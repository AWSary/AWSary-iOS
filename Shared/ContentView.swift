//
//  ContentView.swift
//  Shared
//
//  Created by Tiago Rodrigues on 15/07/2022.
//

import SwiftUI

struct ContentView: View {
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
                            AsyncImage(url: URL(string: item.imageURL))
                            { image in
                               image.resizable()
                           } placeholder: {
                               ProgressView()
                           }
                           .frame(width: 64, height: 64)
                           .clipShape(RoundedRectangle(cornerRadius: 8))
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
                //TODO refresh contet
            }
            .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search for a Service or a Feature")
            .disableAutocorrection(true)
//            .autocorrectionDisabled() //only available on iOS 16
            .navigationTitle("AWS Dictionary")
            .toolbar {
                Button(action: {}) {
                    Image(systemName: "gear")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
