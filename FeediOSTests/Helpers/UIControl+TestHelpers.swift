//
//  UIControl+TestHelpers.swift
//  FeediOSTests
//
//  Created by Juan Santiago Martín Balbás on 12/10/23.
//

import UIKit

extension UIControl {
    func simulate(event: UIControl.Event) {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: event)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }
}
