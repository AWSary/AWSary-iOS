//
//  AboutView.swift
//  awsary
//
//  Created by Tiago Rodrigues on 20/07/2022.
//

import SwiftUI
import SwiftData
import StoreKit
import RevenueCat
import RevenueCatUI

private func awsaryRemoteURL(_ remoteURLString: String?, fallback fallbackURLString: String) -> URL {
   URL(string: remoteURLString ?? fallbackURLString) ?? URL(string: fallbackURLString)!
}

struct AboutView: View {
   @Environment(\.dismiss) var dismiss
   @Environment(\.modelContext) private var modelContext
   @StateObject private var awsServices = AwsServices()
   @Query var settings: [SystemSetting]
   @Query var cachedStats: [CachedAppStats]
   
   @State private var previewService: awsService?
   
   // State variables for app statistics
   @State private var appStats: AppStats?
   @State private var isLoadingStats = false
   
   // Computed property for awsServiceLogoWithLabel setting
   private var awsServiceLogoWithLabel: Bool {
      settings.first(where: { $0.key == "awsServiceLogoWithLabel" })?.boolValue ?? true
   }
   
   // Helper method to update or create a setting
   private func updateSetting(key: String, boolValue: Bool) {
      if let existingSetting = settings.first(where: { $0.key == key }) {
         existingSetting.boolValue = boolValue
         existingSetting.updatedAt = Date()
      } else {
         let newSetting = SystemSetting(key: key, value: boolValue)
         modelContext.insert(newSetting)
      }
      
      do {
         try modelContext.save()
      } catch {
         print("Failed to save setting: \(error)")
      }
   }
   
   // Function to load cached stats and fetch fresh data if needed
   private func loadAppStats() {
      // First, load from cache
      loadFromCache()
      
      // Then check if we need to fetch fresh data
      if shouldFetchFreshData() {
         fetchAppStatsFromAPI()
      }
   }
   
   private func loadFromCache() {
      if let cached = cachedStats.first {
         // Convert cached data to display format
         appStats = AppStats(
            currentVersion: cached.currentVersion,
            ratings: RatingInfo(
               version: cached.ratingVersion,
               ratingCount: cached.ratingCount,
               customMessage: cached.customMessage,
               lastUpdated: cached.lastUpdated
            ),
            featuredMessage: cached.featuredMessage,
            updateAvailable: cached.updateAvailable,
            links: AppStatsLinks(
               merchStore: cached.merchStoreURL,
               privacyPolicy: cached.privacyPolicyURL,
               termsOfUse: cached.termsOfUseURL,
               github: cached.githubURL
            ),
            support: AppStatsSupport(
               email: cached.supportEmail,
               feedbackSubject: cached.feedbackSubject,
               feedbackFooter: cached.feedbackFooter
            ),
            premium: AppStatsPremium(
               discountCode: cached.premiumDiscountCode,
               discountLabel: cached.premiumDiscountLabel
            ),
            about: AppStatsAbout(youtubeId: cached.aboutYoutubeID)
         )
      }
   }
   
   private func shouldFetchFreshData() -> Bool {
      guard let cached = cachedStats.first else {
         return true // No cache, need to fetch
      }
      
      // Cache is stale if older than 1 hour
      let cacheAge = Date().timeIntervalSince(cached.cachedAt)
      return cacheAge > 3600 // 1 hour in seconds
   }
   
   private func fetchAppStatsFromAPI() {
      guard !isLoadingStats else { return }
      
      isLoadingStats = true
      
      guard let url = URL(string: "https://api.awsary.com/app-stats") else {
         isLoadingStats = false
         return
      }
      
      URLSession.shared.dataTask(with: url) { data, response, error in
         DispatchQueue.main.async {
            isLoadingStats = false
            
            if let data = data {
               do {
                  let stats = try JSONDecoder().decode(AppStats.self, from: data)
                  self.appStats = stats
                  self.saveToCacheAndUpdate(stats)
               } catch {
                  print("Failed to decode app stats: \(error)")
               }
            }
         }
      }.resume()
   }
   
