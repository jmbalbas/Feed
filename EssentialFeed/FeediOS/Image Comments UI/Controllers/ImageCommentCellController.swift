//
//  ImageCommentCellController.swift
//  FeediOS
//
//  Created by Juan Santiago Martín Balbás on 23/11/23.
//

import Feed
import UIKit

public class ImageCommentCellController: NSObject, UITableViewDataSource {
    private let model: ImageCommentViewModel

    public init(model: ImageCommentViewModel) {
        self.model = model
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ImageCommentCell = tableView.dequeueReusableCell()
        cell.messageLabel.text = model.message
        cell.dateLabel.text = model.date
        cell.usernameLabel.text = model.username
        return cell
    }
}
