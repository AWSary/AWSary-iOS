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
    @State private var navigationPath: [awsService] = []
    @Binding private var requestedServiceID: Int?
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Query var settings: [SystemSetting]

    init(requestedServiceID: Binding<Int?> = .constant(nil)) {
       _requestedServiceID = requestedServiceID
    }
    
    // Computed property for awsServiceLogoWithLabel setting
    private var awsServiceLogoWithLabel: Bool {
       return settings.first(where: { $0.key == "awsServiceLogoWithLabel" })?.boolValue ?? true
    }
    
    var filteredAwsServices: [awsService] {
       let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
       if query.isEmpty {
          return awsServices.services
       } else {
          return awsServices.services
             .compactMap { service in
                service.awsarySearchRank(for: query).map { (service, $0) }
             }
             .sorted {
                if $0.1 == $1.1 {
                   return $0.0.name.localizedCaseInsensitiveCompare($1.0.name) == .orderedAscending
                }
                return $0.1 < $1.1
             }
             .map(\.0)
       }
    }
    
    var body: some View {
               NavigationStack(path: $navigationPath){
                   ScrollView{
                    LazyVGrid(
                       columns: [GridItem(.adaptive(minimum: 100))], content: {
                          ForEach(filteredAwsServices, id: \.self){ service in
                             NavigationLink(value: service){
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
                 .navigationDestination(for: awsService.self) { service in
                    DetailsView(service: service)
                 }
                 .refreshable {
                    AwsServices().refresh()
                 }
                 .onChange(of: requestedServiceID) {
                    openRequestedServiceIfPossible()
                 }
                 .onChange(of: awsServices.services.count) {
                    openRequestedServiceIfPossible()
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

   private func openRequestedServiceIfPossible() {
      guard let requestedServiceID else { return }
      guard let service = awsServices.services.first(where: { $0.id == requestedServiceID }) else {
         return
      }

      navigationPath = [service]
      self.requestedServiceID = nil
   }
    }

#Preview {
    Glossary()
}
