import SwiftUI
import Foundation

struct AAIEventData {
    static let eventNames = [
        "Architecting on AWS",
        "Advanced Architecting on AWS",
        "Developing on AWS",
        "Advanced Developing on AWS"
    ]
    
    static let eventSequences: [String: [(name: String, duration: Int)]] = [
        "Architecting on AWS": [("AoA - Module 0", 20), ("AoA - Module 1", 45), ("AoA - Module 2", 20)],
        "Advanced Architecting on AWS": [("AAoA - Module 0", 20), ("AAoA - Module 1", 45), ("AAoA - Module 2", 20)],
        "Developing on AWS": [("DoA - Module 0", 20), ("DoA - Module 1", 10), ("DoA - Module 2", 120)],
        "Advanced Developing on AWS": [("ADoA - Module 0", 20), ("ADoA - Module 1", 10), ("ADoA - Module 2", 120)]
    ]
    
    static let timeZones: [TimeZoneInfo] = TimeZone.knownTimeZoneIdentifiers.sorted().map { TimeZoneInfo(identifier: $0) }
}
