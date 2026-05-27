import SwiftUI
import WebKit

struct LedgerCrossWebPanel: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        // .always so page content is inset below the top safe area (notch / Dynamic
        // Island). The panel is shown with .edgesIgnoringSafeArea(.all); .never would
        // draw content under the notch.
        webView.scrollView.contentInsetAdjustmentBehavior = .always
        webView.isOpaque = true
        webView.backgroundColor = .white
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Intentionally empty — never reload on SwiftUI re-renders.
    }
}
