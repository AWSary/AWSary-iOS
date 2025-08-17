import Foundation

struct BuildersContentHelper {
    func getBuildersContent() async throws -> [FeedContent] {
        guard let url = URL(string:"https://api.awsary.com/content/trending") else {
            throw URLError(.badURL)
        }
            
        let (data,_) = try await URLSession.shared.data(from: url)
        let buildersContent = try JSONDecoder().decode(BuildersContent.self, from: data)
        return buildersContent.feedContents
    }
}

struct BuildersContent: Codable{
    let feedContents: [FeedContent]
    let nextToken: String
}

// MARK: - FeedContent
struct FeedContent: Codable, Hashable {
    let author: Author
    let commentsCount: Int
    let contentID: String
    let contentType: ContentType
    let contentTypeSpecificResponse: ContentTypeSpecificResponse
    let createdAt: Int
    let isLiked: Bool
    let lastModifiedAt, lastPublishedAt, likesCount: Int
    let locale: Locale
    let markdownDescription: String
    let status: Status
    let title: String
    
    var id: String { contentID }

    enum CodingKeys: String, CodingKey {
        case author, commentsCount
        case contentID = "contentId"
        case contentType, contentTypeSpecificResponse, createdAt, isLiked, lastModifiedAt, lastPublishedAt, likesCount, locale, markdownDescription, status, title
    }
}

// MARK: - Author
struct Author: Codable, Hashable {
    let alias: String
    let avatarURL: String?
    let creatorID: String
    let isAmazonEmployee: Bool
    let preferredName: String
    let bio, headline: String?
    
    var id: String { alias }

    enum CodingKeys: String, CodingKey {
        case alias
        case avatarURL = "avatarUrl"
        case creatorID = "creatorId"
        case isAmazonEmployee, preferredName, bio, headline
    }
}

enum ContentType: String, Codable {
    case article = "ARTICLE"
}

// MARK: - ContentTypeSpecificResponse
struct ContentTypeSpecificResponse: Codable, Hashable {
    let article: Article
    
    var id: Article { article }
}

// MARK: - Article
struct Article: Codable, Hashable {
    let description: String
    let heroImageURL: String
    let tags: [String]
    let versionID: String

    enum CodingKeys: String, CodingKey {
        case description
        case heroImageURL = "heroImageUrl"
        case tags
        case versionID = "versionId"
    }
}

enum Locale: String, Codable {
    case en = "en"
}

enum Status: String, Codable {
    case live = "live"
}
