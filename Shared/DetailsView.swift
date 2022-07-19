//
//  DetailsView.swift
//  awsary
//
//  Created by Tiago Rodrigues on 18/07/2022.
//

import SwiftUI


struct DetailsView: View {
   @State private var favoriteColor = 0
   var service:awsService
   
   var body: some View {
      VStack{
         Text("Elastic Compute Cloud").font(Font.title)
         HStack{
            AsyncImage(url: URL(string: service.imageURL))
            { image in
               image.resizable()
            } placeholder: {
               ProgressView()
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            Text(service.shortDesctiption)
         }.padding()
         Section() {
            Text("Tags".uppercased()).font(Font.footnote)
            Text("Compute, managed, eventDriven".uppercased())
         }
         // https://www.hackingwithswift.com/quick-start/swiftui/how-to-create-a-segmented-control-and-read-values-from-it
         Picker("What is your favorite color?", selection: $favoriteColor) {
            Text("Docs".uppercased()).tag(0)
            Text("Tutorials".uppercased()).tag(1)
            Text("Pricing".uppercased()).tag(2)
         }
         .pickerStyle(.segmented)
         List{
            ForEach((1...100), id: \.self) {
               Text("\($0) sample item")
            }
         }
         Spacer()
      }
      .navigationTitle(service.name)
      .navigationBarTitleDisplayMode(.inline)
   }
}

struct DetailsView_Previews: PreviewProvider {
   static var previews: some View {
      NavigationView{
         DetailsView(service:
                        awsService(
                           id: 1,
                           name: "EC2",
                           shortDesctiption: "Run your code without thinking about servers with this event driven service that will wow you",
                           imageURL: "Arch_AWS-Lambda_64.png"
                        )
         )
      }
   }
}
