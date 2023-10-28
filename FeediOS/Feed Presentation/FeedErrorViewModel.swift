//
//  FeedErrorViewModel.swift
//  FeediOS
//
//  Created by Juan Santiago Martín Balbás on 28/10/23.
//

struct FeedErrorViewModel {
    let message: String?

    static var noError: FeedErrorViewModel {
        FeedErrorViewModel(message: nil)
    }

    static func error(message: String) -> FeedErrorViewModel {
        FeedErrorViewModel(message: message)
    }
}
