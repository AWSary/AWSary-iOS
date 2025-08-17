//
//  Utils.swift
//  awsary (iOS)
//
//  Created by Tiago Rodrigues on 13/08/2025.
//

import Foundation

func timeAgo(from milliseconds: Int) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated // e.g., "1 wk ago"
    
    return formatter.localizedString(for: date, relativeTo: Date())
}
