//
//  UIRefreshControl+Helpers.swift
//  FeediOS
//
//  Created by Juan Santiago Martín Balbás on 28/10/23.
//

import UIKit

extension UIRefreshControl {
    func update(isRefreshing: Bool) {
        isRefreshing ? beginRefreshing() : endRefreshing()
    }
}
