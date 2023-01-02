//
//  AwsServices.swift
//  awsary
//
//  Created by Tiago Rodrigues on 02/01/2023.
//

import Foundation

class AwsServices: ObservableObject {
    @Published var services = [awsService]()
    
    init() {
        refresh()
    }
    
    func refresh(){
        //        Get json from bundle instead of internet for offline debug
        //        guard let url = Bundle.main.url(forResource: "services", withExtension: "json") else {
        //            print("JSON file not found")
        //            return
        //        }
        //        let data = try? Data(contentsOf: url)
        //                let awsServices = try? JSONDecoder().decode([awsService].self, from: data!)
        //                self.awsServices = awsServices!
        //        Get json from internet
        let url = URL(string: "https://static.tig.pt/awsary/services3.json")!
        URLSession.shared.dataTask(with: url) {(data, response, error) in
            do {
                if let awsServiceData = data {
                    let decodedData = try JSONDecoder().decode([awsService].self, from: awsServiceData)
                    DispatchQueue.main.async {
                        self.services = decodedData
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
