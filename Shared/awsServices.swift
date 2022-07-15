//
//  awsServices.swift
//  AWSary
//
//  Created by Tiago Rodrigues on 15/07/2022.
//

import Foundation

struct awsService: Codable, Identifiable {
    public var id: Int
    public var name: String
    public var shortDesctiption: String
    public var imageURL: String
}
