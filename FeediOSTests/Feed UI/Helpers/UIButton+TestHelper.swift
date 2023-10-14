//
//  UIButton+TestHelper.swift
//  FeediOSTests
//
//  Created by Juan Santiago Martín Balbás on 12/10/23.
//

import UIKit

extension UIButton {
    func simulateTap() {
        simulate(event: .touchUpInside)
    }
}
