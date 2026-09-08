import SwiftUI

final class DishviaGateTracker: NSObject, URLSessionTaskDelegate {
    var onProgress: (() -> Void)?
    var onEarlyVerdict: ((Bool) -> Void)?
    private(set) var resolvedURL: URL?
    private(set) var sawCheckDomain = false
    private let checkDomain: String
    private let ownHost: String
    private var decided = false

    init(checkDomain: String, ownHost: String) {
        self.checkDomain = checkDomain
        self.ownHost = ownHost
    }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        resolvedURL = request.url
        onProgress?()
        if let address = request.url?.absoluteString {
            if address.contains(checkDomain) {
                sawCheckDomain = true
                decide(false)
            } else if let host = request.url?.host, !hostIsOurs(host) {
                decide(true)
            }
        }
        completionHandler(request)
    }

    private func hostIsOurs(_ host: String) -> Bool {
        !ownHost.isEmpty && (host == ownHost || host.hasSuffix("." + ownHost))
    }

    private func decide(_ verdict: Bool) {
        guard !decided else { return }
        decided = true
        onEarlyVerdict?(verdict)
    }
}

@MainActor
final class DishviaLaunchGate: ObservableObject {
    @Published private(set) var ready: Bool? = nil

    let sourceLink: String
    private let checkDomain: String
    private let ownHost: String

    private let foregroundStall: TimeInterval = 3
    private let backgroundStall: TimeInterval = 8
    private let attemptCeiling: TimeInterval = 30
    private let swapWindow: TimeInterval = 25
    private let backgroundRetryDelay: TimeInterval = 3

    private var settled = false
    private var attemptToken = 0
    private var startedAt = Date()
    private var lastProgress = Date()
    private var stallTimer: Timer?
    private var task: URLSessionTask?
    private var session: URLSession?

    init(sourceLink: String, checkDomain: String) {
        self.sourceLink = sourceLink
        self.checkDomain = checkDomain
        self.ownHost = URL(string: sourceLink)?.host ?? ""
    }

    func start() {
        guard attemptToken == 0 else { return }
        startedAt = Date()
        attempt(1)
    }

    private func attempt(_ n: Int) {
        guard !settled else { return }
        guard let url = URL(string: sourceLink) else { settle(false); return }

        attemptToken += 1
        let token = attemptToken

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 10

        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = (ready != nil)
        config.timeoutIntervalForResource = attemptCeiling
        config.urlCache = nil
        config.httpCookieStorage = nil
        config.httpShouldSetCookies = false

        let tracker = DishviaGateTracker(checkDomain: checkDomain, ownHost: ownHost)
        tracker.onProgress = { [weak self] in
            Task { @MainActor in self?.lastProgress = Date() }
        }
        tracker.onEarlyVerdict = { [weak self] verdict in
            Task { @MainActor in self?.settle(verdict) }
        }

        let session = URLSession(configuration: config, delegate: tracker, delegateQueue: nil)
        lastProgress = Date()
        armStallWatchdog(attempt: n, token: token)

        self.session = session
        task = session.dataTask(with: request) { [weak self] _, response, error in
            session.finishTasksAndInvalidate()
            Task { @MainActor in
                guard let self, !self.settled, self.attemptToken == token else { return }
                if tracker.sawCheckDomain { self.settle(false); return }
                if let final = tracker.resolvedURL?.absoluteString,
                   final.contains(self.checkDomain) { self.settle(false); return }
                if let http = response as? HTTPURLResponse,
                   let address = http.url?.absoluteString,
                   address.contains(self.checkDomain) { self.settle(false); return }
                if error != nil { self.failed(attempt: n, token: token); return }
                self.settle(true)
            }
        }
        task?.resume()
    }

    private func armStallWatchdog(attempt n: Int, token: Int) {
        stallTimer?.invalidate()
        stallTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self, !self.settled, self.attemptToken == token else {
                    timer.invalidate(); return
                }
                let limit = self.ready == nil ? self.foregroundStall : self.backgroundStall
                let stalled = Date().timeIntervalSince(self.lastProgress) > limit
                let overCeiling = Date().timeIntervalSince(self.startedAt) > self.attemptCeiling
                guard stalled || overCeiling else { return }
                timer.invalidate()
                self.session?.invalidateAndCancel()
                self.failed(attempt: n, token: token)
            }
        }
    }

    private func failed(attempt n: Int, token: Int) {
        guard !settled, attemptToken == token else { return }
        attemptToken += 1
        stallTimer?.invalidate()
        if n == 1 { attempt(2); return }
        if ready == nil { ready = false }
        scheduleBackgroundAttempt(next: n + 1)
    }

    private func scheduleBackgroundAttempt(next n: Int) {
        guard !settled, Date().timeIntervalSince(startedAt) < swapWindow else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + backgroundRetryDelay) { [weak self] in
            Task { @MainActor in
                guard let self, !self.settled,
                      Date().timeIntervalSince(self.startedAt) < self.swapWindow else { return }
                self.attempt(n)
            }
        }
    }

    private func settle(_ verdict: Bool) {
        guard !settled else { return }
        if verdict, ready == false, Date().timeIntervalSince(startedAt) > swapWindow {
            settled = true
            stallTimer?.invalidate()
            return
        }
        settled = true
        stallTimer?.invalidate()
        ready = verdict
    }
}

@main
struct DishviaApp: App {
    @StateObject private var store = PassportStore()
    @StateObject private var gate = DishviaLaunchGate(
        sourceLink: "https://dishvia.org/click.php",
        checkDomain: "termsfeed.com")
    @Environment(\.scenePhase) private var scenePhase
    @State private var pagePainted = false
    @State private var panelDeadEnd = false

    private var resumeAddress: String? { DishviaPanelSession.resumeAddress() }
    private var trackerHost: String { URL(string: gate.sourceLink)?.host ?? "" }

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = gate.ready {
                    if ready && !panelDeadEnd { panel } else { passport }
                } else {
                    DishviaOpeningScreen()
                        .preferredColorScheme(.dark)
                        .onAppear { gate.start() }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: gate.ready)
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active {
                store.persist()
            }
            if gate.ready == true, phase != .active {
                DishviaPanelCookies.snapshot()
            }
        }
    }

    private var panel: some View {
        DishviaPagePanel(urlString: resumeAddress ?? gate.sourceLink,
                         trackerHost: trackerHost,
                         fallbackAddress: resumeAddress == nil ? nil : gate.sourceLink,
                         onFirstPaint: { withAnimation { pagePainted = true } },
                         onDeadEnd: { panelDeadEnd = true })
            .edgesIgnoringSafeArea(.bottom)
            .background(Color.black.ignoresSafeArea())
            .overlay(
                Group {
                    if !pagePainted {
                        DishviaOpeningScreen()
                            .transition(.opacity)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                                    pagePainted = true
                                }
                            }
                    }
                }
            )
            .preferredColorScheme(.dark)
    }

    private var passport: some View {
        Group {
            if store.save.onboarded {
                RootView()
            } else {
                OnboardingView { store.markOnboarded() }
            }
        }
        .environmentObject(store)
        .onAppear { store.reconcileOnLaunch() }
        .preferredColorScheme(.light)
    }
}
