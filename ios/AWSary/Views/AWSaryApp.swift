//
//  awsaryApp.swift
//  Shared
//
//  Created by Tiago Rodrigues on 15/07/2022.
//

import SwiftUI

import SwiftData
import RevenueCat

@main
struct awsaryApp: App {
    init() {
        // RevenueCat
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: Constants.apiKey)
        
        Purchases.shared.delegate = PurchasesDelegateHandler.shared
    }

   
   var body: some Scene {
      WindowGroup {
          AppTabsView()
            .task {
                AWSaryContentIndexer.scheduleIndexingIfNeeded()

                do {
                    // Fetch the available offerings
                    UserViewModel.shared.offerings = try await Purchases.shared.offerings()
                } catch {
                    print("Error fetching offerings: \(error)")
                }
            }
            .accentColor(Color(red: 0.357, green: 0.361, blue: 1.0))
      }
      .modelContainer(for: [SystemSetting.self, CachedAppStats.self])
   }
}
