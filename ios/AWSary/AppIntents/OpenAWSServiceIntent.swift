import AppIntents
import Foundation

struct OpenAWSServiceIntent: OpenIntent {
    static var title: LocalizedStringResource = "Open AWS Service in AWSary"
    static var description = IntentDescription("Opens an AWS service glossary entry in AWSary.")
    static var supportedModes: IntentModes { .foreground(.dynamic) }

    @Parameter(title: "Service")
    var target: AWSServiceEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        AWSaryDeepLinkDispatcher.shared.open(target.deepLink)
        return .result(snippetIntent: AWSServiceSnippetIntent(service: target))
    }
}
