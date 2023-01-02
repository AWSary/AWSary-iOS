//
//  SettingsView.swift
//  awsary
//
//  Created by Tiago Rodrigues on 20/07/2022.
//

import SwiftUI

struct AboutView: View {
   @Environment(\.dismiss) var dismiss
   
   var body: some View {
      NavigationView{
         List{
            Section(header: Text("Why AWSary")){
               Text("I'm a AWS Cloud Consultant and Trainer.\n\nI draw AWS Cloud diagrams daily on iPad, to explore ideas either with Clients or Students.\n\nGood drawing Applicaitons don't have AWS services logos, so I created this application aiming to be the best AWS Cloud Consultant companion tool.")
            }
            Section(header: Text("How to use AWSary")){
               Text("Search for a AWS service logo, drag and drop it to your favorite drawing applicaiton.")
// TODO - make a youtube video on how to use the app and configure it here.
//               MyYoutubePlayer(youtube_id: "d_u1GKWm2f0")
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
         .navigationTitle("About AWSary")
         .toolbar {
            ToolbarItem(placement: .confirmationAction){
               Button("Done", action: {dismiss()})
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
