//
//  FeedImageViewModel.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 29/10/23.
//

public struct FeedImageViewModel {
    public let description: String?
    public let location: String?

    public var hasLocation: Bool {
        location != nil
    }
}
