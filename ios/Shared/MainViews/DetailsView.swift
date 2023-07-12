//
//  DetailsView.swift
//  awsary
//
//  Created by Tiago Rodrigues on 18/07/2022.
//

import SwiftUI
import MarkdownUI

struct DetailsView: View {
   @State private var favoriteColor = 0
   @State private var showingVideo = true
   var service:awsService
   
   var body: some View {
      ScrollView{
         VStack{
            HStack{
               AwsServiceImageView(service: service).frame(maxWidth: 100, maxHeight: 100)
               Text(service.longName).font(Font.title)
            }
            Spacer()
            Markdown(service.shortDesctiption).padding()
            Spacer()
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
               name: "Athena",
               longName: "Amazon Athena",
               shortDesctiption: "AWS Athena is a serverless service that allows you to make queries using ANSI SQL in data stored on Amazon S3. It supports a wide variety of data formats like CSV, TSV, JSON, or Textfiles. You pay for reading data and you can read compressed data like Zip or Gzip, so if you have 10GB CSV but it is only 20Mb Zipped, you can just upload a zipped version and query it while zipped, you will pay for 20Mb of reading instead of 10Gb or read. Nothing to maintain, and super-duper fast, querying multiple GB of data in seconds.",
               imageURL: "https://static.tig.pt/awsary/logos/Arch_Amazon-Athena_64@5x.png",
               youtube_id: "d_u1GKWm2f0"
            )
         )
      }
   }
}
