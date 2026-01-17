//
//  AwsServices.swift
//  awsary
//
//  Created by Tiago Rodrigues on 02/01/2023.
//

import Foundation
import SwiftUI

var fm = FileManager.default
var subUrl: URL?
var mainUrl: URL? = Bundle.main.url(forResource: "aws_services", withExtension: "json")
var lastRandom: awsService = awsService(id: 10, name: "DeepRacer", longName: "AWS DeepRacer", shortDesctiption: "DeepRacer", imageURL: "https://static.tig.pt/awsary/logos/Arch_AWS-DeepRacer_64.svg", youtube_id: "")

class AwsServices: ObservableObject {
    @Published var services = [awsService]()
    @Published var isLoading = true
    
    // Static cache to avoid reloading data multiple times
    private static var cachedServices: [awsService]?
   
   func getNameOfLastRandom() -> String {
      return lastRandom.longName
   }
   
   func getLastRandom() -> awsService {
      return lastRandom
   }
   
   func getRandomElement() -> awsService{
      lastRandom = services.randomElement()!
      return lastRandom
   }
    init() {
       // Check if we have cached data first
       if let cached = AwsServices.cachedServices {
           self.services = cached
           self.isLoading = false
       } else {
           // Load asynchronously
           Task {
               await refresh()
           }
       }
    }
    
   func getData() async {
           do {
               let documentDirectory = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
               subUrl = documentDirectory.appendingPathComponent("aws_services.json")
               await loadFile(mainPath: mainUrl!, subPath: subUrl!)
           } catch {
               print(error)
           }
       }
   
   func loadFile(mainPath: URL, subPath: URL) async {
           if fm.fileExists(atPath: subPath.path){
               await decodeData(pathName: subPath)
               
               if services.isEmpty{
                   await decodeData(pathName: mainPath)
               }
               
           }else{
               await decodeData(pathName: mainPath)
           }
       }
   
   func decodeData(pathName: URL) async {
           do{
               let jsonData = try Data(contentsOf: pathName)
               let decoder = JSONDecoder()
               let decodedServices = try decoder.decode([awsService].self, from: jsonData)
               
               await MainActor.run {
                   self.services = decodedServices
                   // Cache the services for future use
                   AwsServices.cachedServices = decodedServices
                   self.isLoading = false
               }
           } catch {
               await MainActor.run {
                   self.isLoading = false
               }
           }
       }
   
    func refresh() async {
       await getData()
       await MainActor.run {
           self.services.sort {$0.name < $1.name}
       }
    }
}
