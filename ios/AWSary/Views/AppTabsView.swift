//
//  AppTabsView.swift
//  awsary (iOS)
//
//  Created by Tiago Rodrigues on 10/11/2024.
//

import SwiftUI

struct AppTabsView: View {
    @State private var searchString = ""
    @State private var selectedTab: AppTab = .community
    @State private var searchFocusRequest = 0

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
//            Tab("AWSary", systemImage: "house"){
//                HomeView()
//            }
           Tab("Community", systemImage: "person.3.sequence", value: .community) {
               Community()
           }
           Tab("Glossary", systemImage: "books.vertical", value: .glossary) {
               Glossary()
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
                   isActive: selectedTab == .search
               )
           }
       }
       .tabViewStyle(.sidebarAdaptable)
    }
 }

private enum AppTab: Hashable {
    case community
    case glossary
    case game
    case planner
    case search
}

#Preview {
    AppTabsView()
}
