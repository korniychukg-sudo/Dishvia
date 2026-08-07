import SwiftUI
import WebKit

struct DishviaPagePanel: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let panel = WKWebView(frame: .zero, configuration: config)
        panel.allowsBackForwardNavigationGestures = true
        panel.scrollView.bounces = true
        panel.scrollView.contentInsetAdjustmentBehavior = .always
        panel.isOpaque = true
        panel.backgroundColor = UIColor(red: 0.153, green: 0.180, blue: 0.161, alpha: 1)
        if let address = URL(string: urlString) {
            panel.load(URLRequest(url: address))
        }
        return panel
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
