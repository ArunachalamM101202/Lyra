import SwiftUI
import Textual

struct ArticleMarkdownView: View {
    let markdown: String

    var body: some View {
        StructuredText(markdown: markdown)
            .textSelection(.enabled)
    }
}
