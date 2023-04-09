//
//  LocalFeedLoader.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 18/1/23.
//

import Foundation

private struct FeedCachePolicy {

    private enum Constants {
        static let maxCacheAgeInDays = 7
    }

    private let currentDate: () -> Date
    private let calendar = Calendar(identifier: .gregorian)

    init(currentDate: @escaping () -> Date) {
        self.currentDate = currentDate
    }

    func validate(_ timestamp: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: Constants.maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        return currentDate() < maxCacheAge
    }
}

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    private let cachePolicy: FeedCachePolicy

    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
        self.cachePolicy = FeedCachePolicy(currentDate: currentDate)
    }


    private func deleteCache(completion: ((Error?) -> Void)? = nil) {
        store.deleteCachedFeed { error in
            completion?(error)
        }
    }
}

extension LocalFeedLoader {
    public typealias SaveResult = Error?

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

    private func validate(_ timestamp: Date) -> Bool {
        cachePolicy.validate(timestamp)
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
    public typealias LoadResult = Result<[FeedImage], Error>

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
