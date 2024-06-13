import SwiftUI
import Foundation

struct TimeZoneInfo: Identifiable {
    let id: String
    let name: String
    let gmtOffset: String
    
    init(identifier: String) {
        let timeZone = TimeZone(identifier: identifier)!
        self.id = identifier
        self.name = timeZone.identifier
        let seconds = timeZone.secondsFromGMT()
        let hours = seconds / 3600
        let minutes = abs(seconds / 60) % 60
        self.gmtOffset = String(format: "GMT%+02d:%02d", hours, minutes)
    }
    
    var displayName: String {
        return "\(name) (\(gmtOffset))"
    }
}
