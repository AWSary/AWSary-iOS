//
//  DetailsView.swift
//  awsary
//
//  Created by Tiago Rodrigues on 18/07/2022.
//

import SwiftUI
import NukeUI
import YouTubePlayerKit

struct DetailsView: View {
   @State private var favoriteColor = 0
   @State private var showingVideo = true
   var service:awsService
   let youTubePlayer: YouTubePlayer = "https://www.youtube.com/watch?v=9me296xhHYw"
   
   var body: some View {
      VStack{
         Text(service.longName).font(Font.title)
         HStack{
            LazyImage(source: URL(string: service.imageURL)) { state in
               if let image = state.image {
                  image
               } else if state.error != nil {
                  Text("Error Loading Image").font(.footnote).multilineTextAlignment(.center)
               } else {
                  ProgressView()
               }
            }
            .frame(width: 64, height: 64)
//            .clipShape(RoundedRectangle(cornerRadius: 8))
            Text(service.shortDesctiption)
         }.padding(.leading, 3)
         HStack{
//            VStack(alignment: .leading){
//               Text("Tags".uppercased()).font(Font.footnote)
//               HStack{
//                  Text("Compute".uppercased()).padding(.leading,4).padding(.trailing,4).padding(3).background(Color .orange).cornerRadius(15).fixedSize().minimumScaleFactor(0.01)
//                  Text("managed".uppercased()).padding(.leading,4).padding(.trailing,4).padding(3).background(Color .green).cornerRadius(15).fixedSize().minimumScaleFactor(0.01)
//               }
//            }.padding(.leading)
            Spacer()
            VStack{
               Image(systemName: "play.rectangle.fill").font(.title2).foregroundColor(Color .red)
               Text("\(showingVideo ? "Hide":"Show") Video").fixedSize().font(Font.system(.body, design: .monospaced)).padding(.top, 1)
            }.padding(.trailing)
            .onTapGesture {
               showingVideo.toggle()
               
            }
         }.padding(.top)
         if showingVideo {
            YouTubePlayerView(self.youTubePlayer) { state in
                        switch state {
                        case .idle:
                           HStack{
                              Text("Video is loading  ")
                              ProgressView()
                           }
                        case .ready:
                            EmptyView()
                        case .error(let error):
                            Text(verbatim: "YouTube player couldn't be loaded")
                        }
                    }
//            YouTubePlayerView("https://www.youtube.com/watch?v=9me296xhHYw")
         }
         
         
         // https://www.hackingwithswift.com/quick-start/swiftui/how-to-create-a-segmented-control-and-read-values-from-it
         Picker("What is your favorite color?", selection: $favoriteColor) {
            Text("Overview".uppercased()).tag(0)
            Text("Best-practice".uppercased()).tag(1)
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
                           longName: "Elastic Compute Cloud",
                           shortDesctiption: "Run your code without thinking about servers with this event driven service that will wow you",
                           imageURL: "https://static.tig.pt/awsary/logos/Arch_AWS-Lambda_64.png"
                        )
         )
      }
   }
}
