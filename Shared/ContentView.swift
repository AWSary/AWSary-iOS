//
//  ContentView.swift
//  Shared
//
//  Created by Tiago Rodrigues on 15/07/2022.
//

import SwiftUI
import NukeUI

struct ContentView: View {
   @State private var showingSheet = false
   @ObservedObject var fetch = FetchAwsService()
   @State private var searchQuery = ""
   
   var filteredAwsServices: [awsService] {
      if searchQuery.isEmpty {
         return fetch.awsServices
      } else {
         return fetch.awsServices.filter { $0.name.lowercased().contains(searchQuery.lowercased()) }
      }
   }
   
   var body: some View {
      NavigationView{
         List{
            ForEach(filteredAwsServices, id:\.id){ item in
               NavigationLink(
                  destination:
                     DetailsView(service: item)
               ){
                  HStack{
                     LazyImage(source: URL(string: item.imageURL)) { state in
                        if let image = state.image {
                           image.cornerRadius(8)
                        } else if state.error != nil {
                           Text("Error Loading Image").font(.footnote).multilineTextAlignment(.center)
                        } else {
                           ProgressView()
                        }
                     }
                     .frame(width: 64, height: 64)
                     //.clipShape(RoundedRectangle(cornerRadius: 8))
                     VStack(alignment: .leading){
                        Text(item.name).font(.title2).lineLimit(2)
                        Text(item.shortDesctiption).font(.footnote).lineLimit(2)
                           .foregroundColor(Color.gray)
                     }
                  }
                  .frame(height: 68)
               }
            }
         }
         .refreshable {
            fetch.refresh()
         }
         .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search for a Service or a Feature")
         .disableAutocorrection(true)
         //            .autocorrectionDisabled() //only available on iOS 16
         .navigationTitle("AWS Dictionary")
         .toolbar {
            Button(action: {
               showingSheet.toggle()
            }) {
               Image(systemName: "gear")
            }
         }
      }.sheet(isPresented: $showingSheet) {
         SettingsView()
      }
   }
   
   struct ContentView_Previews: PreviewProvider {
      static var previews: some View {
         ContentView()
      }
   }
}
