import Foundation

enum AWSaryAppEntitySearch {
    static func normalized(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func tokens(for value: String) -> [String] {
        normalized(value)
            .split(separator: " ")
            .map(String.init)
    }

    static func matches(query: String, fields: [String]) -> Bool {
        let normalizedQuery = normalized(query)
        guard !normalizedQuery.isEmpty else { return true }

        let haystack = normalized(fields.joined(separator: " "))
        if haystack.contains(normalizedQuery) {
            return true
        }

        let queryTokens = tokens(for: normalizedQuery)
        guard !queryTokens.isEmpty else { return true }

        let fieldTokens = Set(tokens(for: haystack))
        return queryTokens.allSatisfy { queryToken in
            fieldTokens.contains(queryToken) || fieldTokens.contains { $0.hasPrefix(queryToken) }
        }
    }

    static func sortedMatches<Entity>(
        query: String,
        in entities: [Entity],
        title: (Entity) -> String,
        rank: ((Entity) -> Int?)? = nil,
        fields: (Entity) -> [String]
    ) -> [Entity] {
        entities
            .compactMap { entity -> (Entity, Int)? in
                guard let score = rank?(entity) ?? score(query: query, title: title(entity), fields: fields(entity)) else {
                    return nil
                }
                return (entity, score)
            }
            .sorted {
                if $0.1 == $1.1 {
                    return title($0.0).localizedCaseInsensitiveCompare(title($1.0)) == .orderedAscending
                }
                return $0.1 < $1.1
            }
            .map(\.0)
    }

    private static func score(query: String, title: String, fields: [String]) -> Int? {
        let normalizedQuery = normalized(query)
        guard !normalizedQuery.isEmpty else { return 0 }

        let normalizedTitle = normalized(title)
        if normalizedTitle == normalizedQuery { return 0 }
        if normalizedTitle.hasPrefix(normalizedQuery) { return 1 }
        if normalizedTitle.contains(normalizedQuery) { return 2 }
        if matches(query: query, fields: fields) { return 3 }
        return nil
    }
}
