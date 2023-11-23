//
//  FeedImagePresenter.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 29/10/23.
//

import Foundation

public final class FeedImagePresenter{
    public static func map(_ image: FeedImage) -> FeedImageViewModel {
        FeedImageViewModel(description: image.description, location: image.location)
    }
}
