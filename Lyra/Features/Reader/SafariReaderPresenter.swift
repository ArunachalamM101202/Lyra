import SafariServices
import SwiftUI

/// Presents Safari's own browser modally so its Reader and history gestures work.
struct SafariReaderPresenter: UIViewControllerRepresentable {
    @Binding var article: Article?

    func makeCoordinator() -> Coordinator {
        Coordinator(article: $article)
    }

    func makeUIViewController(context: Context) -> PresentationAnchorController {
        let controller = PresentationAnchorController()
        controller.view.backgroundColor = .clear
        controller.onAppear = { [weak coordinator = context.coordinator] in
            coordinator?.presentIfNeeded()
        }
        context.coordinator.anchor = controller
        return controller
    }

    func updateUIViewController(_ controller: PresentationAnchorController, context: Context) {
        context.coordinator.article = $article
        context.coordinator.anchor = controller
        context.coordinator.presentIfNeeded()
    }

    final class PresentationAnchorController: UIViewController {
        var onAppear: (() -> Void)?

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            onAppear?()
        }
    }

    final class Coordinator: NSObject, SFSafariViewControllerDelegate {
        var article: Binding<Article?>
        weak var anchor: PresentationAnchorController?
        private var safari: SFSafariViewController?

        init(article: Binding<Article?>) {
            self.article = article
        }

        func presentIfNeeded() {
            guard let selectedArticle = article.wrappedValue,
                  let anchor,
                  anchor.view.window != nil,
                  safari == nil else {
                return
            }

            let configuration = SFSafariViewController.Configuration()
            configuration.entersReaderIfAvailable = true
            let controller = SFSafariViewController(
                url: selectedArticle.originalURL,
                configuration: configuration
            )
            controller.delegate = self
            safari = controller
            anchor.present(controller, animated: true)
        }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            safari = nil
            article.wrappedValue = nil
        }
    }
}
