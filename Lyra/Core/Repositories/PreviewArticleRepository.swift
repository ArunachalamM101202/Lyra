import Foundation

struct PreviewArticleRepository: ArticleRepository {
    func articles() -> [Article] {
        [
            Article(
                id: UUID(uuidString: "A574B8A2-071E-498A-8E78-7AA0CD9C7D01")!,
                title: "Running a Software Factory Efficiently at Uber Scale",
                source: "Uber Engineering",
                originalURL: URL(string: "https://www.uber.com/us/en/blog/efficient-software-factory/")!,
                hook: "What happens to AI costs when agents become part of everyday engineering?",
                preview: "Uber breaks down the cost of an agent session, then shows how it measures model choice, token use, and outcomes across its software factory.",
                category: .artificialIntelligence,
                tags: ["AI agents", "engineering productivity", "cost"],
                estimatedReadMinutes: 12,
                themeColorHex: "#000000"
            ),
            Article(
                id: UUID(uuidString: "0E86DD31-D076-47D3-9C35-E801E5745A02")!,
                title: "The Lifecycle of LLM-as-a-Judge: Building, Aligning, and Monitoring at Scale",
                source: "Netflix Technology Blog",
                originalURL: URL(string: "https://netflixtechblog.medium.com/the-lifecycle-of-llm-as-a-judge-building-aligning-and-monitoring-at-scale-c95bd8283508")!,
                hook: "If an AI judges other AI output, who checks the judge?",
                preview: "Netflix follows an LLM judge from human-labeled benchmarks through deployment and ongoing review, using recommendation explanations as a real example.",
                category: .artificialIntelligence,
                tags: ["LLM evaluation", "human review", "recommendations"],
                estimatedReadMinutes: 16,
                themeColorHex: "#E50914"
            )
        ]
    }
}
