//
//  AppTabsView.swift
//  awsary (iOS)
//
//  Created by Tiago Rodrigues on 10/11/2024.
//

import CoreSpotlight
import SwiftUI

struct AppTabsView: View {
    @State private var searchString = ""
    @State private var selectedTab: AppTab = .glossary
    @State private var searchFocusRequest = 0
    @StateObject private var deepLinkDispatcher = AWSaryDeepLinkDispatcher.shared
    @State private var requestedServiceID: Int?
    @State private var requestedHeroID: String?
    @State private var requestedUserGroupID: String?

    private var tabSelection: Binding<AppTab> {
        Binding {
            selectedTab
        } set: { newSelection in
            if newSelection == .search && selectedTab == .search {
                searchFocusRequest += 1
            }
            selectedTab = newSelection
        }
    }

    var body: some View {
       TabView(selection: tabSelection) {
           Tab("Glossary", systemImage: "books.vertical", value: .glossary) {
               Glossary(requestedServiceID: $requestedServiceID)
           }
           Tab("Community", systemImage: "person.3.sequence", value: .community) {
               Community(
                   requestedHeroID: $requestedHeroID,
                   requestedUserGroupID: $requestedUserGroupID
               )
           }
           Tab("Game", systemImage: "gamecontroller", value: .game) {
               Game()
           }
//           Tab("Tools", systemImage: "wrench.and.screwdriver.fill"){
//           }
           Tab("AAI Planner", systemImage: "calendar.badge.clock", value: .planner) {
               AAIplannerContentView()
           }

           Tab("Search", systemImage: "magnifyingglass", value: .search) {
               SearchView(
                   searchString: $searchString,
                   focusRequest: searchFocusRequest,
                   isActive: selectedTab == .search,
                   onNavigate: { selectedTab = $0 }
               )
           }
       }
       .tabViewStyle(.sidebarAdaptable)
       .onOpenURL { url in
           deepLinkDispatcher.open(url)
       }
       .onContinueUserActivity(CSSearchableItemActionType) { userActivity in
           deepLinkDispatcher.open(userActivity)
       }
       .onReceive(deepLinkDispatcher.$pendingDeepLink.compactMap { $0 }) { deepLink in
           handle(deepLink)
       }
    }

    private func handle(_ deepLink: AWSaryDeepLink) {
        switch deepLink {
        case .service(let id):
            selectedTab = .glossary
            requestedServiceID = id
        case .hero(let id):
            selectedTab = .community
            requestedHeroID = id
        case .userGroup(let id):
            selectedTab = .community
            requestedUserGroupID = id
        }

        deepLinkDispatcher.pendingDeepLink = nil
    }
 }

enum AppTab: Hashable {
    case community
    case glossary
    case game
    case planner
    case search
}

#Preview {
    AppTabsView()
}
