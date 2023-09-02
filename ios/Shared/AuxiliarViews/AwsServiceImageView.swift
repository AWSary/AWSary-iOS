//
//  AwsServiceImageView.swift
//  awsary
//
//  Created by Tiago Rodrigues on 02/01/2023.
//

import SwiftUI
import SDWebImageSwiftUI

struct AwsServiceImageView: View {
    let service: awsService
    var body: some View{
       Image(service.imageURL.replacingOccurrences(of: "https://static.tig.pt/awsary/logos/", with: "").replacingOccurrences(of: ".png", with: ""))
                   .resizable()
                   .scaledToFit()
                   .overlay(ImageOverlay(serviceName: service.name),alignment: .bottom)
                   .onDrag({
                      print("Dragging name:\(service.name) id:\(service.id)")
                      var dragImage: UIImage
                      dragImage = self.asUIImage()
                      let itemProvider = NSItemProvider(object: dragImage as UIImage)
                      return itemProvider
                   })
                   .frame(width: 100, height: 100, alignment: .center)
                   .cornerRadius(8)
    }
}

struct ImageOverlay: View {
   let serviceName: String?
   
    var body: some View {
        ZStack {
            Text(serviceName!)
              .font(.caption2)
              .padding(.vertical, 2)
              .padding(.horizontal, 5)
                .foregroundColor(.white)
                .minimumScaleFactor(0.01)
                .lineLimit(2)
        }.background(Color.black)
        .cornerRadius(8.0)
        .padding(3)
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

extension View {
// This function changes our View to UIView, then calls another function
// to convert the newly-made UIView to a UIImage.
    public func asUIImage() -> UIImage {
        let controller = UIHostingController(rootView: self)
        
 // Set the background to be transparent incase the image is a PNG, WebP or (Static) GIF
        controller.view.backgroundColor = .clear
        
        controller.view.frame = CGRect(x: 0, y: CGFloat(Int.max), width: 1, height: 1)
        UIApplication.shared.windows.first!.rootViewController?.view.addSubview(controller.view)
        
        let size = controller.sizeThatFits(in: UIScreen.main.bounds.size)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.sizeToFit()
        
// here is the call to the function that converts UIView to UIImage: `.asUIImage()`
        let image = controller.view.asUIImage()
        controller.view.removeFromSuperview()
        return image
    }
}

extension UIView {
// This is the function to convert UIView to UIImage
    public func asUIImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
