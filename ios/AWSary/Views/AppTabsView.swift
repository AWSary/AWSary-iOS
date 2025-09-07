//
//  AppTabsView.swift
//  awsary (iOS)
//
//  Created by Tiago Rodrigues on 10/11/2024.
//

import SwiftUI

struct AppTabsView: View {
    @State private var searchString = ""
    
    
    var body: some View {
       TabView {
//            Tab("AWSary", systemImage: "house"){
//                HomeView()
//            }
//            Tab("Community", systemImage: "person.3.sequence"){
//                Community()
//            } 
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

//           Tab(role: .search) {
//               SearchView()
//           }
       }
       .tabViewStyle(.sidebarAdaptable)
    }
 }

#Preview {
    AppTabsView()
}
