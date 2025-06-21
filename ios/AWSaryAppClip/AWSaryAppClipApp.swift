//
//  AWSaryAppClipApp.swift
//  AWSaryAppClip
//
//  Created by Tiago Rodrigues on 09/03/2024.
//

import SwiftUI
import SwiftData
import RevenueCat

@main
struct AWSaryAppClipApp: App {
   
    init() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: Constants.apiKey)
    }

   
   var body: some Scene {
      WindowGroup {
         OnboardingView()
            .task {
                do {
                    // Fetch the available offerings
                    UserViewModel.shared.offerings = try await Purchases.shared.offerings()
                } catch {
                    print("Error fetching offerings: \(error)")
                }
            }
            .accentColor(Color(red:1.0, green: 0.5, blue: 0.0))
      }
      .modelContainer(for: [SystemSetting.self])
   }
}
