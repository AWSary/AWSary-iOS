//
//  ContentView.swift
//  Shared
//
//  Created by Tiago Rodrigues on 15/07/2022.
//

import SwiftUI

struct ContentView: View {
   @State private var showingSheet = false
   @ObservedObject var awsServices = AwsServices()
   @State private var searchQuery = ""
   @Environment(\.colorScheme) var colorScheme
   
   var filteredAwsServices: [awsService] {
      if searchQuery.isEmpty {
         return awsServices.services
      } else {
         return awsServices.services.filter { $0.name.lowercased().contains(searchQuery.lowercased()) }
      }
   }
   
   var body: some View {
      NavigationView{
         ScrollView{
            LazyVGrid(
               columns: [GridItem(.adaptive(minimum: 100))], content: {
                 ForEach(filteredAwsServices, id: \.self){ service in
                    NavigationLink(destination: DetailsView(service: service)){
                       VStack(alignment: .center, spacing: 4, content: {
                          AWSserviceImagePlaceHolderView(service: service, showLabel: true)
                             .frame(minHeight: 140)
                          Text(service.name)
                             .font(.subheadline)
                             .lineLimit(3)
                          Spacer()
                       })
                    }
                 }
             }).padding(.horizontal, 12)
               .accentColor(Color(colorScheme == .dark ? .white : .black))
         }
         .refreshable {
            AwsServices().refresh()
         }
         .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search for an AWS Service")
         .disableAutocorrection(true) // .autocorrectionDisabled() //only available on iOS 16
         .navigationTitle("AWSary")
         .toolbar {
            Button(action: {
               showingSheet.toggle()
            }) {
               Image(systemName: "gear")
            }
         }
      }.sheet(isPresented: $showingSheet) {
         AboutView()
      }.navigationViewStyle(.stack)
   }
   
   struct ContentView_Previews: PreviewProvider {
      static var previews: some View {
         ContentView()
      }
   }
}
