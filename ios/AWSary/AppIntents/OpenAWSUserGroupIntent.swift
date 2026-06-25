import AppIntents
import Foundation

struct OpenAWSUserGroupIntent: OpenIntent {
    static var title: LocalizedStringResource = "Open AWS User Group in AWSary"
    static var description = IntentDescription("Opens an AWS User Group in AWSary.")
    static var supportedModes: IntentModes { .foreground(.dynamic) }

    @Parameter(title: "User Group")
    var target: AWSUserGroupEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        AWSaryDeepLinkDispatcher.shared.open(target.deepLink)
        return .result(snippetIntent: AWSUserGroupSnippetIntent(userGroup: target))
    }
}
