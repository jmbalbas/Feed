//
//  FeedCachePolicy.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 8/8/23.
//

import Foundation

enum FeedCachePolicy {
    private enum Constants {
        static let maxCacheAgeInDays = 7
    }
    
    private static let calendar = Calendar(identifier: .gregorian)

    static func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: Constants.maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        return date < maxCacheAge
    }
}
