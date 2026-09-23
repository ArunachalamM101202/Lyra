import SwiftUI
import WebKit

struct ArticleWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var loadFailed: Bool
    let onExit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        let backSwipe = UIScreenEdgePanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleBackSwipe(_:))
        )
        backSwipe.edges = .left
        webView.addGestureRecognizer(backSwipe)
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: ArticleWebView

        init(parent: ArticleWebView) {
            self.parent = parent
        }

        @objc func handleBackSwipe(_ gesture: UIScreenEdgePanGestureRecognizer) {
            guard gesture.state == .ended,
                  gesture.translation(in: gesture.view).x > 70,
                  let webView = gesture.view as? WKWebView else {
                return
            }

            if webView.canGoBack {
                webView.goBack()
            } else {
                parent.onExit()
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
            parent.loadFailed = false
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            parent.loadFailed = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handle(error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            handle(error)
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }

        private func handle(_ error: Error) {
            if (error as NSError).code == NSURLErrorCancelled { return }
            parent.isLoading = false
            parent.loadFailed = true
        }
    }
}
