//
//  SystemSetting.swift
//  AWSary
//
//  Created by System on SwiftData implementation.
//

import Foundation
import SwiftData

@Model
class SystemSetting {
    @Attribute(.unique) var key: String
    var stringValue: String?
    var boolValue: Bool?
    var intValue: Int?
    var doubleValue: Double?
    var dateValue: Date?
    var createdAt: Date
    var updatedAt: Date
    
    init(key: String, stringValue: String? = nil, boolValue: Bool? = nil, intValue: Int? = nil, doubleValue: Double? = nil, dateValue: Date? = nil) {
        self.key = key
        self.stringValue = stringValue
        self.boolValue = boolValue
        self.intValue = intValue
        self.doubleValue = doubleValue
        self.dateValue = dateValue
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Convenience initializers for different types
    convenience init(key: String, value: String) {
        self.init(key: key, stringValue: value)
    }
    
    convenience init(key: String, value: Bool) {
        self.init(key: key, boolValue: value)
    }
    
    convenience init(key: String, value: Int) {
        self.init(key: key, intValue: value)
    }
    
    convenience init(key: String, value: Double) {
        self.init(key: key, doubleValue: value)
    }
    
    convenience init(key: String, value: Date) {
        self.init(key: key, dateValue: value)
    }
} 