   private func saveToCacheAndUpdate(_ stats: AppStats) {
      // Remove old cached data
      for oldStats in cachedStats {
         modelContext.delete(oldStats)
      }
      
      // Save new data
      let newCachedStats = CachedAppStats(from: stats)
      modelContext.insert(newCachedStats)
      
      do {
         try modelContext.save()
      } catch {
         print("Failed to save app stats to cache: \(error)")
      }
   }

   private func openAppReview() {
      let appId = "1634871091"
      guard let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appId)?mt=8&action=write-review") else {
         return
      }
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
   }

   private func openAppStore() {
      let appId = "1634871091"
      guard let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appId)") else {
         return
      }

      UIApplication.shared.open(url, options: [:], completionHandler: nil)
   }

   private func sendFeedback() {
      var components = URLComponents()
      components.scheme = "mailto"
      components.path = appStats?.supportEmail ?? "mail@tig.pt"
      let feedbackBodySuffix = appStats?.feedbackFooter.map { "\n\n\($0)" } ?? ""
      components.queryItems = [
         URLQueryItem(name: "subject", value: appStats?.feedbackSubject ?? "Feedback on AWSary"),
         URLQueryItem(
            name: "body",
            value: "\n\n--\nAWSary Version: \(Bundle.main.appVersionLong) (\(Bundle.main.appBuild))\n\nScreen: Settings\(feedbackBodySuffix)"
         )
      ]

      guard let url = components.url else {
         NSLog("Failed to create mailto URL")
         return
      }
      UIApplication.shared.open(url)
   }

   var body: some View {
      NavigationStack {
         List {
            if let featuredMessage = appStats?.visibleFeaturedMessage {
               Section {
                  Label(featuredMessage, systemImage: "sparkles")
               }
            }

            if let stats = appStats, stats.updateAvailable {
               Section {
                  Button(action: openAppStore) {
                     Label {
                        VStack(alignment: .leading, spacing: 3) {
                           Text("Update AWSary")
                           Text("Version \(stats.currentVersion) is available.")
                              .font(.caption)
                              .foregroundStyle(.secondary)
                        }
                     } icon: {
                        Image(systemName: "arrow.down.app.fill")
                     }
                  }
               }
            }

            Section {
               NavigationLink {
                  AboutSettingsDetailsView(
                     showServiceLogoName: Binding(
                        get: { awsServiceLogoWithLabel },
                        set: { updateSetting(key: "awsServiceLogoWithLabel", boolValue: $0) }
                     ),
                     previewService: previewService,
                     appStats: appStats
                  )
               } label: {
                  AboutNavigationRow(
                     title: "Preferences & Premium",
                     subtitle: "Service logos and your subscription",
                     systemImage: "gearshape.fill"
                  )
               }

               NavigationLink {
                  AboutAWSaryDetailsView(appStats: appStats)
               } label: {
                  AboutNavigationRow(
                     title: "About AWSary",
                     subtitle: "The story and the person behind the app",
                     systemImage: "person.crop.circle"
                  )
               }

               NavigationLink {
                  AboutContactDetailsView(
                     ratingInfo: appStats?.ratings,
                     isLoadingStats: isLoadingStats,
                     openReview: openAppReview,
                     sendFeedback: sendFeedback
                  )
               } label: {
                  AboutNavigationRow(
                     title: "Contact & Feedback",
                     subtitle: "Get help or share what you think",
                     systemImage: "envelope.fill"
                  )
               }

               NavigationLink {
                  AboutLegalDetailsView(appStats: appStats)
               } label: {
                  AboutNavigationRow(
                     title: "Legal",
                     subtitle: "Terms of use and privacy policy",
                     systemImage: "checkmark.shield.fill"
                  )
               }
            }
         }
         .navigationTitle("Settings")
         .navigationBarTitleDisplayMode(.inline)
         .toolbar {
            ToolbarItem(placement: .confirmationAction){
               Button("Done", action: {
                  dismiss()
               })
            }
         }
         .onAppear {
            // Keep the same preview service when returning from a detail screen.
            if previewService == nil {
               previewService = awsServices.services.randomElement()
            }
            // Load app statistics (from cache first, then API if needed)
            loadAppStats()
         }
      }
      .tint(Color(red: 0.357, green: 0.361, blue: 1.0))
   }
}

extension View {
   /// Adds the shared Settings entry point to a main screen inside a NavigationStack.
   func awsarySettingsToolbar() -> some View {
      modifier(AWSarySettingsToolbar())
   }
}

