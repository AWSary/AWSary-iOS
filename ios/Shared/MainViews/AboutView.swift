//
//  SettingsView.swift
//  awsary
//
//  Created by Tiago Rodrigues on 20/07/2022.
//

import SwiftUI
import StoreKit
import RevenueCat

struct AboutView: View {
   @Environment(\.dismiss) var dismiss
   @ObservedObject var userModel = UserViewModel.shared
   @ObservedObject var awsServices = AwsServices()
   @AppStorage("awsServiceLogoWithLabel") var awsServiceLogoWithLabel: Bool = true
   
   var body: some View {
      let randomAWSservice = awsServices.getRandomElement()
      
      NavigationStack{
         List{
            Section(header: Text("Configure service logos")){
               VStack{
                  Toggle(isOn: $awsServiceLogoWithLabel){
                     Text("Show name on service logo")
                  }
//                  .disabled(!self.userModel.subscriptionActive)
//                  Text("")
//                  Text("Drag-and-drop each of the icons bellow, to test it on your diagrams.\n\nTap to load a diferent random icon, purchange a subscription to enable on all logos.")
                  LazyVGrid(
                     columns: [GridItem(.adaptive(minimum: 110))], content: {
                        
                        if (awsServiceLogoWithLabel){
                           AWSserviceImagePlaceHolderView(service: randomAWSservice, showLabel: false)
                           AWSserviceImagePlaceHolderView(service: randomAWSservice, showLabel: true)
                              .padding(.horizontal, 8)
                              .padding(.vertical, 6)
                              .background(Color(red:1.0, green: 0.5, blue: 0.0))
                              .cornerRadius(8.0)
                        }else{
                           AWSserviceImagePlaceHolderView(service: randomAWSservice, showLabel: false)
                              .padding(.horizontal, 8)
                              .padding(.vertical, 6)
                              .background(Color(red:1.0, green: 0.5, blue: 0.0))
                              .cornerRadius(8.0)
                           AWSserviceImagePlaceHolderView(service: randomAWSservice, showLabel: true)
                        }
                     }
                  ).frame(minHeight: 160)
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
                  Label("Discount Code: ", systemImage: "doc.on.doc").onTapGesture {
                     UIPasteboard.general.string = ""
                  }
                  NavigationLink(destination: PaywallView(isPresented: .constant(true))){
                     Label("Manage Subscription", systemImage: "heart.fill")
                  }
               } else {
                  NavigationLink(destination: PaywallView(isPresented: .constant(true))){
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
                     Text("Be like the 19 other beautiful people that have rated this version.").font(.footnote).opacity(0.6)
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
                  let body = "\n\n--\nAWSary Version: \(Bundle.main.appVersionLong) (\(Bundle.main.appBuild))"

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
