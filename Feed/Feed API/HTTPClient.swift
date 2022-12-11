//
//  HTTPClient.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 11/12/22.
//

import Foundation

public protocol HTTPClient {
    func get(from url: URL) async throws -> (Data, HTTPURLResponse)
}
