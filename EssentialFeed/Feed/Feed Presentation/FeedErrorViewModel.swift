//
//  FeedErrorViewModel.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 29/10/23.
//

public struct FeedErrorViewModel {
    public let message: String?

    static var noError: FeedErrorViewModel {
        FeedErrorViewModel(message: nil)
    }

    static func error(message: String) -> FeedErrorViewModel {
        FeedErrorViewModel(message: message)
    }
}
