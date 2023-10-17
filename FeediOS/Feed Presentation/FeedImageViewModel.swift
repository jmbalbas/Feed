//
//  FeedImageViewModel.swift
//  FeediOS
//
//  Created by Juan Santiago Martín Balbás on 14/10/23.
//

struct FeedImageViewModel<Image> {
    let description: String?
    let location: String?
    let image: Image?
    let isLoading: Bool
    let shouldRetry: Bool

    var hasLocation: Bool {
        location != nil
    }
}
