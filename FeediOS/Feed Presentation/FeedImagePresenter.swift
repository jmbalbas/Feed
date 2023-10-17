//
//  FeedImagePresenter.swift
//  FeediOS
//
//  Created by Juan Santiago Martín Balbás on 17/10/23.
//

import Feed
import Foundation

protocol FeedImageView {
    associatedtype Image

    func display(_ model: FeedImageViewModel<Image>)
}

final class FeedImagePresenter<View: FeedImageView, Image> where View.Image == Image {
    private let view: View
    private let imagetransformer: (Data) -> Image?

    init(view: View, imageTransformer: @escaping (Data) -> Image?) {
        self.view = view
        self.imagetransformer = imageTransformer
    }

    func didStartLoadingImageData(for model: FeedImage) {
        view.display(FeedImageViewModel(
            description: model.description,
            location: model.location,
            image: nil,
            isLoading: true,
            shouldRetry: false))
    }

    private struct InvalidImageDataError: Error {}

    func didFinishLoadingImageData(with data: Data, for model: FeedImage) {
        guard let image = imagetransformer(data) else {
            return didFinishLoadingImageData(with: InvalidImageDataError(), for: model)
        }

        view.display(FeedImageViewModel(
            description: model.description,
            location: model.location,
            image: image,
            isLoading: false,
            shouldRetry: false))
    }

    func didFinishLoadingImageData(with error: Error, for model: FeedImage) {
        view.display(FeedImageViewModel(
            description: model.description,
            location: model.location,
            image: nil,
            isLoading: false,
            shouldRetry: true))
    }
}
