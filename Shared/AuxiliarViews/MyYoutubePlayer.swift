//
//  MyYoutubePlayer.swift
//  awsary
//
//  Created by Tiago Rodrigues on 02/01/2023.
//

import SwiftUI
import YouTubePlayerKit

struct MyYoutubePlayer: View {
   let youtube_id: String
   
   var body: some View {
      YouTubePlayerView(YouTubePlayer(stringLiteral: "https://www.youtube.com/watch?v=\(self.youtube_id)")) { state in
         switch state {
         case .idle:
            ProgressView()
         case .ready:
            EmptyView()
         case .error(_):
            Text(verbatim: "YouTube player couldn't be loaded")
         }
      }.frame(height: 220)
   }
}
