//
//  FeedCacheTestHelpers.swift
//  FeedTests
//
//  Created by Juan Santiago Martín Balbás on 8/4/23.
//

import Foundation
import Feed

var uniqueImage: FeedImage {
    FeedImage(id: UUID(), description: nil, location: nil, url: anyURL)
}

var uniqueImageFeed: (models: [FeedImage], local: [LocalFeedImage]) {
    let models: [FeedImage] = [uniqueImage, uniqueImage]
    let local = models.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    return (models, local)
}

extension Date {
    private var feedCacheMaxAgeInDays: Int {
        7
    }
    
    func minusFeedCacheMaxAge() -> Date {
        adding(days: -feedCacheMaxAgeInDays)
    }
}
