//
//  AwsServices.swift
//  awsary
//
//  Created by Tiago Rodrigues on 02/01/2023.
//

import Foundation

var fm = FileManager.default
var subUrl: URL?
var mainUrl: URL? = Bundle.main.url(forResource: "aws_services", withExtension: "json")
var lastRandom: awsService = awsService(id: 10, name: "DeepRacer", longName: "AWS DeepRacer", shortDescription: "DeepRacer", imageURL: "https://static.tig.pt/awsary/logos/Arch_AWS-DeepRacer_64.svg", youtube_id: "")

class AwsServices: ObservableObject {
    @Published var services = [awsService]()
   
   func getNameOfLastRandom() -> String {
      return lastRandom.longName
   }
   
   func getLastRandom() -> awsService {
      return lastRandom
   }
   
   func getRandomElement() -> awsService{
      if let randomService = services.randomElement() {
         lastRandom = randomService
         return lastRandom
      }
      return lastRandom // Return the default if no services available
   }
    init() {
       refresh()
    }
    
   func getData() {
           do {
               let documentDirectory = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
               subUrl = documentDirectory.appendingPathComponent("aws_services.json")
               guard let mainPath = mainUrl, let subPath = subUrl else {
                   print("Error: Unable to create file paths")
                   return
               }
               loadFile(mainPath: mainPath, subPath: subPath)
           } catch {
               print("Error getting document directory: \(error)")
           }
       }
   
   func loadFile(mainPath: URL, subPath: URL){
           if fm.fileExists(atPath: subPath.path){
               decodeData(pathName: subPath)
               
               if services.isEmpty{
                   decodeData(pathName: mainPath)
               }
               
           }else{
               decodeData(pathName: mainPath)
           }
       }
   
   func decodeData(pathName: URL){
           do{
               let jsonData = try Data(contentsOf: pathName)
               let decoder = JSONDecoder()
              services = try decoder.decode([awsService].self, from: jsonData)
           } catch {
               print("Error decoding JSON data: \(error)")
           }
       }
   
    func refresh(){
       getData()
       services.sort {$0.name < $1.name}
    }
}
