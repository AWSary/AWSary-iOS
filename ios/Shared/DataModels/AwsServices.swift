//
//  AwsServices.swift
//  awsary
//
//  Created by Tiago Rodrigues on 02/01/2023.
//

import Foundation

var fm = FileManager.default
var mainUrl: URL? = Bundle.main.url(forResource: "aws_services", withExtension: "json")
var lastRandom: awsService = awsService(id: 10, name: "DeepRacer", longName: "AWS DeepRacer", shortDesctiption: "DeepRacer", imageURL: "https://static.tig.pt/awsary/logos/Arch_AWS-DeepRacer_64.svg", youtube_id: "")

class AwsServices: ObservableObject {
    @Published var services = [awsService]()
   
   func getNameOfLastRandom() -> String {
      return lastRandom.longName
   }
   
   func getLastRandom() -> awsService {
      return lastRandom
   }
   
   func getRandomElement() -> awsService {
      if services.isEmpty {
         refresh()
      }

      guard let randomService = services.randomElement() else {
         return lastRandom
      }

      lastRandom = randomService
      return randomService
   }

   init() {
      refresh()
   }

   private func servicesFromDocuments() -> [awsService] {
      do {
         let documentDirectory = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
         let documentURL = documentDirectory.appendingPathComponent("aws_services.json")

         guard fm.fileExists(atPath: documentURL.path) else {
            return []
         }

         return decodeData(pathName: documentURL)
      } catch {
         print("Failed to resolve documents directory for aws_services.json: \(error)")
         return []
      }
   }

   private func servicesFromBundle() -> [awsService] {
      guard let bundleURL = mainUrl else {
         print("Missing bundled aws_services.json")
         return []
      }

      return decodeData(pathName: bundleURL)
   }

   private func decodeData(pathName: URL) -> [awsService] {
      do {
         let jsonData = try Data(contentsOf: pathName)
         let decoder = JSONDecoder()
         let decoded = try decoder.decode([awsService].self, from: jsonData)

         if decoded.isEmpty {
            print("Decoded zero services from \(pathName.lastPathComponent)")
         }

         return decoded
      } catch {
         print("Failed to decode aws_services.json from \(pathName): \(error)")
         return []
      }
   }

   func refresh() {
      var loadedServices = servicesFromDocuments()

      if loadedServices.isEmpty {
         loadedServices = servicesFromBundle()
      }

      if loadedServices.isEmpty {
         print("Falling back to last known service to prevent empty catalogue")
         services = [lastRandom]
      } else {
         loadedServices.sort { $0.name < $1.name }
         services = loadedServices
      }
   }
}
