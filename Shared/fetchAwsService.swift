//
//  fetchAWSservices.swift
//  AWSary
//
//  Created by Tiago Rodrigues on 15/07/2022.
//

import Foundation

class FetchAwsService: ObservableObject {
   @Published var awsServices = [awsService]()
   
   init() {
      //        Get json from bundle instead of internet for offline debug
      //        guard let url = Bundle.main.url(forResource: "services", withExtension: "json") else {
      //            print("JSON file not found")
      //            return
      //        }
      //        let data = try? Data(contentsOf: url)
      //                let awsServices = try? JSONDecoder().decode([awsService].self, from: data!)
      //                self.awsServices = awsServices!
      //        Get json from internet
      let url = URL(string: "https://static.tig.pt/awsary/services2.json")!
      URLSession.shared.dataTask(with: url) {(data, response, error) in
         do {
            if let awsServiceData = data {
               let decodedData = try JSONDecoder().decode([awsService].self, from: awsServiceData)
               DispatchQueue.main.async {
                  self.awsServices = decodedData
               }
            } else {
               print("No data")
            }
         } catch {
            print("Error")
         }
      }.resume()
   }
}
