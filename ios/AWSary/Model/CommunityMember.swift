//
//  CommunityMember.swift
//  awsary (iOS)
//
//  Created by OpenAI Codex on 13/06/2026.
//

import Foundation

struct CommunityMember: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let bio: String
    let location: String
    let imageURL: String
    let profileURL: String
    let statuses: [String]
    let specialties: [String]
    let links: [CommunityMemberLink]

    var tags: [String] {
        statuses + specialties
    }

    func matches(searchText: String, selectedStatus: String?, selectedSpecialty: String?) -> Bool {
        if let selectedStatus, !statuses.contains(selectedStatus) {
            return false
        }

        if let selectedSpecialty, !specialties.contains(selectedSpecialty) {
            return false
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return true
        }

        let searchableText = ([name, bio, location] + statuses + specialties)
            .joined(separator: " ")
            .localizedCaseInsensitiveContains(query)

        return searchableText
    }
}

struct CommunityMemberLink: Codable, Hashable, Identifiable {
    let label: String
    let url: String

    var id: String {
        url
    }
}

@MainActor
final class CommunityMemberStore: ObservableObject {
    @Published private(set) var members: [CommunityMember] = []
    @Published private(set) var errorMessage: String?

    init() {
        load()
    }

    func load() {
        errorMessage = nil

        guard let url = Bundle.main.url(forResource: "community_members", withExtension: "json") else {
            errorMessage = "Community data is not available."
            members = []
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decodedMembers = try JSONDecoder().decode([CommunityMember].self, from: data)
            members = decodedMembers.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            errorMessage = "Community data could not be loaded."
            members = []
        }
    }
}
