//
//  SettingsView.swift
//  awsary
//
//  Created by Tiago Rodrigues on 20/07/2022.
//

import SwiftUI
import SwiftData
import StoreKit
import RevenueCat
import RevenueCatUI

struct AboutView: View {
   @Environment(\.dismiss) var dismiss
   @Environment(\.modelContext) private var modelContext
   @ObservedObject var userModel = UserViewModel.shared
   @ObservedObject var awsServices = AwsServices()
   @Query var settings: [SystemSetting]
   @Query var cachedStats: [CachedAppStats]
   
   // Add state variable to store the random service
   @State private var randomAWSservice: awsService?
   
   // State variables for app statistics
   @State private var appStats: AppStats?
   @State private var isLoadingStats = false
   
   // Computed property for awsServiceLogoWithLabel setting
   private var awsServiceLogoWithLabel: Bool {
      get {
         return settings.first(where: { $0.key == "awsServiceLogoWithLabel" })?.boolValue ?? true
      }
      set {
         updateSetting(key: "awsServiceLogoWithLabel", boolValue: newValue)
      }
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
            updateAvailable: cached.updateAvailable
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
   
   var body: some View {
      NavigationStack{
         List{
            Section(header: Text("Configure service logos")){
               VStack{
                  Toggle(isOn: Binding(
                     get: { awsServiceLogoWithLabel },
                     set: { updateSetting(key: "awsServiceLogoWithLabel", boolValue: $0) }
                  )){
                     Text("Show name on service logo")
                  }
//                  .disabled(!self.userModel.subscriptionActive)
//                  Text("")
//                  Text("Drag-and-drop each of the icons bellow, to test it on your diagrams.\n\nTap to load a diferent random icon, purchange a subscription to enable on all logos.")
                  if let service = randomAWSservice {
                     LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 110))], content: {
                           
                           if (awsServiceLogoWithLabel){
                              AWSserviceImagePlaceHolderView(service: service, showLabel: false)
                              AWSserviceImagePlaceHolderView(service: service, showLabel: true)
                                 .padding(.horizontal, 8)
                                 .padding(.vertical, 6)
                                 .background(Color(red:1.0, green: 0.5, blue: 0.0))
                                 .cornerRadius(8.0)
                           }else{
                              AWSserviceImagePlaceHolderView(service: service, showLabel: false)
                                 .padding(.horizontal, 8)
                                 .padding(.vertical, 6)
                                 .background(Color(red:1.0, green: 0.5, blue: 0.0))
                                 .cornerRadius(8.0)
                              AWSserviceImagePlaceHolderView(service: service, showLabel: true)
                           }
                        }
                     ).frame(minHeight: 160)
                  }
               }
            }
            Section(header: Text("AWSary Premium")){
               Label("AWSary Merch Store", systemImage: "storefront").onTapGesture {
                  guard let url = URL(string: "https://bit.ly/awsary-merch") else {
                     return
                  }
                  UIApplication.shared.open(url, options: [:], completionHandler: nil)
               }
               if self.userModel.subscriptionActive{
                  Label("Discount Code: GSC293ZEQD", systemImage: "doc.on.doc").onTapGesture {
                     UIPasteboard.general.string = "GSC293ZEQD"
                  }
                   NavigationLink(destination:PaywallView(displayCloseButton: true)){
                       Label("Manage Subscription", systemImage: "heart.fill")
                   }
               } else {
                   NavigationLink(destination:PaywallView(displayCloseButton: true)){
                       Label("Purchase Subscription", systemImage: "creditcard")
                   }
                  Label("Restore Purchase", systemImage: "arrow.triangle.2.circlepath").onTapGesture {
                     Purchases.shared.restorePurchases { customerInfo, error in
                        //... check customerInfo to see if entitlement is now active
                     }
                  }
               }
            }
            Section(header: Text("Feedback")){
//              Label("Send Feedback", systemImage: "envelope")
               Label {
                  VStack(alignment: .leading){
                     Text("Rate version \(Bundle.main.appVersionLong) of AWSary")
                     if let stats = appStats {
                        Text("Join the \(stats.ratings.ratingCount) wonderful people who have already rated this version!").font(.footnote).opacity(0.6)
                     } else if isLoadingStats {
                        Text("Loading rating info...").font(.footnote).opacity(0.6)
                     } else {
                        Text("Be one of the first to rate this version!").font(.footnote).opacity(0.6)
                     }
                  }
               } icon:{
                  Image(systemName: "star.fill")                  //                     .frame(width: 40, height: 40)
                  //                     .foregroundColor(Color.white)
                  //                     .background(Color.orange)
                  //                     .cornerRadius(7)
               }.onTapGesture {
                  let appId = "1634871091"
                  let url_string = "itms-apps://itunes.apple.com/app/id\(appId)?mt=8&action=write-review"
                  guard let url = URL(string: url_string) else {
                     return
                  }
                  UIApplication.shared.open(url, options: [:], completionHandler: nil)
               }
               
               Label {
                  VStack(alignment: .leading){
                     Text("Send Feedback")
                     Text("Feedback emails are lovely to read!").font(.footnote).opacity(0.6)
                  }
               } icon:{
                  Image(systemName: "envelope")
               }.onTapGesture {
                  let address = "mail@tig.pt"
                  let subject = "Feedback on AWSary"

                  // Example email body with useful info for bug reports
                  let body = "\n\n--\nAWSary Version: \(Bundle.main.appVersionLong) (\(Bundle.main.appBuild))\n\nScreen: About"

                  // Build the URL from its components
                  var components = URLComponents()
                  components.scheme = "mailto"
                  components.path = address
                  components.queryItems = [
                        URLQueryItem(name: "subject", value: subject),
                        URLQueryItem(name: "body", value: body)
                  ]

                  guard let email_url = components.url else {
                      NSLog("Failed to create mailto URL")
                      return
                  }
                  UIApplication.shared.open(email_url) { success in
                    // handle success or failure
                  }
               }
               
            }
            Section(header: Text("Why AWSary")){
               Text("I'm an AWS Cloud Consultant and Trainer.\n\nNew AWS Services are released all the time, and sometimes you just want a quick dictionary definition.\n\nI also draw AWS Cloud Architecture diagrams daily on iPad, to explore ideas either with Colleagues, Clients or Students.\n\nGood drawing Applications don't have AWS services logos, so on top of this dictionary I enabled the drag and drop of the logos to 3rd party drawing tools.\n\n This App is a great AWS Cloud Consultant companion tool.\n\nHelp develop this app at [GitHub](https://github.com/tigpt/AWSary/).")
            }
            Section(header: Text("How to use AWSary")){
               Text("Search for the name of an AWS service, you can open and look for the definition of it. You can also drag and drop the service logo to your favorite drawing application. (Check video below)")
               MyYoutubePlayer(youtube_id: "c0SjbhRR3lk")
            }
            Section(){
               Link("Terms of Use (EULA)", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula")!)
               Link("Privacy Policy", destination: URL(string: "https://tig.pt/awsary-privacy")!)
            }
//            Section(header: Text("AWSary.com")){
//               Text("This is a hobby project from Tiago Rodrigues to help more people learn about Cloud, specialy AWS. Special tanks to tecRacer for supporting the backend.").lineLimit(100)
//            }
//            Section(header: Text("Help developing this app")){
//               Text("Get involved in this application")
//            }
//            Section(header: Text("Contact & Help")){
//               Text("FAQ - Frequently Asked Questions")
//            }
//            Section(header: Text("info")){
//               Text("Acknowledgements")
//               Text("Colophon")
//               Text("Privacy Policy")
//            }
//            Section(header: Text("Icon")){
//               Text("Icon 1")
//               Text("Icon 2")
//               Text("Icon 3")
//            }
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
            // Initialize the random service only once when the view appears
            if randomAWSservice == nil {
               randomAWSservice = awsServices.getRandomElement()
            }
            // Load app statistics (from cache first, then API if needed)
            loadAppStats()
         }
      }.accentColor(Color(red:1.0, green: 0.5, blue: 0.0))
   }
   //   var body: some View {
   //      NavigationStack{
   ////         VStack{
   ////            HStack{
   ////               Spacer()
   ////               Button(action: {
   ////                  dismiss()
   ////               }){
   ////                  Text("Done").font(.title3 .bold()).padding(10)
   ////               }
   ////            }.background(Color .yellow)
   ////            ScrollView{
   ////               Text("AWSary.com").font(.largeTitle)
   ////               Text("Multiline \ntext \nis called \nTextEditor")
   ////            }.background(Color .red)
   ////               .font(.title)
   ////            Spacer()
   ////         }
   //         Text("hello world")
   //      }.background(Color .pink)
   //      .navigationTitle("Settings")
   //      .toolbar {
   //            Button("Done", action: {
   //               dismiss()
   //            })
   //         }
   //   }
}



#Preview {
   AboutView()
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
