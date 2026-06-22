//
//  Community.swift
//  awsary (iOS)
//
//  Created by Tiago Rodrigues on 06/08/2025.
//

import SwiftUI

public struct Community: View {
    @StateObject private var memberStore = CommunityMemberStore()
    @StateObject private var userGroupStore = CommunityUserGroupStore()
    @State private var selectedDirectory = CommunityDirectory.people
    @State private var searchText = ""
    @State private var selectedStatus: String?
    @State private var selectedSpecialty: String?
    @State private var selectedCountry: String?
    @State private var selectedPlatform: String?

    private var availableStatuses: [String] {
        sortedUniqueValues(memberStore.members.flatMap(\.statuses))
    }

    private var availableSpecialties: [String] {
        sortedUniqueValues(memberStore.members.flatMap(\.specialties))
    }

    private var availableCountries: [String] {
        sortedUniqueValues(userGroupStore.groups.map(\.location.country))
    }

    private var availablePlatforms: [String] {
        sortedUniqueValues(userGroupStore.groups.map(\.platformName))
    }

    private var filteredMembers: [CommunityMember] {
        memberStore.members.filter {
            $0.matches(
                searchText: searchText,
                selectedStatus: selectedStatus,
                selectedSpecialty: selectedSpecialty
            )
        }
    }

