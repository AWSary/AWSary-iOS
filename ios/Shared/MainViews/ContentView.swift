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
   @AppStorage("awsServiceLogoWithLabel") var awsServiceLogoWithLabel: Bool = true
   
   var filteredAwsServices: [awsService] {
      if searchQuery.isEmpty {
         return awsServices.services
      } else {
         return awsServices.services.filter { $0.name.lowercased().contains(searchQuery.lowercased()) }
      }
   }
   
   var body: some View {
      TabView {
         NavigationStack{
            ScrollView{
               HStack{
                  Image("bunny-ses")
                     .resizable()
                     .scaledToFit()
                     .frame(width: 100, height: 100)
                  VStack{
                     Text("Celebrate Bunny SES launch")
                     Text("10% Discount Code: GSC293ZEQD").font(.footnote)
                     Text("\nUntil 31st of June 2024").font(.footnote)
                  }
               }.padding(6)
                  .background(Color(light: .white, dark: .black))
                  .cornerRadius(8.0)
                  .padding(.horizontal, 3)
                  .padding(.vertical, 3)
                  .background(Color(red:1.0, green: 0.5, blue: 0.0))
                  .cornerRadius(8.0)
                  .background(.pink)
                  .cornerRadius(8.0)
                  .onTapGesture {
                     guard let url = URL(string: "https://bit.ly/awsary-merch") else {
                        return
                     }
                     UIApplication.shared.open(url, options: [:], completionHandler: nil)
                  }
               LazyVGrid(
                  columns: [GridItem(.adaptive(minimum: 100))], content: {
                     ForEach(filteredAwsServices, id: \.self){ service in
                        NavigationLink(destination: DetailsView(service: service)){
                           VStack(alignment: .center, spacing: 4, content: {
                              AWSserviceImagePlaceHolderView(service: service, showLabel: awsServiceLogoWithLabel)
                                 .frame(minHeight: 140)
                              if (!awsServiceLogoWithLabel){
                                 Text(service.name)
                                    .font(.subheadline)
                                    .lineLimit(3)
                              }
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
         }
         .tabItem {
            Label("Dictionary", systemImage: "books.vertical")
         }
         Game()
            .tabItem {
               Label("Game", systemImage: "gamecontroller")
            }
      }
   }
}

#Preview{
   ContentView()
}
