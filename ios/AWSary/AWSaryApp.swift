//
//  awsaryApp.swift
//  Shared
//
//  Created by Tiago Rodrigues on 15/07/2022.
//

import SwiftUI
import Sentry

import SwiftData
import RevenueCat

@main
struct awsaryApp: App {
    init() {
        SentrySDK.start { options in
            options.dsn = "https://477881ef4da534dc2a5d623681bb8ff1@o4509860037001216.ingest.de.sentry.io/4509860041982032"
            #if DEBUG
            options.debug = true
            #else
            options.debug = false
            #endif

            // Adds IP for users.
            // For more information, visit: https://docs.sentry.io/platforms/apple/data-management/data-collected/
            options.sendDefaultPii = true

            // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
            // We recommend adjusting this value in production.
            options.tracesSampleRate = 0.3

            // Configure profiling. Visit https://docs.sentry.io/platforms/apple/profiling/ to learn more.
            options.configureProfiling = {
                $0.sessionSampleRate = 0.2
                $0.lifecycle = .ui
            }

            // Uncomment the following lines to add more data to your events
            // options.attachScreenshot = true // This adds a screenshot to the error events
            // options.attachViewHierarchy = true // This adds the view hierarchy to the error events
            
            // Enable experimental logging features
            #if DEBUG
            options.experimental.enableLogs = true
            #else
            options.experimental.enableLogs = false
            #endif
        }
        // Remove the next line after confirming that your Sentry integration is working.
//        SentrySDK.capture(message: "This app uses Sentry! :)")
        
        // RevenueCat
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: Constants.apiKey)
        
        Purchases.shared.delegate = PurchasesDelegateHandler.shared
    }

   
   var body: some Scene {
      WindowGroup {
          AppTabsView()
            .environmentObject(AwsServices.shared)
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
      .modelContainer(for: [SystemSetting.self, CachedAppStats.self])
   }
}
