//
//  CachedAppStats.swift
//  AWSary
//
//  Created by System on SwiftData implementation.
//

import Foundation
import SwiftData

@Model
class CachedAppStats {
    var currentVersion: String
    var ratingVersion: String
    var ratingCount: Int
    var customMessage: String?
    var featuredMessage: String?
    var updateAvailable: Bool
    var lastUpdated: String
    var cachedAt: Date
    
    init(currentVersion: String, ratingVersion: String, ratingCount: Int, customMessage: String?, featuredMessage: String?, updateAvailable: Bool, lastUpdated: String) {
        self.currentVersion = currentVersion
        self.ratingVersion = ratingVersion
        self.ratingCount = ratingCount
        self.customMessage = customMessage
        self.featuredMessage = featuredMessage
        self.updateAvailable = updateAvailable
        self.lastUpdated = lastUpdated
        self.cachedAt = Date()
    }
    
    // Convert from API response
    convenience init(from apiStats: AppStats) {
        self.init(
            currentVersion: apiStats.currentVersion,
            ratingVersion: apiStats.ratings.version,
            ratingCount: apiStats.ratings.ratingCount,
            customMessage: apiStats.ratings.customMessage,
            featuredMessage: apiStats.featuredMessage,
            updateAvailable: apiStats.updateAvailable,
            lastUpdated: apiStats.ratings.lastUpdated
        )
    }
}

// Data models for app statistics API
struct AppStats: Codable {
    let currentVersion: String
    let ratings: RatingInfo
    let featuredMessage: String?
    let updateAvailable: Bool
}

struct RatingInfo: Codable {
    let version: String
    let ratingCount: Int
    let customMessage: String?
    let lastUpdated: String
} 