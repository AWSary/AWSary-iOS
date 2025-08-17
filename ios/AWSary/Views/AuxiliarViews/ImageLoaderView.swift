//
//  ImageLoaderView.swift
//  awsary (iOS)
//
//  Created by Tiago Rodrigues on 13/08/2025.
//

import SwiftUI
import SDWebImageSwiftUI

struct ImageLoaderView: View {
    
    var urlString: String = MyConstants.randomImage
    var resizingMode: ContentMode = .fit
    
    var body: some View {
        WebImage(url: URL(string: urlString))
            .resizable()
            .indicator(.activity)
            .aspectRatio(contentMode: resizingMode)
//            .frame(maxWidth: .infinity)
            .clipped()
//        Rectangle()
//            .opacity(0.001)
//            .overlay(
//                WebImage(url: URL(string: urlString))
//                    .resizable()
//                    .indicator(.activity)
//                    .aspectRatio(contentMode: resizingMode)
//                    .allowsHitTesting(false)
//            )
//            .clipped()
    }
}

#Preview {
    ImageLoaderView()
//        .cornerRadius(30)
//        .padding(40)
//        .padding(.vertical, 60)
}
