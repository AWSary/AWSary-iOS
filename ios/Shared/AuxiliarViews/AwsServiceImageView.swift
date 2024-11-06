//
//  AwsServiceImageView.swift
//  awsary
//
//  Created by Tiago Rodrigues on 02/01/2023.
//

import SwiftUI

struct AwsServiceImageView: View {
   let service: awsService
   let showLabel: Bool
   var body: some View{
       VStack{
          Image(service.imageURL.replacingOccurrences(of: "https://static.tig.pt/awsary/logos/", with: "").replacingOccurrences(of: ".svg", with: ""))
             .resizable()
             .scaledToFit()
             .frame(width: 100, height: 100)
             .cornerRadius(8.0)
          if showLabel {
             Text(service.name)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .font(.caption.bold())
                .foregroundColor(.white)
                .minimumScaleFactor(0.85)
                .padding(.bottom,2)
                .padding(.horizontal, 5)
                .padding(.top, -6)
                .frame(width: 100)
          }
       }
       .background(Color.black)
       .cornerRadius(8.0)
       .onDrag({
          print("Dragging name:\(service.name) id:\(service.id)")
          var dragImage: UIImage
          dragImage = self.asUIImage()
          let itemProvider = NSItemProvider(object: dragImage as UIImage)
          return itemProvider
       })
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
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.view.addSubview(controller.view)
        }
        
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

struct AwsServiceImageView_Previews: PreviewProvider {
   static var previews: some View {
      NavigationStack{
         HStack{
            AwsServiceImageView(service:
                                 awsService(
                                    id: 1,
                                    name: "Alexa for Business",
                                    longName: "Amazon Athena",
                                    shortDesctiption: "AWS Athena is a serverless service that allows you to make queries using ANSI SQL in data stored on Amazon S3. It supports a wide variety of data formats like CSV, TSV, JSON, or Textfiles. You pay for reading data and you can read compressed data like Zip or Gzip, so if you have 10GB CSV but it is only 20Mb Zipped, you can just upload a zipped version and query it while zipped, you will pay for 20Mb of reading instead of 10Gb or read. Nothing to maintain, and super-duper fast, querying multiple GB of data in seconds.",
                                    imageURL: "https://static.tig.pt/awsary/logos/Arch_Amazon-Athena_64.svg",
                                    youtube_id: "d_u1GKWm2f0"
                                 ),showLabel: false
            )
            AwsServiceImageView(service:
                                 awsService(
                                    id: 1,
                                    name: "Athena",
                                    longName: "Amazon Athena",
                                    shortDesctiption: "AWS Athena is a serverless service that allows you to make queries using ANSI SQL in data stored on Amazon S3. It supports a wide variety of data formats like CSV, TSV, JSON, or Textfiles. You pay for reading data and you can read compressed data like Zip or Gzip, so if you have 10GB CSV but it is only 20Mb Zipped, you can just upload a zipped version and query it while zipped, you will pay for 20Mb of reading instead of 10Gb or read. Nothing to maintain, and super-duper fast, querying multiple GB of data in seconds.",
                                    imageURL: "https://static.tig.pt/awsary/logos/Arch_Amazon-Athena_64.svg",
                                    youtube_id: "d_u1GKWm2f0"
                                 ),showLabel: true
            )
            AwsServiceImageView(service:
                                 awsService(
                                    id: 1,
                                    name: "Application Discovery Service",
                                    longName: "Application Discovery Service",
                                    shortDesctiption: "AWS Athena is a serverless service that allows you to make queries using ANSI SQL in data stored on Amazon S3. It supports a wide variety of data formats like CSV, TSV, JSON, or Textfiles. You pay for reading data and you can read compressed data like Zip or Gzip, so if you have 10GB CSV but it is only 20Mb Zipped, you can just upload a zipped version and query it while zipped, you will pay for 20Mb of reading instead of 10Gb or read. Nothing to maintain, and super-duper fast, querying multiple GB of data in seconds.",
                                    imageURL: "https://static.tig.pt/awsary/logos/Arch_Amazon-Athena_64.svg",
                                    youtube_id: "d_u1GKWm2f0"
                                 ),showLabel: true
            )
         }
      }
   }
}
