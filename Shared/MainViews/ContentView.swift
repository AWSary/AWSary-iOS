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
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10, content: {
                 ForEach(filteredAwsServices, id: \.self){ service in
// TODO enable details page
//                    NavigationLink(destination: DetailsView(service: service)){
                       VStack(alignment: .leading, spacing: 4, content: {
                          AwsServiceImageView(service: service)
                          Text("\(service.name)").font(.subheadline).lineLimit(2)
                          Spacer()
                       })
                 }
             }).padding(.horizontal, 12)
         }
//         List{
//            ForEach(filteredAwsServices, id:\.id){ item in
//               NavigationLink(
//                  destination:
//                     DetailsView(service: item)
//               ){
//                  HStack{
//                     LazyImage(source: URL(string: item.imageURL)) { state in
//                        if let image = state.image {
//                           image.cornerRadius(8)
//                        } else if state.error != nil {
//                           Text("Error Loading Image").font(.footnote).multilineTextAlignment(.center)
//                        } else {
//                           ProgressView()
//                        }
//                     }
//                     .frame(width: 64, height: 64)
//                     //.clipShape(RoundedRectangle(cornerRadius: 8))
//                     VStack(alignment: .leading){
//                        Text(item.name).font(.title2).lineLimit(2)
//                        Text(item.shortDesctiption).font(.footnote).lineLimit(2)
//                           .foregroundColor(Color.gray)
//                     }
//                  }
//                  .frame(height: 68)
//               }
//            }
//         }
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
