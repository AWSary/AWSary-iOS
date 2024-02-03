//
//  Game.swift
//  awsary
//
//  Created by Tiago Rodrigues on 03/02/2024.
//

import SwiftUI

struct Game: View {
   @ObservedObject var awsServices = AwsServices()
   @State private var showServiceName = false
   
   var body: some View {
      var lastRandomService: awsService = awsServices.getLastRandom()
      VStack{
         Spacer()
         Text("Name the AWS service")
            .font(.title).bold()
         AWSserviceImagePlaceHolderView(service: lastRandomService, showLabel: false)
            .frame(minHeight: 140)
         if (showServiceName){
            Text(awsServices.getNameOfLastRandom()).font(.title)
               .multilineTextAlignment(.center)
         } else {
            Text(" ").font(.title)
         }
         Spacer()
         if(showServiceName){
            Button(action: {
               if (showServiceName){
                  lastRandomService = awsServices.getRandomElement()
                  showServiceName = false
               }
            }, label: {
               Text("Generate a new Random Service")
            })
         }else {
            Button(action: {showServiceName = true}, label: {
               Text("Reveal")
            })
         }
         Spacer()
      }
   }
}

#Preview {
    Game()
}
