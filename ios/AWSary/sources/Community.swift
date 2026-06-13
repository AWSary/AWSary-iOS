//
//  Community.swift
//  awsary (iOS)
//
//  Created by Tiago Rodrigues on 06/08/2025.
//

import SwiftUI

public struct Community: View {
    @StateObject private var store = CommunityMemberStore()
    @State private var searchText = ""
    @State private var selectedStatus: String?
    @State private var selectedSpecialty: String?

    private var availableStatuses: [String] {
        sortedUniqueValues(store.members.flatMap(\.statuses))
    }

    private var availableSpecialties: [String] {
        sortedUniqueValues(store.members.flatMap(\.specialties))
    }

    private var filteredMembers: [CommunityMember] {
        store.members.filter {
            $0.matches(
                searchText: searchText,
                selectedStatus: selectedStatus,
                selectedSpecialty: selectedSpecialty
            )
        }
    }

    public var body: some View {
        NavigationStack {
            Group {
                if let errorMessage = store.errorMessage {
                    CommunityEmptyState(
                        systemImage: "exclamationmark.triangle",
                        title: "Community data unavailable",
                        message: errorMessage
                    )
                } else if store.members.isEmpty {
                    CommunityEmptyState(
                        systemImage: "person.3.sequence",
                        title: "Loading community",
                        message: "Preparing the community index."
                    )
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            CommunityHeaderView(memberCount: filteredMembers.count)

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
                        store.load()
                    }
                }
            }
            .navigationTitle("Community")
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search people, skills, or places"
            )
            .disableAutocorrection(true)
        }
    }

    private func sortedUniqueValues(_ values: [String]) -> [String] {
        Array(Set(values)).sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }
    }
}

private struct CommunityHeaderView: View {
    let memberCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Discover AWS community members")
                .font(.title2)
                .fontWeight(.bold)

            Text("\(memberCount) people indexed with searchable bios, locations, specialties, and community status tags.")
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

private struct CommunityMemberDetailView: View {
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
