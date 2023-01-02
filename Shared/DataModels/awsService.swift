//
//  awsServices.swift
//  AWSary
//
//  Created by Tiago Rodrigues on 15/07/2022.
//

import Foundation

struct awsService: Codable, Identifiable, Hashable {
   public var id: Int
   public var name: String
   public var longName: String
   public var shortDesctiption: String
   public var imageURL: String
   public var youtube_id: String
}
