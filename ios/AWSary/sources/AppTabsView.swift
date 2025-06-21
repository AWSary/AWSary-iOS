//
//  AppTabsView.swift
//  awsary (iOS)
//
//  Created by Tiago Rodrigues on 10/11/2024.
//

import SwiftUI

struct AppTabsView: View {
    @State private var searchText = ""
    
    var body: some View {
       TabView {
//           Tab("Today", systemImage: "newspaper.fill"){
//           }
           Tab("Glossary", systemImage: "books.vertical"){
               Glossary()
           }
//           Tab("Game", systemImage: "gamecontroller"){
//               Game()
//           }
//           Tab("Tools", systemImage: "wrench.and.screwdriver.fill"){
//           }
//           Tab("AAI Planner", systemImage: "calendar.badge.clock"){
//               AAIplannerContentView()
//           }
           Tab("Community", systemImage: "person.3.sequence.fill"){
               Text("Community")
           }
//           Tab(role:.search){
//           }
           Tab(role: .search) {
               NavigationStack {
                   Text("Search")
               }
           }
       }
       .tabViewStyle(.sidebarAdaptable)
       .searchable(text: $searchText)

    }
 }

#Preview {
    AppTabsView()
}
