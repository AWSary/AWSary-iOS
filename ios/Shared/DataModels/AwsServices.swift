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

class AwsServices: ObservableObject {
    @Published var services = [awsService]()
    
   
   func getRandomElement() -> awsService{
      return services.randomElement()!
   }
    init() {
       refresh()
    }
    
   func getData() {
           do {
               let documentDirectory = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
               subUrl = documentDirectory.appendingPathComponent("aws_services.json")
               loadFile(mainPath: mainUrl!, subPath: subUrl!)
           } catch {
               print(error)
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
           } catch {}
       }
   
    func refresh(){
       getData()
       services.sort {$0.name < $1.name}
    }
}
