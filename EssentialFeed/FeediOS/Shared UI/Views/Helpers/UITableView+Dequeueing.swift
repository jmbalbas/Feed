//
//  UITableView+Dequeueing.swift
//  FeediOS
//
//  Created by Juan Santiago Martín Balbás on 19/10/23.
//

import UIKit

extension UITableView {
    func dequeueReusableCell<T: UITableViewCell>() -> T {
        let identifier = String(describing: T.self)
        return dequeueReusableCell(withIdentifier: identifier) as! T
    }
}
