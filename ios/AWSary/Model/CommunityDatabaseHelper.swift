//
//  CommunityDatabaseHelper.swift
//  awsary (iOS)
//
//  Created by Tiago Rodrigues on 06/08/2025.
//

import Foundation

struct CommunityDatabaseHelper {
    
    func getUserGroups() async throws -> [AwsCloudClubElement] {
        guard let url = URL(string:"https://api.awsary.com/community-all") else {
            throw URLError(.badURL)
        }
            
        let (data,_) = try await URLSession.shared.data(from: url)
        let community = try JSONDecoder().decode(CommuityArray.self, from: data)
        return community.awsUserGroups
    }
    
    func getCloudClubs() async throws -> [AwsCloudClubElement] {
        guard let url = URL(string:"https://api.awsary.com/community-all") else {
            throw URLError(.badURL)
        }
            
        let (data,_) = try await URLSession.shared.data(from: url)
        let community = try JSONDecoder().decode(CommuityArray.self, from: data)
        return community.awsCloudClubs
    }
}

struct CommuityArray: Codable {
    let awsUserGroups, awsCloudClubs: [AwsCloudClubElement]
    let awsCommunityBuilders, awsHeroes: [AwsCommunityBuilderElement]
}

struct AwsCloudClubElement: Codable, Hashable {
    let name, location, country, countryCode: String
    let link: String
}

struct AwsCommunityBuilderElement: Codable {
    let basicInfo: BasicInfo
    let location: Location
}

struct BasicInfo: Codable {
    let name, alias, headline, builderProfileID: String

    enum CodingKeys: String, CodingKey {
        case name, alias, headline
        case builderProfileID = "builderProfileId"
    }
}

struct Location: Codable {
    let displayLocation: DisplayLocation
}

struct DisplayLocation: Codable {
    let countryRegion, stateProvince: String
}
