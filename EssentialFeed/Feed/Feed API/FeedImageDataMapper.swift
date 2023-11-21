//
//  FeedImageDataMapper.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 21/11/23.
//

import Foundation

public enum FeedImageDataMapper {
    public enum Errors: Error {
        case invalidData
    }

    public static func map(_ data: Data, from response: HTTPURLResponse) throws -> Data {
        guard response.isOK, !data.isEmpty else {
            throw Errors.invalidData
        }
        return data
    }
}