private struct AWSarySettingsToolbar: ViewModifier {
   @State private var showingSettings = false

   func body(content: Content) -> some View {
      content
         .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
               Button {
                  showingSettings = true
               } label: {
                  Label("Settings", systemImage: "gearshape")
               }
               .labelStyle(.iconOnly)
               .tint(Color(red: 0.357, green: 0.361, blue: 1.0))
            }
         }
         .sheet(isPresented: $showingSettings) {
            AboutView()
         }
   }
}

private struct AboutNavigationRow: View {
   let title: String
   let subtitle: String
   let systemImage: String

   var body: some View {
      HStack(spacing: 14) {
         Image(systemName: systemImage)
            .font(.headline)
            .foregroundStyle(.white)
            .frame(width: 34, height: 34)
            .background(Color(red: 0.357, green: 0.361, blue: 1.0).gradient, in: RoundedRectangle(cornerRadius: 9))

         VStack(alignment: .leading, spacing: 3) {
            Text(title)
               .font(.body.weight(.medium))
            Text(subtitle)
               .font(.caption)
               .foregroundStyle(.secondary)
         }
      }
      .padding(.vertical, 4)
   }
}

private struct AboutAWSaryDetailsView: View {
   let appStats: AppStats?

   var body: some View {
      List {
         Section("Why AWSary") {
            Text("AWSary is built by Tiago Rodrigues, an AWS Cloud Consultant and Trainer. New AWS services are released all the time, and sometimes you just want a quick dictionary definition.")
            Text("Inspired by drawing AWS architecture diagrams on iPad with colleagues, clients, and students, AWSary combines a practical dictionary with service logos you can drag into your favorite drawing tools.")
         }

         Section("How to use AWSary") {
            Text("Search for an AWS service to read its definition. You can also drag its logo into your favorite drawing application.")
            MyYoutubePlayer(youtube_id: appStats?.aboutYoutubeID ?? "c0SjbhRR3lk")
         }

         Section("Open source") {
            Link(destination: awsaryRemoteURL(appStats?.githubURLString, fallback: "https://github.com/tigpt/AWSary/")) {
               Label("Help develop AWSary on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
            }
         }

         Section("App information") {
            LabeledContent("Version", value: Bundle.main.appVersionLong)
            LabeledContent("Build", value: Bundle.main.appBuild)
         }
      }
      .navigationTitle("About AWSary")
      .navigationBarTitleDisplayMode(.inline)
   }
}

private struct AboutSettingsDetailsView: View {
   @Binding var showServiceLogoName: Bool
   let previewService: awsService?
   let appStats: AppStats?
   @ObservedObject private var userModel = UserViewModel.shared
   @State private var isRestoringPurchases = false
   @State private var restoreMessage: String?

   var body: some View {
      List {
         Section {
            Toggle("Show name on service logo", isOn: $showServiceLogoName)
            if let previewService {
               AWSserviceImagePlaceHolderView(service: previewService, showLabel: showServiceLogoName)
                  .frame(maxWidth: .infinity, minHeight: 160)
                  .padding(.vertical, 8)
                  .accessibilityLabel("Service logo preview: \(previewService.name)")
            }
         } header: {
            Text("Service logos")
         } footer: {
            Text("Choose whether service names appear on logos, including when you drag them into a drawing app.")
         }

         Section("AWSary Premium") {
            Link(destination: awsaryRemoteURL(appStats?.merchStoreURLString, fallback: "https://bit.ly/awsary-merch")) {
               Label("AWSary Merch Store", systemImage: "storefront")
            }

            if userModel.subscriptionActive {
               let discountCode = appStats?.premiumDiscountCode ?? "GSC293ZEQD"
               let discountLabel = appStats?.premiumDiscountLabel ?? "10% Discount on AWSary Merch Store"
               Button {
                  UIPasteboard.general.string = discountCode
               } label: {
                  Label("\(discountLabel): \(discountCode)", systemImage: "doc.on.doc")
               }
            }

            if userModel.subscriptionActive {
               Link(destination: awsaryRemoteURL(nil, fallback: "https://apps.apple.com/account/subscriptions")) {
                  Label("Manage Subscription", systemImage: "creditcard")
               }
            } else {
               NavigationLink {
                  PaywallView(displayCloseButton: true)
               } label: {
                  Label("Get AWSary Premium", systemImage: "sparkles")
               }
            }

            Button(action: restorePurchases) {
               HStack {
                  Label("Restore Purchases", systemImage: "arrow.triangle.2.circlepath")
                  Spacer()
                  if isRestoringPurchases {
                     ProgressView()
                  }
               }
            }
            .disabled(isRestoringPurchases)
         }
      }
      .navigationTitle("Preferences & Premium")
      .navigationBarTitleDisplayMode(.inline)
      .alert("Restore Purchases", isPresented: Binding(
         get: { restoreMessage != nil },
         set: { if !$0 { restoreMessage = nil } }
      )) {
         Button("OK", role: .cancel) { restoreMessage = nil }
      } message: {
         Text(restoreMessage ?? "")
      }
   }

