import AppIntents
import Foundation

struct OpenAWSHeroIntent: OpenIntent {
    static var title: LocalizedStringResource = "Open AWS Hero in AWSary"
    static var description = IntentDescription("Opens a public AWS Hero profile in AWSary.")
    static var supportedModes: IntentModes { .foreground(.dynamic) }

    @Parameter(title: "Hero")
    var target: AWSHeroEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        AWSaryDeepLinkDispatcher.shared.open(target.deepLink)
        return .result(snippetIntent: AWSHeroSnippetIntent(hero: target))
    }
}
