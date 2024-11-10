//
//  AppTabsView.swift
//  awsary (iOS)
//
//  Created by Tiago Rodrigues on 10/11/2024.
//

import SwiftUI

struct AppTabsView: View {
    var body: some View {
       TabView {
//           Tab("Today", systemImage: "newspaper.fill"){
//           }
           Tab("Glossary", systemImage: "books.vertical"){
               Glossary()
           }
           Tab("Game", systemImage: "gamecontroller"){
               Game()
           }
//           Tab("Tools", systemImage: "wrench.and.screwdriver.fill"){
//           }
           Tab("AAI Planner", systemImage: "calendar.badge.clock"){
               AAIplannerContentView()
           }
//           Tab("Community", systemImage: "person.3.sequence.fill"){
//           }
//           Tab(role:.search){
//           }
       }
    }
 }

#Preview {
    AppTabsView()
}
