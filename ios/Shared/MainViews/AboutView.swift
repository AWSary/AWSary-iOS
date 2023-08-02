//
//  SettingsView.swift
//  awsary
//
//  Created by Tiago Rodrigues on 20/07/2022.
//

import SwiftUI
import AppReview
import StoreKit
import RevenueCat

struct AboutView: View {
   @Environment(\.dismiss) var dismiss
   
   var body: some View {
      NavigationView{
         List{
//            Section(){
//               Toggle(isOn: .constant(false), label: {
//                  Label("Label services on Drag", systemImage: "tag")
//               })
//               Label("App Icon", systemImage: "square")
//            }
            Section(header: Text("AWSary Premium")){
               NavigationLink(destination: PaywallView(isPresented: .constant(true))){
                  Label("Purchase Subscription", systemImage: "creditcard")
               }
               Label("Restore Purchase", systemImage: "arrow.triangle.2.circlepath").onTapGesture {
                  Purchases.shared.restorePurchases { customerInfo, error in
                      //... check customerInfo to see if entitlement is now active
                  }
               }
            }
            Section(header: Text("Feedback")){
//              Label("Send Feedback", systemImage: "envelope")
               Label("Rate this version of AWSary", systemImage: "star.fill").onTapGesture {
                  SKStoreReviewController.requestReview()
               }
              
            }
            Section(header: Text("Why AWSary")){
               Text("I'm an AWS Cloud Consultant and Trainer.\n\nNew AWS Services are released all the time, and sometimes you junt want a quick dictionary definition.\n\nI also draw AWS Cloud Architecture diagrams daily on iPad, to explore ideas either with Colleagues, Clients or Students.\n\nGood drawing Applications don't have AWS services logos, so on top of this dictionary I enabled the drag and drop of the logos to 3rd party drawing tools.\n\n This App is a great AWS Cloud Consultant companion tool.\n\nHelp develop this app at [GitHub](https://github.com/tigpt/AWSary/).")
            }
            Section(header: Text("How to use AWSary")){
               Text("Search for the name of an AWS service, you can open and look for the definition of it. You can also drag and drop the service logo to your favorite drawing application. (Check video below)")
               MyYoutubePlayer(youtube_id: "Jvq6nEtm9LY")
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
      }
   }
   //   var body: some View {
   //      NavigationView{
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

struct AboutView_Previews: PreviewProvider {
   static var previews: some View {
      AboutView()
   }
}
