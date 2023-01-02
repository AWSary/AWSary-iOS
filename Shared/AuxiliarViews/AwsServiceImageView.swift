//
//  AwsServiceImageView.swift
//  awsary
//
//  Created by Tiago Rodrigues on 02/01/2023.
//

import SwiftUI
import CachedAsyncImage

struct AwsServiceImageView: View {
    let service: awsService
    var body: some View{
        CachedAsyncImage(url: URL(string: service.imageURL)) { phase in
            if let image = phase.image{
                image
                    .resizable()
                    .cornerRadius(8)
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 100, maxHeight: 100)
            } else if phase.error != nil {
                Image(systemName: "photo")
                    .font(.largeTitle)
            } else {
                ProgressView()
                    .frame(width: 100, height: 100, alignment: .center)
            }
        }.onDrag({
           print("Dragging name:\(service.name) id:\(service.id)")
           let cache = URLCache.shared
           //let request = URLRequest(url: URL(string: service.imageURL)!)
           var dragImage: UIImage
           let request = URLRequest(url: URL(string: service.imageURL)!, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 60.0)
           if let data = cache.cachedResponse(for: request)?.data {
              dragImage = UIImage(data:data)!
           } else {
              dragImage = UIImage(url: URL(string: service.imageURL))!
           }
           let itemProvider = NSItemProvider(object: dragImage as UIImage)
           return itemProvider
        })
    }
}


extension UIImage {
   convenience init?(url: URL?) {
      guard let url = url else { return nil }
      do {
         self.init(data: try Data(contentsOf: url))
      } catch {
         print("Cannot load image from url: \(url) with error: \(error)")
         return nil
      }
   }
}
