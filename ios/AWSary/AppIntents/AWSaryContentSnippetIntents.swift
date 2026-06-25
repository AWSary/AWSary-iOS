import AppIntents
import SwiftUI

struct AWSServiceSnippetIntent: SnippetIntent {
    static var title: LocalizedStringResource = "AWS Service Summary"
    static var isDiscoverable = false

    @Parameter(title: "Service")
    var service: AWSServiceEntity

    init() {}

    init(service: AWSServiceEntity) {
        self.service = service
    }

    func perform() async throws -> some ShowsSnippetView {
        .result(view: AWSServiceSnippetView(service: service))
    }
}

struct AWSHeroSnippetIntent: SnippetIntent {
    static var title: LocalizedStringResource = "AWS Hero Summary"
    static var isDiscoverable = false

    @Parameter(title: "Hero")
    var hero: AWSHeroEntity

    init() {}

    init(hero: AWSHeroEntity) {
        self.hero = hero
    }

    func perform() async throws -> some ShowsSnippetView {
        .result(view: AWSHeroSnippetView(hero: hero))
    }
}

struct AWSUserGroupSnippetIntent: SnippetIntent {
    static var title: LocalizedStringResource = "AWS User Group Summary"
    static var isDiscoverable = false

    @Parameter(title: "User Group")
    var userGroup: AWSUserGroupEntity

    init() {}

    init(userGroup: AWSUserGroupEntity) {
        self.userGroup = userGroup
    }

    func perform() async throws -> some ShowsSnippetView {
        .result(view: AWSUserGroupSnippetView(userGroup: userGroup))
    }
}

private struct AWSServiceSnippetView: View {
    let service: AWSServiceEntity

    var body: some View {
        AWSarySnippetCard {
            HStack(alignment: .top, spacing: 14) {
                AWSarySnippetImage(imageData: service.iconPNGData, fallbackSystemName: "cloud")

                VStack(alignment: .leading, spacing: 8) {
                    Text(service.fullName)
                        .font(.headline)
                        .lineLimit(2)

                    Text(service.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)
                        .lineLimit(1)

                    Text(service.summary.awsaryPlainTextSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)

                    AWSarySnippetChips(values: [service.iconAssetName.awsaryServiceTopicLabel, "AWS Service"])
                }
            }
        }
    }
}

private struct AWSHeroSnippetView: View {
    let hero: AWSHeroEntity

    var body: some View {
        AWSarySnippetCard {
            HStack(alignment: .top, spacing: 14) {
                AWSarySnippetRemoteImage(urlString: hero.imageURL, fallbackSystemName: "person.crop.circle")

                VStack(alignment: .leading, spacing: 8) {
                    Text(hero.name)
                        .font(.headline)
                        .lineLimit(2)

                    Text(hero.location)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)
                        .lineLimit(1)

                    Text(hero.bio.awsaryPlainTextSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)

                    AWSarySnippetChips(values: Array((hero.statuses + hero.specialties).prefix(3)))
                }
            }
        }
    }
}

private struct AWSUserGroupSnippetView: View {
    let userGroup: AWSUserGroupEntity

    var body: some View {
        AWSarySnippetCard {
            HStack(alignment: .top, spacing: 14) {
                AWSarySnippetRemoteImage(urlString: userGroup.imageURL, fallbackSystemName: "person.3")

                VStack(alignment: .leading, spacing: 8) {
                    Text(userGroup.name)
                        .font(.headline)
                        .lineLimit(2)

                    Text(userGroup.locationName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)
                        .lineLimit(1)

                    Text(userGroup.summary.awsaryPlainTextSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)

                    AWSarySnippetChips(values: Array(([userGroup.platformName, userGroup.country] + userGroup.topics).prefix(3)))
                }
            }
        }
    }
}

private struct AWSarySnippetCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
    }
}

private struct AWSarySnippetImage: View {
    let imageData: Data?
    let fallbackSystemName: String

    var body: some View {
        Group {
            if let imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: fallbackSystemName)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.orange)
            }
        }
        .frame(width: 58, height: 58)
        .padding(8)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct AWSarySnippetRemoteImage: View {
    let urlString: String
    let fallbackSystemName: String

    var body: some View {
        if let url = URL(string: urlString), !urlString.isEmpty {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    fallback
                }
            }
            .frame(width: 74, height: 74)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            fallback
                .frame(width: 74, height: 74)
        }
    }

    private var fallback: some View {
        Image(systemName: fallbackSystemName)
            .font(.system(size: 30, weight: .semibold))
            .foregroundStyle(.orange)
            .frame(width: 74, height: 74)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct AWSarySnippetChips: View {
    let values: [String]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(values.filter { !$0.isEmpty }, id: \.self) { value in
                Text(value)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 7)
                    .background(Color.orange.opacity(0.16))
                    .foregroundStyle(.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }
}

private extension String {
    var awsaryServiceTopicLabel: String {
        replacingOccurrences(of: "Arch_", with: "")
            .replacingOccurrences(of: "_64", with: "")
            .replacingOccurrences(of: "-", with: " ")
    }
}
