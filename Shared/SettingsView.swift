//
//  SettingsView.swift
//  awsary
//
//  Created by Tiago Rodrigues on 20/07/2022.
//

import SwiftUI

struct SettingsView: View {
   @Environment(\.dismiss) var dismiss
   
   var body: some View {
      NavigationView{
         List{
//            Section(header: Text("AWSary.com")){
//               Text("This is a hobby project from Tiago Rodrigues to help more people learn about Cloud, specialy AWS. Special tanks to tecRacer for supporting the backend.").lineLimit(100)
//            }
            Section(header: Text("Help developing this app")){
               Text("Get involved in this application")
            }
            Section(header: Text("Contact & Help")){
               Text("FAQ - Frequently Asked Questions")
            }
            Section(header: Text("info")){
               Text("Acknowledgements")
               Text("Colophon")
               Text("Privacy Policy")
            }
            Section(header: Text("Icon")){
               Text("Icon 1")
               Text("Icon 2")
               Text("Icon 3")
            }
         }
         .navigationTitle("Settings")
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

struct SettingsView_Previews: PreviewProvider {
   static var previews: some View {
      SettingsView()
   }
}
