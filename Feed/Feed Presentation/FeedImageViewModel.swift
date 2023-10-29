//
//  FeedImageViewModel.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 29/10/23.
//

public struct FeedImageViewModel<Image> {
    public let description: String?
    public let location: String?
    public let image: Image?
    public let isLoading: Bool
    public let shouldRetry: Bool

    var hasLocation: Bool {
        location != nil
    }
}
