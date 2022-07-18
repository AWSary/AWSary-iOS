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
    
    var body: some View {
        NavigationView{
            List{
                ForEach(fetch.awsServices, id:\.id){ item in
                    NavigationLink(
                        destination:
                            DetailsView(service: item)
                    ){
                        HStack{
                            AsyncImage(url: URL(string: "https://static.tig.pt/awsary/logos/\(item.imageURL)"))
                            { image in
                               image.resizable()
                           } placeholder: {
                               ProgressView()
                           }
                           .frame(width: 70, height: 70)
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
            .searchable(text: $searchQuery, prompt: "(Not working yet) Search for a Service or a Feature")  // TODO Searchable
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
