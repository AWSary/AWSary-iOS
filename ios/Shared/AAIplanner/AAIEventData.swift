import SwiftUI
import Foundation

struct AAIEventData {
   @ObservedObject var userModel = UserViewModel.shared
   
    static let eventNames = [
      "AWS Cloud Essentials for Business Leaders",
      "AWS Cloud Essentials for Business Leaders – Financial Services",
      "AWS Cloud Practitioner Essentials",
      "AWS Technical Essentials",
      "AWS Security Essentials",
      "Architecting on AWS",
      "AWS Cloud Financial Management for Builders",
      "AWS Cloud for Finance Professionals",
      "AWS Security Best Practices",
      "AWS Security Governance at Scale",
      "AWS Well-Architected Best Practices",
      "Advanced AWS Well-Architected Best Practices",
      "Big Data on AWS",
      "Building Batch Data Analytics Solutions on AWS",
      "Building Data Analytics Solutions Using Amazon Redshift",
      "Building Data Lakes on AWS",
      "Building Streaming Data Analytics on AWS",
      "Cloud Operations on AWS",
      "Data Warehousing on AWS",
      "Deep Learning on AWS",
      "Developing on AWS",
      "Developing Serverless Solutions on AWS",
      "DevOps Engineering on AWS",
      "Migrating to AWS",
      "MLOps Engineering on AWS",
      "Planning and Designing Databases on AWS",
      "Practical Data Science with Amazon SageMaker",
      "Running Containers on Amazon Elastic Kubernetes Service",
      "Security Engineering on AWS",
      "The Machine Learning Pipeline on AWS",
      "Video Streaming Essentials for AWS Media Services",
      "Advanced Architecting on AWS",
      "Advanced Developing on AWS",
      "Architecting on AWS - Accelerator",
      "Amazon SageMaker Studio for Data Scientists",
      "Authoring Visual Analytics Using Amazon QuickSight",
    ]
    
   // TODO add real data to the trainings
    static let eventSequences: [String: [(name: String, duration: Int)]] = [
        "Architecting on AWS": [("AoA - Module 0", 20), ("AoA - Module 1", 45), ("AoA - Module 2", 20)],
        "Advanced Architecting on AWS": [("AAoA - Module 0", 20), ("AAoA - Module 1", 45), ("AAoA - Module 2", 20)],
        "Developing on AWS": [("DoA - Module 0", 20), ("DoA - Module 1", 10), ("DoA - Module 2", 120)],
        "Advanced Developing on AWS": [("ADoA - Module 0", 20), ("ADoA - Module 1", 10), ("ADoA - Module 2", 120)]
    ]
    
    static let timeZones: [TimeZoneInfo] = TimeZone.knownTimeZoneIdentifiers.sorted().map { TimeZoneInfo(identifier: $0) }
}
