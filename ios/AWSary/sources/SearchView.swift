//
//  SearchView.swift
//  awsary
//
//  Created by Tiago Rodrigues on 04/07/2025.
//
import SwiftUI

struct SearchView: View {
    @Binding var searchString: String
    @StateObject private var awsServices = AwsServices()
    @StateObject private var communityStore = CommunityMemberStore()
    @State private var showingAllServices = false
    @State private var showingAllMembers = false

    private let visibleResultLimit = 4

    private var query: String {
        searchString.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var matchingResults: [UnifiedSearchResult] {
        guard !query.isEmpty else { return [] }

        let services = awsServices.services.map(UnifiedSearchResult.service)
        let members = communityStore.members.map(UnifiedSearchResult.member)

        return (services + members)
            .compactMap { result in
                searchScore(for: result).map { (result, $0) }
            }
            .sorted {
                if $0.1 == $1.1 {
                    return $0.0.title.localizedCaseInsensitiveCompare($1.0.title) == .orderedAscending
                }
                return $0.1 < $1.1
            }
            .map(\.0)
    }

    var body: some View {
        let results = matchingResults
        let matchingServices = results.compactMap(\.service)
        let matchingMembers = results.compactMap(\.member)
        let visibleServices = showingAllServices
            ? matchingServices
            : Array(matchingServices.prefix(visibleResultLimit))
        let visibleMembers = showingAllMembers
            ? matchingMembers
            : Array(matchingMembers.prefix(visibleResultLimit))

        NavigationStack {
            Group {
                if query.isEmpty {
                    ContentUnavailableView {
                        Label("Search AWSary", systemImage: "magnifyingglass")
                    } description: {
                        Text("Find AWS services and community members from one place.")
                    }
                } else if matchingServices.isEmpty && matchingMembers.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    List {
                        if !matchingServices.isEmpty {
                            Section("AWS Services") {
                                ForEach(visibleServices) { service in
                                    NavigationLink {
                                        DetailsView(service: service)
                                    } label: {
                                        ServiceSearchResultRow(service: service)
                                    }
                                }

                                if matchingServices.count > visibleResultLimit {
                                    SearchResultsExpansionButton(
                                        categoryName: "AWS Services",
                                        resultCount: matchingServices.count,
                                        isExpanded: $showingAllServices
                                    )
                                }
                            }
                        }

                        if !matchingMembers.isEmpty {
                            Section("Community Members") {
                                ForEach(visibleMembers) { member in
                                    NavigationLink {
                                        CommunityMemberDetailView(member: member)
                                    } label: {
                                        CommunitySearchResultRow(member: member)
                                    }
                                }

                                if matchingMembers.count > visibleResultLimit {
                                    SearchResultsExpansionButton(
                                        categoryName: "Community Members",
                                        resultCount: matchingMembers.count,
                                        isExpanded: $showingAllMembers
                                    )
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Search")
        }
        .onChange(of: query) {
            showingAllServices = false
            showingAllMembers = false
        }
    }

    private func searchScore(for result: UnifiedSearchResult) -> Int? {
        if result.names.contains(where: { $0.localizedCaseInsensitiveCompare(query) == .orderedSame }) {
            return 0
        }
        if result.names.contains(where: { hasLocalizedPrefix($0, prefix: query) }) {
            return 1
        }
        if result.names.contains(where: { $0.localizedCaseInsensitiveContains(query) }) {
            return 2
        }
        if result.metadata.contains(where: { $0.localizedCaseInsensitiveContains(query) }) {
            return 3
        }
        return nil
    }

    private func hasLocalizedPrefix(_ value: String, prefix: String) -> Bool {
        value.range(
            of: prefix,
            options: [.anchored, .caseInsensitive, .diacriticInsensitive],
            locale: .current
        ) != nil
    }
}

private struct SearchResultsExpansionButton: View {
    let categoryName: String
    let resultCount: Int
    @Binding var isExpanded: Bool

    var body: some View {
        Button {
            withAnimation {
                isExpanded.toggle()
            }
        } label: {
            HStack {
                Text(isExpanded ? "Show fewer" : "Show all \(resultCount) \(categoryName)")
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.semibold))
            }
            .contentShape(.rect)
        }
    }
}

private enum UnifiedSearchResult {
    case service(awsService)
    case member(CommunityMember)

    var title: String {
        switch self {
        case .service(let service):
            service.name
        case .member(let member):
            member.name
        }
    }

    var names: [String] {
        switch self {
        case .service(let service):
            [service.name, service.longName]
        case .member(let member):
            [member.name]
        }
    }

    var metadata: [String] {
        switch self {
        case .service(let service):
            [service.shortDesctiption]
        case .member(let member):
            [member.bio, member.location] + member.statuses + member.specialties
        }
    }

    var service: awsService? {
        guard case .service(let service) = self else { return nil }
        return service
    }

    var member: CommunityMember? {
        guard case .member(let member) = self else { return nil }
        return member
    }
}

private struct ServiceSearchResultRow: View {
    let service: awsService

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text(service.longName)
                    .foregroundStyle(.primary)

                if service.name.localizedCaseInsensitiveCompare(service.longName) != .orderedSame {
                    Text(service.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } icon: {
            Image(systemName: "cloud")
                .foregroundStyle(.orange)
        }
    }
}

private struct CommunitySearchResultRow: View {
    let member: CommunityMember

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(member.name, systemImage: "person.crop.circle")
                .foregroundStyle(.primary)

            Text(memberSummary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }

    private var memberSummary: String {
        ([member.location] + Array(member.specialties.prefix(2)))
            .filter { !$0.isEmpty }
            .joined(separator: " • ")
    }
}

#Preview {
    SearchView(searchString: .constant("Lambda"))
}
