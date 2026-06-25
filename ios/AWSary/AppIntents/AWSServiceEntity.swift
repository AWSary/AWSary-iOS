import AppIntents
import CoreSpotlight
import Foundation
import UniformTypeIdentifiers

struct AWSServiceEntity: IndexedEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "AWS Service",
        synonyms: ["AWS glossary item", "AWS product"]
    )
    static var defaultQuery = AWSServiceEntityQuery()

    let id: Int
    let name: String
    let fullName: String
    let summary: String
    let iconAssetName: String
    let iconURL: String
    let youtubeID: String

    init(service: awsService) {
        id = service.id
        name = service.name
        fullName = service.longName
        summary = service.shortDesctiption
        iconURL = service.imageURL
        iconAssetName = service.awsaryIconAssetName
        youtubeID = service.youtube_id
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(fullName)",
            subtitle: "\(name)",
            image: DisplayRepresentation.Image(named: iconAssetName)
        )
    }

    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(contentType: .text)
        attributes.title = fullName
        attributes.displayName = fullName
        attributes.contentDescription = summary.awsaryPlainTextSummary
        attributes.keywords = searchableFields
        attributes.thumbnailURL = Bundle.main.url(forResource: iconAssetName, withExtension: nil)
        return attributes
    }

    var deepLink: AWSaryDeepLink {
        .service(id: id)
    }

    fileprivate var searchableFields: [String] {
        [
            name,
            fullName,
            summary,
            iconAssetName,
            iconURL,
            youtubeID
        ]
    }
}

struct AWSServiceEntityQuery: EntityStringQuery, EnumerableEntityQuery {
    func entities(for identifiers: [AWSServiceEntity.ID]) async throws -> [AWSServiceEntity] {
        var entities: [AWSServiceEntity] = []
        for identifier in identifiers {
            if let service = await AWSaryContentDataSource.shared.service(id: identifier) {
                entities.append(AWSServiceEntity(service: service))
            }
        }
        return entities
    }

    func suggestedEntities() async throws -> [AWSServiceEntity] {
        Array(try await allEntities().prefix(20))
    }

    func allEntities() async throws -> [AWSServiceEntity] {
        await AWSaryContentDataSource.shared.services().map(AWSServiceEntity.init(service:))
    }

    func entities(matching string: String) async throws -> [AWSServiceEntity] {
        await AWSaryContentDataSource.shared.services(matching: string).map(AWSServiceEntity.init(service:))
    }
}

private extension awsService {
    var awsaryIconAssetName: String {
        imageURL
            .replacingOccurrences(of: "https://static.tig.pt/awsary/logos/", with: "")
            .replacingOccurrences(of: ".svg", with: "")
    }
}

extension String {
    var awsaryPlainTextSummary: String {
        replacingOccurrences(of: #"!\[[^\]]*\]\([^\)]*\)"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\[([^\]]+)\]\([^\)]*\)"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"#{1,6}\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\*\*([^*]+)\*\*"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
