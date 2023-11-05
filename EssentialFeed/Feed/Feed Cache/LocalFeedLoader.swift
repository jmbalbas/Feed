//
//  LocalFeedLoader.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 18/1/23.
//

import Foundation

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date

    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    private func deleteCache(completion: ((Result<Void, Error>) -> Void)? = nil) {
        store.deleteCachedFeed { error in
            completion?(error)
        }
    }
}

extension LocalFeedLoader: FeedCache {
    public typealias SaveResult = FeedCache.Result

    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        deleteCache { [weak self] result in
            guard let self = self else { return }

            switch result {
            case let .failure(error):
                completion(.failure(error))
            case .success:
                self.cache(feed, with: completion)
            }
        }
    }

    private func cache(_ feed: [FeedImage], with completion: @escaping (SaveResult) -> Void) {
        store.insert(feed.toLocal, timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }

            completion(error)
        }
    }

    private func validate(_ timestamp: Date) -> Bool {
        FeedCachePolicy.validate(timestamp, against: currentDate())
    }
}

extension LocalFeedLoader: FeedLoader {
    public func load() async throws -> [FeedImage] {
        try await withCheckedThrowingContinuation { continuation in
            load(completion: continuation.resume(with:))
        }
    }
}

extension LocalFeedLoader {
    public func load(completion: @escaping (FeedLoader.Result) -> Void) {
        store.retrieve { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case let .success(.some(cache)) where self.validate(cache.timestamp):
                completion(.success(cache.feed.toModels))
            case .success:
                completion(.success([]))
            }
        }
    }
}

extension LocalFeedLoader {
    public typealias ValidationResult = Result<Void, Error>

    public func validateCache(completion: @escaping (ValidationResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure:
                self.deleteCache(completion: completion)
            case let .success(.some(cache)) where !self.validate(cache.timestamp):
                self.deleteCache(completion: completion)
            case .success:
                completion(.success(()))
            }
        }
    }
}

private extension Array where Element == FeedImage {
    var toLocal: [LocalFeedImage] {
        map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    }
}

private extension Array where Element == LocalFeedImage {
    var toModels: [FeedImage] {
        map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    }
}
