//
//  awsaryApp.swift
//  Shared
//
//  Created by Tiago Rodrigues on 15/07/2022.
//

// TODO - Make at least 50Mb of cache to fit all images, more for some spare room.
// https://smashswift.com/how-to-change-urlsession-cache-size/


import SwiftUI

@main
struct awsaryApp: App {
   
   init(){
      let cache = URLCache(
         memoryCapacity: 50 * 1024 * 1024,
         diskCapacity: 100 * 1024 * 1024, directory: nil)
      URLCache.shared = cache
   }
   
   var body: some Scene {
      WindowGroup {
         ContentView()
      }
   }
}
