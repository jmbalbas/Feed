//
//  UIRefreshControl+TestHelper.swift
//  FeediOSTests
//
//  Created by Juan Santiago Martín Balbás on 12/10/23.
//

import UIKit

extension UIRefreshControl {
    func simulatePullToRefresh() {
        simulate(event: .valueChanged)
    }
}
