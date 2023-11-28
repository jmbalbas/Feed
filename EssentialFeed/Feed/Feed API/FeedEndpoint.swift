//
//  FeedEndpoint.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 26/11/23.
//

import Foundation

public enum FeedEndpoint {
    case get

    public func url(baseURL: URL) -> URL {
        switch self {
        case .get:
            baseURL.appendingPathComponent("/v1/feed")
        }
    }
}
