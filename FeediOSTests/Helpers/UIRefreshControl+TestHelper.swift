//
//  UIRefreshControl+TestHelper.swift
//  FeediOSTests
//
//  Created by Juan Santiago Martín Balbás on 12/10/23.
//

import UIKit

extension UIRefreshControl {
    func simulatePullToRefresh() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach { action in
                (target as NSObject).perform(Selector(action))
            }
        }
    }
}
