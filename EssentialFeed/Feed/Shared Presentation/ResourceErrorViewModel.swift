//
//  ResourceErrorViewModel.swift
//  Feed
//
//  Created by Juan Santiago Martín Balbás on 29/10/23.
//

public struct ResourceErrorViewModel {
    public let message: String?

    static var noError: ResourceErrorViewModel {
        ResourceErrorViewModel(message: nil)
    }

    static func error(message: String) -> ResourceErrorViewModel {
        ResourceErrorViewModel(message: message)
    }
}
