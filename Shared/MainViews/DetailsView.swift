//
//  DetailsView.swift
//  awsary
//
//  Created by Tiago Rodrigues on 18/07/2022.
//

import SwiftUI

struct DetailsView: View {
   @State private var favoriteColor = 0
   @State private var showingVideo = true
   var service:awsService
   
   var body: some View {
      ScrollView{
         VStack{
         Text(service.longName).font(Font.title)
         HStack(alignment: .top){
            AwsServiceImageView(service: service)
            .frame(width: 64, height: 64)
            Text(service.shortDesctiption)
         }
         .padding(.leading)
         .padding(.trailing)
         HStack{
//            VStack(alignment: .leading){
//               Text("Tags".uppercased()).font(Font.footnote)
//               HStack{
//                  Text("Compute".uppercased()).padding(.leading,4).padding(.trailing,4).padding(3).background(Color .orange).cornerRadius(15).fixedSize().minimumScaleFactor(0.01)
//                  Text("managed".uppercased()).padding(.leading,4).padding(.trailing,4).padding(3).background(Color .green).cornerRadius(15).fixedSize().minimumScaleFactor(0.01)
//               }
//            }.padding(.leading)
            Spacer()
            if service.youtube_id != "" {
               HStack{
                  Text("\(showingVideo ? "Hide":"Show") ").fixedSize().font(Font.system(.body, design: .monospaced)).padding(.trailing, -10)
                  Image(systemName: "play.rectangle.fill").font(.title2).foregroundColor(Color .red)
               }.padding(.trailing)
               .onTapGesture {
                  showingVideo.toggle()
                  
               }
            }
         }.padding(.top, 3)
         if showingVideo && service.youtube_id != "" {
            MyYoutubePlayer(youtube_id: service.youtube_id)
         }
         
         
         // https://www.hackingwithswift.com/quick-start/swiftui/how-to-create-a-segmented-control-and-read-values-from-it
//         Picker("What is your favorite color?", selection: $favoriteColor) {
//            Text("Overview".uppercased()).tag(0)
//            Text("Best-practice".uppercased()).tag(1)
//            Text("Pricing".uppercased()).tag(2)
//         }
//         .pickerStyle(.segmented)
//         List{
//            ForEach((1...100), id: \.self) {
//               Text("\($0) sample item")
//            }
//         }
         Spacer()
      }
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
               shortDesctiption: "Run your code without thinking abouSA  FDAS F AS F AS F DASF AS D F ASF AS F S AF AS F AS F AS F DAS F SAf sad f asf da f dsf as d fa sfdt servers with this event driven service that will wow you",
               imageURL: "https://static.tig.pt/awsary/logos/Arch_AWS-Lambda_64.png",
               youtube_id: "d_u1GKWm2f0"
            )
         )
      }
   }
}