    private var filteredUserGroups: [CommunityUserGroup] {
        userGroupStore.groups.filter {
            $0.matches(
                searchText: searchText,
                selectedCountry: selectedCountry,
                selectedPlatform: selectedPlatform
            )
        }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Community directory", selection: $selectedDirectory) {
                    ForEach(CommunityDirectory.allCases) { directory in
                        Text(directory.title).tag(directory)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 10)

                if selectedDirectory == .people {
                    peopleContent
                } else {
                    userGroupsContent
                }
            }
            .navigationTitle("Community")
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: selectedDirectory.searchPrompt
            )
            .disableAutocorrection(true)
            .onChange(of: selectedDirectory) {
                searchText = ""
            }
        }
    }

    @ViewBuilder
    private var peopleContent: some View {
        if let errorMessage = memberStore.errorMessage {
            CommunityEmptyState(
                systemImage: "exclamationmark.triangle",
                title: "Community data unavailable",
                message: errorMessage
            )
        } else if memberStore.members.isEmpty {
            CommunityEmptyState(
                systemImage: "person.3.sequence",
                title: "Loading community",
                message: "Preparing the community index."
            )
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    CommunityHeaderView(
                        title: "Discover AWS community members",
                        message: "\(filteredMembers.count) people indexed with searchable bios, locations, specialties, and community status tags."
                    )

                    if availableStatuses.count > 1 {
                        CommunityFacetSection(
                            title: "Status",
                            values: availableStatuses,
                            selectedValue: selectedStatus
                        ) { status in
                            selectedStatus = selectedStatus == status ? nil : status
                        }
                    }

                    CommunityFacetSection(
                        title: "Specialty",
                        values: availableSpecialties,
                        selectedValue: selectedSpecialty
                    ) { specialty in
                        selectedSpecialty = selectedSpecialty == specialty ? nil : specialty
                    }

                    if filteredMembers.isEmpty {
                        CommunityEmptyState(
                            systemImage: "magnifyingglass",
                            title: "No members found",
                            message: "Try another name, location, specialty, or keyword."
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.top, 48)
                    } else {
                        ForEach(filteredMembers) { member in
                            NavigationLink(destination: CommunityMemberDetailView(member: member)) {
                                CommunityMemberRow(member: member)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .refreshable {
                memberStore.load()
            }
        }
    }

    @ViewBuilder
    private var userGroupsContent: some View {
        if let errorMessage = userGroupStore.errorMessage {
            CommunityEmptyState(
                systemImage: "exclamationmark.triangle",
                title: "User Group data unavailable",
                message: errorMessage
            )
        } else if userGroupStore.groups.isEmpty {
            CommunityEmptyState(
                systemImage: "person.3.fill",
                title: "Loading User Groups",
                message: "Preparing the global User Group directory."
            )
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    CommunityHeaderView(
                        title: "Find an AWS User Group",
                        message: "Explore \(filteredUserGroups.count) communities across \(availableCountries.count) countries and connect with AWS builders near you."
                    )

                    HStack {
                        Text("Country")
                            .font(.headline)

                        Spacer()

                        Menu {
                            Button("All countries") {
                                selectedCountry = nil
                            }

                            ForEach(availableCountries, id: \.self) { country in
                                Button(country) {
                                    selectedCountry = country
                                }
                            }
                        } label: {
                            Label(selectedCountry ?? "All countries", systemImage: "globe")
                                .font(.subheadline)
                        }
                    }

                    CommunityFacetSection(
                        title: "Platform",
                        values: availablePlatforms,
                        selectedValue: selectedPlatform
                    ) { platform in
                        selectedPlatform = selectedPlatform == platform ? nil : platform
                    }

                    if filteredUserGroups.isEmpty {
                        CommunityEmptyState(
                            systemImage: "magnifyingglass",
                            title: "No User Groups found",
                            message: "Try another name, country, platform, or keyword."
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.top, 48)
                    } else {
                        ForEach(filteredUserGroups) { userGroup in
                            NavigationLink(destination: CommunityUserGroupDetailView(userGroup: userGroup)) {
                                CommunityUserGroupRow(userGroup: userGroup)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .refreshable {
                userGroupStore.load()
            }
        }
    }

    private func sortedUniqueValues(_ values: [String]) -> [String] {
        Array(Set(values)).sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }
    }
}

private enum CommunityDirectory: String, CaseIterable, Identifiable {
    case people
    case userGroups

    var id: Self { self }

    var title: String {
        switch self {
        case .people: "People"
        case .userGroups: "User Groups"
        }
    }

    var searchPrompt: String {
        switch self {
        case .people: "Search people, skills, or places"
        case .userGroups: "Search User Groups, topics, or places"
        }
    }
}

private struct CommunityHeaderView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct CommunityFacetSection: View {
    let title: String
    let values: [String]
    let selectedValue: String?
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(values, id: \.self) { value in
                        CommunityFacetChip(
                            title: value,
                            isSelected: selectedValue == value
                        ) {
                            onSelect(value)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

private struct CommunityFacetChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.orange : Color(.secondarySystemGroupedBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct CommunityMemberRow: View {
    let member: CommunityMember

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ImageLoaderView(urlString: member.imageURL, resizingMode: .fill)
                .frame(width: 64, height: 64)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color(.separator), lineWidth: 0.5)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(member.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if !member.location.isEmpty {
                    Label(member.location, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                CommunityTagFlow(tags: Array(member.tags.prefix(3)))

                Text(member.bio)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 6)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct CommunityUserGroupRow: View {
    let userGroup: CommunityUserGroup

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CommunityUserGroupImage(userGroup: userGroup, size: 64)

            VStack(alignment: .leading, spacing: 6) {
                Text(userGroup.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Label(userGroup.location.displayName, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    CommunityTagFlow(tags: [userGroup.platformName])

                    if let memberCount = userGroup.activity?.memberCount {
                        Label(memberCount.formatted(), systemImage: "person.2")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if !userGroup.summary.isEmpty {
                    Text(userGroup.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 6)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct CommunityUserGroupImage: View {
    let userGroup: CommunityUserGroup
    let size: CGFloat

    var body: some View {
        Group {
            if userGroup.imageURL.isEmpty {
                Image(systemName: "person.3.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.22)
                    .foregroundStyle(.orange)
                    .background(Color.orange.opacity(0.14))
            } else {
                ImageLoaderView(urlString: userGroup.imageURL, resizingMode: .fill)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
    }
}

struct CommunityUserGroupDetailView: View {
    let userGroup: CommunityUserGroup

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 12) {
                    CommunityUserGroupImage(userGroup: userGroup, size: 132)

                    Text(userGroup.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Label(userGroup.location.displayName, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    CommunityTagFlow(tags: [userGroup.platformName])
                }
                .frame(maxWidth: .infinity)

                if let activity = userGroup.activity {
                    CommunityUserGroupActivityView(activity: activity)
                }

                if !userGroup.summary.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.headline)

                        Text(userGroup.summary)
                            .font(.body)
                    }
                }

                if !userGroup.topics.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Topics")
                            .font(.headline)

                        CommunityTagFlow(tags: Array(userGroup.topics.prefix(4)))
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Links")
                        .font(.headline)

                    if let joinURL = URL(string: userGroup.joinURL), !userGroup.joinURL.isEmpty {
                        Link(destination: joinURL) {
                            CommunityLinkRow(label: "Join this User Group", systemImage: "person.badge.plus")
                        }
                    }

                    ForEach(userGroup.links.filter { $0.url != userGroup.joinURL }) { link in
                        if let url = URL(string: link.url) {
                            Link(destination: url) {
                                CommunityLinkRow(label: link.label, systemImage: "link")
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(userGroup.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CommunityUserGroupActivityView: View {
    let activity: CommunityUserGroupActivity

    private var metrics: [(label: String, value: Int, icon: String)] {
        [
            activity.memberCount.map { ("Members", $0, "person.2") },
            activity.upcomingEventCount.map { ("Upcoming", $0, "calendar") },
            activity.pastEventCount.map { ("Past events", $0, "calendar.badge.checkmark") }
        ].compactMap { $0 }
    }

    var body: some View {
        if !metrics.isEmpty {
            HStack(spacing: 8) {
                ForEach(metrics, id: \.label) { metric in
                    VStack(spacing: 6) {
                        Image(systemName: metric.icon)
                            .foregroundStyle(.orange)

                        Text(metric.value.formatted())
                            .font(.headline)

                        Text(metric.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

struct CommunityMemberDetailView: View {
    let member: CommunityMember

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .center, spacing: 12) {
                    ImageLoaderView(urlString: member.imageURL, resizingMode: .fill)
                        .frame(width: 132, height: 132)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(.separator), lineWidth: 0.5)
                        )

                    Text(member.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    if !member.location.isEmpty {
                        Label(member.location, systemImage: "mappin.and.ellipse")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    CommunityTagFlow(tags: member.tags)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Bio")
                        .font(.headline)

                    Text(member.bio)
                        .font(.body)
                        .foregroundStyle(.primary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Links")
                        .font(.headline)

                    if let profileURL = URL(string: member.profileURL) {
                        Link(destination: profileURL) {
                            CommunityLinkRow(label: "AWS profile", systemImage: "person.crop.circle")
                        }
                    }

                    ForEach(member.links) { link in
                        if let url = URL(string: link.url) {
                            Link(destination: url) {
                                CommunityLinkRow(label: link.label, systemImage: "link")
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(member.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CommunityTagFlow: View {
    let tags: [String]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.14))
                    .foregroundStyle(.orange)
                    .clipShape(Capsule())
            }
        }
    }
}

private struct CommunityLinkRow: View {
    let label: String
    let systemImage: String

    var body: some View {
        HStack {
            Label(label, systemImage: systemImage)
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "arrow.up.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct CommunityEmptyState: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    Community()
}
