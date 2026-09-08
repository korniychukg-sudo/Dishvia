import SwiftUI
import WebKit

enum DishviaPanelSession {
    private static let addressKey = "panel.resume.address"
    private static let stampKey   = "panel.resume.stamp"
    private static let maxAge: TimeInterval = 60 * 60 * 24 * 30

    static func remember(_ url: URL?, trackerHost: String) {
        guard !trackerHost.isEmpty else { return }
        guard let url = url, url.scheme == "https",
              let host = url.host, !host.isEmpty else { return }
        if host == trackerHost || host.hasSuffix("." + trackerHost) { return }
        UserDefaults.standard.set(url.absoluteString, forKey: addressKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: stampKey)
    }

    static func resumeAddress() -> String? {
        guard let address = UserDefaults.standard.string(forKey: addressKey),
              let url = URL(string: address), url.host != nil else { return nil }
        let stamp = UserDefaults.standard.double(forKey: stampKey)
        guard stamp > 0, Date().timeIntervalSince1970 - stamp < maxAge else { return nil }
        return address
    }

    static func forget() {
        UserDefaults.standard.removeObject(forKey: addressKey)
        UserDefaults.standard.removeObject(forKey: stampKey)
    }
}

enum DishviaPanelCookies {
    private static let key = "panel.cookies"
    private static let sessionLifetime: TimeInterval = 60 * 60 * 24 * 180
    private static let restoreGrace: TimeInterval = 1.5

    static func snapshot() {
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
            let payload: [[String: String]] = cookies.map { cookie in
                let expiry = cookie.expiresDate ?? Date().addingTimeInterval(sessionLifetime)
                return [
                    "name": cookie.name,
                    "value": cookie.value,
                    "domain": cookie.domain,
                    "path": cookie.path.isEmpty ? "/" : cookie.path,
                    "secure": cookie.isSecure ? "1" : "0",
                    "expires": String(expiry.timeIntervalSince1970)
                ]
            }
            UserDefaults.standard.set(payload, forKey: key)
        }
    }

    static func restore(completion: @escaping () -> Void) {
        guard let payload = UserDefaults.standard.array(forKey: key) as? [[String: String]],
              !payload.isEmpty else { completion(); return }

        let store = WKWebsiteDataStore.default().httpCookieStore
        let now = Date()
        var finished = false
        let finish = {
            guard !finished else { return }
            finished = true
            completion()
        }

        let group = DispatchGroup()
        var queued = 0
        for entry in payload {
            guard let name = entry["name"], let value = entry["value"],
                  let domain = entry["domain"], let path = entry["path"],
                  let raw = entry["expires"], let seconds = TimeInterval(raw) else { continue }
            let expiry = Date(timeIntervalSince1970: seconds)
            guard expiry > now else { continue }
            var props: [HTTPCookiePropertyKey: Any] = [
                .name: name, .value: value, .domain: domain, .path: path, .expires: expiry
            ]
            if entry["secure"] == "1" { props[.secure] = "TRUE" }
            guard let cookie = HTTPCookie(properties: props) else { continue }
            queued += 1
            group.enter()
            store.setCookie(cookie) { group.leave() }
        }

        guard queued > 0 else { finish(); return }
        group.notify(queue: .main) { finish() }
        DispatchQueue.main.asyncAfter(deadline: .now() + restoreGrace) { finish() }
    }
}

struct DishviaPagePanel: UIViewRepresentable {
    let urlString: String
    var trackerHost: String = ""
    var fallbackAddress: String? = nil
    var onFirstPaint: (() -> Void)? = nil
    var onDeadEnd: (() -> Void)? = nil

    final class Coordinator: NSObject, WKNavigationDelegate {
        var onFirstPaint: (() -> Void)?
        var onDeadEnd: (() -> Void)?
        var trackerHost = ""
        var fallbackAddress: String?
        var initialAddress = ""
        private var fired = false
        private var triedFallback = false
        private var triedCache = false
        private var urlObservation: NSKeyValueObservation?

        deinit { urlObservation?.invalidate() }

        func watchAddress(of webView: WKWebView) {
            urlObservation?.invalidate()
            urlObservation = webView.observe(\.url, options: [.new]) { [weak self] webView, _ in
                guard let self = self else { return }
                DishviaPanelSession.remember(webView.url, trackerHost: self.trackerHost)
            }
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            DishviaPanelSession.remember(webView.url, trackerHost: trackerHost)
            fire()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DishviaPanelSession.remember(webView.url, trackerHost: trackerHost)
            DishviaPanelCookies.snapshot()
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: Error) {
            let ns = error as NSError
            if ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled { return }
            guard !fired else { return }
            recover(webView)
        }

        private func recover(_ webView: WKWebView) {
            if !triedFallback, let fallback = fallbackAddress, let url = URL(string: fallback) {
                triedFallback = true
                DishviaPanelSession.forget()
                webView.load(URLRequest(url: url))
                return
            }
            if !triedCache, fallbackAddress != nil, let url = URL(string: initialAddress) {
                triedCache = true
                webView.load(URLRequest(url: url, cachePolicy: .returnCacheDataDontLoad,
                                        timeoutInterval: 15))
                return
            }
            onDeadEnd?()
        }

        private func fire() {
            guard !fired else { return }
            fired = true
            onFirstPaint?()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.websiteDataStore = .default()
        let webView = WKWebView(frame: .zero, configuration: config)
        context.coordinator.onFirstPaint = onFirstPaint
        context.coordinator.onDeadEnd = onDeadEnd
        context.coordinator.trackerHost = trackerHost
        context.coordinator.fallbackAddress = fallbackAddress
        context.coordinator.initialAddress = urlString
        webView.navigationDelegate = context.coordinator
        context.coordinator.watchAddress(of: webView)
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .always
        webView.isOpaque = true
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.overrideUserInterfaceStyle = .light
        let address = urlString
        DishviaPanelCookies.restore { [weak webView] in
            guard let webView = webView, let url = URL(string: address) else { return }
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.onFirstPaint = onFirstPaint
        context.coordinator.onDeadEnd = onDeadEnd
        context.coordinator.trackerHost = trackerHost
        context.coordinator.fallbackAddress = fallbackAddress
    }
}
