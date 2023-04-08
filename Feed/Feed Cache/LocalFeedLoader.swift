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
    private let calendar = Calendar(identifier: .gregorian)

    private enum Constants {
        static let maxCacheAgeInDays = 7
    }

    public typealias SaveResult = Error?
    public typealias LoadResult = Result<[FeedImage], Error>

    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    private func validate(_ timestamp: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: Constants.maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        return currentDate() < maxCacheAge
    }

    private func deleteCache(completion: ((Error?) -> Void)? = nil) {
        store.deleteCachedFeed { error in
            completion?(error)
        }
    }
}

extension LocalFeedLoader {
    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        deleteCache { [weak self] error in
            guard let self = self else { return }

            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
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
}

extension LocalFeedLoader: FeedLoader {
    public func load() async throws -> [FeedImage] {
        try await withCheckedThrowingContinuation { continuation in
            load(completion: continuation.resume(with:))
        }
    }
}

extension LocalFeedLoader {
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case let .found(feed, timestamp) where self.validate(timestamp):
                completion(.success(feed.toModels))
            case .found, .empty:
                completion(.success([]))
            }
        }
    }
}

extension LocalFeedLoader {
    public func validateCache() {
        store.retrieve { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure:
                self.deleteCache()
            case let .found(_, timestamp) where !self.validate(timestamp):
                self.deleteCache()
            case .empty, .found:
                break
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
