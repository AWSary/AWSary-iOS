//
//  Glossary.swift
//  awsary (iOS)
//
//  Created by Tiago Rodrigues on 10/11/2024.
//

import SwiftUI
import SwiftData

struct Glossary: View {
    @State private var showingSheet = false
    @ObservedObject var awsServices = AwsServices()
    @State private var searchQuery = ""
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Query var settings: [SystemSetting]
    
    // Computed property for awsServiceLogoWithLabel setting
    private var awsServiceLogoWithLabel: Bool {
       return settings.first(where: { $0.key == "awsServiceLogoWithLabel" })?.boolValue ?? true
    }
    
    var filteredAwsServices: [awsService] {
       if searchQuery.isEmpty {
          return awsServices.services
       } else {
          return awsServices.services.filter { $0.name.lowercased().contains(searchQuery.lowercased()) }
       }
    }
    
    var body: some View {
               NavigationStack{
                   ScrollView{
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
       }
    }

#Preview {
    Glossary()
}
