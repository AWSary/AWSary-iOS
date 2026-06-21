//
//  SearchView.swift
//  awsary
//
//  Created by Tiago Rodrigues on 04/07/2025.
//
import SwiftUI
import UIKit

struct SearchView: View {
    @Binding var searchString: String
    let focusRequest: Int
    let isActive: Bool
    let onNavigate: (AppTab) -> Void
    @StateObject private var awsServices = AwsServices()
    @StateObject private var communityStore = CommunityMemberStore()
    @State private var isSearchPresented = false
    @State private var submittedQuery = ""
    @State private var selectedFacet: SearchFacet = .topResults

    private let visibleResultLimit = 4

    private var query: String {
        searchString.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var submittedTerm: String {
        submittedQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var usesCompactNavigation: Bool {
        isSearchPresented || !submittedTerm.isEmpty
    }

    var body: some View {
        let liveResults = rankedResults(for: query)
        let committedResults = rankedResults(for: submittedTerm)

        NavigationStack {
            Group {
                if query.isEmpty {
                    SearchDiscoveryView(onNavigate: onNavigate)
                } else if isSearchPresented && query != submittedTerm {
                    SearchSuggestionsView(
                        suggestions: autocompleteSuggestions(from: liveResults),
                        topMatches: Array(liveResults.prefix(visibleResultLimit)),
                        onSelectSuggestion: submitSearch
                    )
                } else if submittedTerm.isEmpty {
                    SearchDiscoveryView(onNavigate: onNavigate)
                } else if committedResults.isEmpty {
                    ContentUnavailableView.search(text: submittedTerm)
                } else {
                    SearchResultsView(
                        results: committedResults,
                        selectedFacet: $selectedFacet,
                        topResultLimit: visibleResultLimit
                    )
                }
            }
            .navigationTitle(usesCompactNavigation ? "" : "Search")
            .navigationBarTitleDisplayMode(usesCompactNavigation ? .inline : .large)
            .searchable(
                text: $searchString,
                isPresented: $isSearchPresented,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Services and community members"
            )
            .autocorrectionDisabled()
            .onSubmit(of: .search) {
                submitSearch(query)
            }
        }
        .onChange(of: focusRequest) {
            focusSearchField()
        }
        .onChange(of: query) {
            if query.isEmpty {
                submittedQuery = ""
                selectedFacet = .topResults
            }
        }
        .onChange(of: isActive) {
            if !isActive {
                isSearchPresented = false
            }
        }
    }

    private func rankedResults(for searchTerm: String) -> [UnifiedSearchResult] {
        guard !searchTerm.isEmpty else { return [] }

        let services = awsServices.services.map(UnifiedSearchResult.service)
        let members = communityStore.members.map(UnifiedSearchResult.member)

        return (services + members)
            .compactMap { result in
                searchScore(for: result, query: searchTerm).map { (result, $0) }
            }
            .sorted {
                if $0.1 == $1.1 {
                    return $0.0.title.localizedCaseInsensitiveCompare($1.0.title) == .orderedAscending
                }
                return $0.1 < $1.1
            }
            .map(\.0)
    }

    private func searchScore(for result: UnifiedSearchResult, query: String) -> Int? {
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

    private func autocompleteSuggestions(from results: [UnifiedSearchResult]) -> [String] {
        var seenSuggestions = Set<String>()

        return Array(results.compactMap { result in
            let suggestion = result.suggestion
            let normalizedSuggestion = suggestion.localizedLowercase
            guard seenSuggestions.insert(normalizedSuggestion).inserted else { return nil }
            return suggestion
        }.prefix(3))
    }

    private func submitSearch(_ value: String) {
        let submittedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !submittedValue.isEmpty else { return }

        searchString = submittedValue
        submittedQuery = submittedValue
        selectedFacet = .topResults
        isSearchPresented = true
        dismissKeyboard()
    }

    private func focusSearchField() {
        if isSearchPresented {
            isSearchPresented = false
            Task { @MainActor in
                await Task.yield()
                isSearchPresented = true
            }
        } else {
            isSearchPresented = true
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private func hasLocalizedPrefix(_ value: String, prefix: String) -> Bool {
        value.range(
            of: prefix,
            options: [.anchored, .caseInsensitive, .diacriticInsensitive],
            locale: .current
        ) != nil
    }
}

private struct SearchDiscoveryView: View {
    let onNavigate: (AppTab) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                SearchDiscoveryCard(
                    title: "Services",
                    description: "Browse the AWS glossary",
                    systemImage: "books.vertical",
                    color: .orange
                ) {
                    onNavigate(.glossary)
                }

                SearchDiscoveryCard(
                    title: "People",
                    description: "Discover community members",
                    systemImage: "person.3",
                    color: .blue
                ) {
                    onNavigate(.community)
                }

                SearchDiscoveryCard(
                    title: "Game",
                    description: "Test your AWS knowledge",
                    systemImage: "gamecontroller",
                    color: .purple
                ) {
                    onNavigate(.game)
                }

                SearchDiscoveryCard(
                    title: "AAI Planner",
                    description: "Explore conference sessions",
                    systemImage: "calendar.badge.clock",
                    color: .teal
                ) {
                    onNavigate(.planner)
                }
            }
            .padding()
        }
    }
}

private struct SearchDiscoveryCard: View {
    let title: String
    let description: String
    let systemImage: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(color)

                Spacer(minLength: 8)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(color.opacity(0.12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(color.opacity(0.25), lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct SearchSuggestionsView: View {
    let suggestions: [String]
    let topMatches: [UnifiedSearchResult]
    let onSelectSuggestion: (String) -> Void

    var body: some View {
        List {
            if !suggestions.isEmpty {
                Section("Suggestions") {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            onSelectSuggestion(suggestion)
                        } label: {
                            Label(suggestion, systemImage: "magnifyingglass")
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }

            if !topMatches.isEmpty {
                Section("Top Matches") {
                    ForEach(topMatches) { result in
                        UnifiedSearchResultLink(result: result)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

private struct SearchResultsView: View {
    let results: [UnifiedSearchResult]
    @Binding var selectedFacet: SearchFacet
    let topResultLimit: Int

    private var services: [awsService] {
        results.compactMap(\.service)
    }

    private var members: [CommunityMember] {
        results.compactMap(\.member)
    }

    var body: some View {
        VStack(spacing: 0) {
            SearchFacetBar(selection: $selectedFacet)
            Divider()
            facetResults
        }
    }

    @ViewBuilder
    private var facetResults: some View {
        switch selectedFacet {
        case .topResults:
            List {
                if !services.isEmpty {
                    Section("Services") {
                        ForEach(services.prefix(topResultLimit)) { service in
                            NavigationLink {
                                DetailsView(service: service)
                            } label: {
                                ServiceSearchResultRow(service: service)
                            }
                        }

                        if services.count > topResultLimit {
                            SearchFacetNavigationButton(
                                title: "See all \(services.count) Services",
                                destination: .services,
                                selection: $selectedFacet
                            )
                        }
                    }
                }

                if !members.isEmpty {
                    Section("People") {
                        ForEach(members.prefix(topResultLimit)) { member in
                            NavigationLink {
                                CommunityMemberDetailView(member: member)
                            } label: {
                                CommunitySearchResultRow(member: member)
                            }
                        }

                        if members.count > topResultLimit {
                            SearchFacetNavigationButton(
                                title: "See all \(members.count) People",
                                destination: .people,
                                selection: $selectedFacet
                            )
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        case .services:
            if services.isEmpty {
                ContentUnavailableView("No Services", systemImage: "cloud")
            } else {
                List(services) { service in
                    NavigationLink {
                        DetailsView(service: service)
                    } label: {
                        ServiceSearchResultRow(service: service)
                    }
                }
                .listStyle(.plain)
            }
        case .people:
            if members.isEmpty {
                ContentUnavailableView("No People", systemImage: "person.crop.circle")
            } else {
                List(members) { member in
                    NavigationLink {
                        CommunityMemberDetailView(member: member)
                    } label: {
                        CommunitySearchResultRow(member: member)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

private struct SearchFacetBar: View {
    @Binding var selection: SearchFacet

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SearchFacet.allCases) { facet in
                    if selection == facet {
                        Button(facet.title) {
                            selection = facet
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                    } else {
                        Button(facet.title) {
                            withAnimation {
                                selection = facet
                            }
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
}

private struct SearchFacetNavigationButton: View {
    let title: String
    let destination: SearchFacet
    @Binding var selection: SearchFacet

    var body: some View {
        Button(title) {
            withAnimation {
                selection = destination
            }
        }
    }
}

private enum SearchFacet: String, CaseIterable, Identifiable {
    case topResults
    case services
    case people

    var id: Self { self }

    var title: String {
        switch self {
        case .topResults: "Top Results"
        case .services: "Services"
        case .people: "People"
        }
    }
}

private enum UnifiedSearchResult: Identifiable {
    case service(awsService)
    case member(CommunityMember)

    var id: String {
        switch self {
        case .service(let service): "service:\(service.id)"
        case .member(let member): "member:\(member.id)"
        }
    }

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

    var suggestion: String {
        switch self {
        case .service(let service): service.longName
        case .member(let member): member.name
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

private struct UnifiedSearchResultLink: View {
    let result: UnifiedSearchResult

    @ViewBuilder
    var body: some View {
        switch result {
        case .service(let service):
            NavigationLink {
                DetailsView(service: service)
            } label: {
                ServiceSearchResultRow(service: service)
            }
        case .member(let member):
            NavigationLink {
                CommunityMemberDetailView(member: member)
            } label: {
                CommunitySearchResultRow(member: member)
            }
        }
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
    SearchView(
        searchString: .constant("Lambda"),
        focusRequest: 0,
        isActive: true,
        onNavigate: { _ in }
    )
}
