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
    var merchStoreURL: String?
    var privacyPolicyURL: String?
    var termsOfUseURL: String?
    var githubURL: String?
    var supportEmail: String?
    var feedbackSubject: String?
    var feedbackFooter: String?
    var premiumDiscountCode: String?
    var premiumDiscountLabel: String?
    var aboutYoutubeID: String?
    var cachedAt: Date
    
    init(
        currentVersion: String,
        ratingVersion: String,
        ratingCount: Int,
        customMessage: String?,
        featuredMessage: String?,
        updateAvailable: Bool,
        lastUpdated: String,
        merchStoreURL: String? = nil,
        privacyPolicyURL: String? = nil,
        termsOfUseURL: String? = nil,
        githubURL: String? = nil,
        supportEmail: String? = nil,
        feedbackSubject: String? = nil,
        feedbackFooter: String? = nil,
        premiumDiscountCode: String? = nil,
        premiumDiscountLabel: String? = nil,
        aboutYoutubeID: String? = nil
    ) {
        self.currentVersion = currentVersion
        self.ratingVersion = ratingVersion
        self.ratingCount = ratingCount
        self.customMessage = customMessage
        self.featuredMessage = featuredMessage
        self.updateAvailable = updateAvailable
        self.lastUpdated = lastUpdated
        self.merchStoreURL = merchStoreURL
        self.privacyPolicyURL = privacyPolicyURL
        self.termsOfUseURL = termsOfUseURL
        self.githubURL = githubURL
        self.supportEmail = supportEmail
        self.feedbackSubject = feedbackSubject
        self.feedbackFooter = feedbackFooter
        self.premiumDiscountCode = premiumDiscountCode
        self.premiumDiscountLabel = premiumDiscountLabel
        self.aboutYoutubeID = aboutYoutubeID
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
            lastUpdated: apiStats.ratings.lastUpdated,
            merchStoreURL: apiStats.links?.merchStore,
            privacyPolicyURL: apiStats.links?.privacyPolicy,
            termsOfUseURL: apiStats.links?.termsOfUse,
            githubURL: apiStats.links?.github,
            supportEmail: apiStats.support?.email,
            feedbackSubject: apiStats.support?.feedbackSubject,
            feedbackFooter: apiStats.support?.feedbackFooter,
            premiumDiscountCode: apiStats.premium?.discountCode,
            premiumDiscountLabel: apiStats.premium?.discountLabel,
            aboutYoutubeID: apiStats.about?.youtubeId
        )
    }
}

// Data models for app statistics API
struct AppStats: Codable {
    let currentVersion: String
    let ratings: RatingInfo
    let featuredMessage: String?
    let updateAvailable: Bool
    let links: AppStatsLinks?
    let support: AppStatsSupport?
    let premium: AppStatsPremium?
    let about: AppStatsAbout?
}

struct RatingInfo: Codable {
    let version: String
    let ratingCount: Int
    let customMessage: String?
    let lastUpdated: String
}

extension RatingInfo {
    var displayMessage: String {
        if let customMessage,
           !customMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return customMessage
        }

        return "Join the \(ratingCount) people who have rated this version."
    }
}

struct AppStatsLinks: Codable {
    let merchStore: String?
    let privacyPolicy: String?
    let termsOfUse: String?
    let github: String?
}

struct AppStatsSupport: Codable {
    let email: String?
    let feedbackSubject: String?
    let feedbackFooter: String?
}

struct AppStatsPremium: Codable {
    let discountCode: String?
    let discountLabel: String?
}

struct AppStatsAbout: Codable {
    let youtubeId: String?
}

extension AppStats {
    private enum Defaults {
        static let merchStoreURL = "https://bit.ly/awsary-merch"
        static let privacyPolicyURL = "https://tig.pt/awsary-privacy"
        static let termsOfUseURL = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula"
        static let githubURL = "https://github.com/tigpt/AWSary/"
        static let supportEmail = "mail@tig.pt"
        static let feedbackSubject = "Feedback on AWSary"
        static let premiumDiscountCode = "GSC293ZEQD"
        static let premiumDiscountLabel = "10% Discount on AWSary Merch Store"
        static let aboutYoutubeID = "c0SjbhRR3lk"
    }

    var merchStoreURLString: String {
        links?.merchStore ?? Defaults.merchStoreURL
    }

    var privacyPolicyURLString: String {
        links?.privacyPolicy ?? Defaults.privacyPolicyURL
    }

    var termsOfUseURLString: String {
        links?.termsOfUse ?? Defaults.termsOfUseURL
    }

    var githubURLString: String {
        links?.github ?? Defaults.githubURL
    }

    var supportEmail: String {
        support?.email ?? Defaults.supportEmail
    }

    var feedbackSubject: String {
        support?.feedbackSubject ?? Defaults.feedbackSubject
    }

    var feedbackFooter: String? {
        support?.feedbackFooter
    }

    var premiumDiscountCode: String? {
        premium?.discountCode ?? Defaults.premiumDiscountCode
    }

    var premiumDiscountLabel: String {
        premium?.discountLabel ?? Defaults.premiumDiscountLabel
    }

    var aboutYoutubeID: String {
        about?.youtubeId ?? Defaults.aboutYoutubeID
    }

    var visibleFeaturedMessage: String? {
        guard let featuredMessage else { return nil }
        let trimmedMessage = featuredMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedMessage.isEmpty ? nil : trimmedMessage
    }
}
