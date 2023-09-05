//
//  AWSserviceImagePlaceHolderView.swift
//  awsary (iOS)
//
//  Created by Tiago Rodrigues on 04/09/2023.
//

import SwiftUI

struct AWSserviceImagePlaceHolderView: View {
   let service: awsService
   let showLabel: Bool
   var body: some View{
      AwsServiceImageView(service: service, showLabel: showLabel)
         .padding(2)
         .background(Color.white)
         .cornerRadius(8.0)
         .frame(width: 100)
   }
}