   private func restorePurchases() {
      isRestoringPurchases = true
      Purchases.shared.restorePurchases { customerInfo, error in
         DispatchQueue.main.async {
            isRestoringPurchases = false
            if let error {
               restoreMessage = error.localizedDescription
            } else if let customerInfo {
               userModel.customerInfo = customerInfo
               restoreMessage = userModel.subscriptionActive
                  ? "Your AWSary Premium subscription has been restored."
                  : "No active subscription was found for your Apple Account."
            } else {
               restoreMessage = "Unable to restore purchases. Please try again."
            }
         }
      }
   }
}

private struct AboutContactDetailsView: View {
   let ratingInfo: RatingInfo?
   let isLoadingStats: Bool
   let openReview: () -> Void
   let sendFeedback: () -> Void

   var body: some View {
      List {
         Section("Feedback") {
            Button(action: openReview) {
               Label {
                  VStack(alignment: .leading, spacing: 3) {
                     Text("Rate AWSary")
                     ratingMessage
                        .font(.caption)
                        .foregroundStyle(.secondary)
                  }
               } icon: {
                  Image(systemName: "star.fill")
               }
            }

            Button(action: sendFeedback) {
               Label {
                  VStack(alignment: .leading, spacing: 3) {
                     Text("Send Feedback")
                     Text("Feedback emails are lovely to read!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                  }
               } icon: {
                  Image(systemName: "envelope.fill")
               }
            }
         }
      }
      .navigationTitle("Contact & Feedback")
      .navigationBarTitleDisplayMode(.inline)
   }

   @ViewBuilder
   private var ratingMessage: some View {
      if let ratingInfo {
         Text(ratingInfo.displayMessage)
      } else if isLoadingStats {
         Text("Loading rating info…")
      } else {
         Text("Be one of the first to rate this version.")
      }
   }
}

private struct AboutLegalDetailsView: View {
   let appStats: AppStats?

   var body: some View {
      List {
         Section {
            Link(destination: awsaryRemoteURL(appStats?.termsOfUseURLString, fallback: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula")) {
               Label("Terms of Use (EULA)", systemImage: "doc.text")
            }
            Link(destination: awsaryRemoteURL(appStats?.privacyPolicyURLString, fallback: "https://tig.pt/awsary-privacy")) {
               Label("Privacy Policy", systemImage: "hand.raised.fill")
            }
         }
      }
      .navigationTitle("Legal")
      .navigationBarTitleDisplayMode(.inline)
   }
}

#Preview {
   AboutView()
      .modelContainer(for: [SystemSetting.self, CachedAppStats.self], inMemory: true)
}

extension Bundle {
    public var appName: String           { getInfo("CFBundleName") }
    public var displayName: String       { getInfo("CFBundleDisplayName") }
    public var language: String          { getInfo("CFBundleDevelopmentRegion") }
    public var identifier: String        { getInfo("CFBundleIdentifier") }
    public var copyright: String         { getInfo("NSHumanReadableCopyright").replacingOccurrences(of: "\\\\n", with: "\n") }
    
    public var appBuild: String          { getInfo("CFBundleVersion") }
    public var appVersionLong: String    { getInfo("CFBundleShortVersionString") }
    //public var appVersionShort: String { getInfo("CFBundleShortVersion") }
    
    fileprivate func getInfo(_ str: String) -> String { infoDictionary?[str] as? String ?? "⚠️" }
}
