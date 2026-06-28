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

extension awsService {
   var awsarySearchNames: [String] {
      [
         name,
         longName
      ]
   }

   var awsarySearchFields: [String] {
      [
         name,
         longName,
         awsarySearchAliases.joined(separator: " "),
         shortDesctiption,
         imageURL.replacingOccurrences(of: "https://static.tig.pt/awsary/logos/Arch_", with: ""),
         youtube_id
      ]
   }

   func matchesAWSarySearchQuery(_ query: String) -> Bool {
      awsarySearchRank(for: query) != nil
   }

   func awsarySearchRank(for query: String) -> Int? {
      let normalizedQuery = AWSServiceSearchText.normalized(query)
      guard !normalizedQuery.isEmpty else { return 0 }

      let normalizedNames = awsarySearchNames.map(AWSServiceSearchText.normalized)
      if normalizedNames.contains(normalizedQuery) { return 0 }
      if normalizedNames.contains(where: { $0.hasPrefix(normalizedQuery) }) { return 1 }
      if normalizedNames.contains(where: { $0.contains(normalizedQuery) }) { return 2 }

      let normalizedAliases = awsarySearchAliases.map(AWSServiceSearchText.normalized)
      if normalizedAliases.contains(normalizedQuery) { return 3 }
      if normalizedAliases.contains(where: { $0.hasPrefix(normalizedQuery) || $0.contains(normalizedQuery) }) { return 4 }
      if AWSServiceSearchText.matches(query: normalizedQuery, fields: awsarySearchFields) { return 5 }
      return nil
   }

   private var awsarySearchAliases: [String] {
      let normalizedName = AWSServiceSearchText.normalized("\(name) \(longName)")
      var aliases: [String] = []

      if normalizedName.contains("lambda") {
         aliases += ["serverless function", "serverless functions", "function as a service"]
      }
      if normalizedName.contains("identity and access management") || normalizedName.contains("iam identity center") || normalizedName.contains("cognito") {
         aliases += ["identity", "access management", "authentication", "authorization"]
      }
      if normalizedName.contains("elastic container") || normalizedName.contains("elastic kubernetes") || normalizedName.contains("fargate") || normalizedName.contains("app runner") {
         aliases += ["containers", "container orchestration", "container registry"]
      }
      if normalizedName.contains("simple queue service") {
         aliases += ["queue", "message queue", "messaging queue"]
      }
      if normalizedName.contains("eventbridge") {
         aliases += ["event bus", "events", "event routing"]
      }
      if normalizedName.contains("simple storage service") {
         aliases += ["object storage", "bucket storage", "s3 bucket"]
      }
      if normalizedName.contains("database") || normalizedName.contains("dynamodb") || normalizedName.contains("rds") || normalizedName.contains("aurora") || normalizedName.contains("documentdb") || normalizedName.contains("redshift") {
         aliases += ["database", "databases", "data store"]
      }

      return aliases
   }
}

private enum AWSServiceSearchText {
   static func normalized(_ value: String) -> String {
      value
         .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
         .lowercased()
         .replacingOccurrences(of: #"[^a-z0-9]+"#, with: " ", options: .regularExpression)
         .trimmingCharacters(in: .whitespacesAndNewlines)
   }

   static func tokens(for value: String) -> [String] {
      normalized(value)
         .split(separator: " ")
         .map(String.init)
   }

   static func matches(query: String, fields: [String]) -> Bool {
      let normalizedQuery = normalized(query)
      guard !normalizedQuery.isEmpty else { return true }

      let haystack = normalized(fields.joined(separator: " "))
      if haystack.contains(normalizedQuery) {
         return true
      }

      let queryTokens = tokens(for: normalizedQuery)
      guard !queryTokens.isEmpty else { return true }

      let fieldTokens = Set(tokens(for: haystack))
      return queryTokens.allSatisfy { queryToken in
         fieldTokens.contains(queryToken) || fieldTokens.contains { $0.hasPrefix(queryToken) }
      }
   }
}
