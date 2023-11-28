//
//  ImageCommentsEndpoint.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 26/11/23.
//

import Foundation

public enum ImageCommentsEndpoint {
    case get(UUID)

    public func url(baseURL: URL) -> URL {
        switch self {
        case let .get(id):
            baseURL.appendingPathComponent("/v1/image/\(id.uuidString)/comments")
        }
    }
}
