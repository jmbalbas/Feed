//
//  FeedViewController.swift
//  FeediOS
//
//  Created by Juan Santiago Martín Balbás on 7/10/23.
//

import Feed
import UIKit

public final class FeedViewController: UITableViewController {
    private var loader: FeedLoader?

    public convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)

        load()
    }

    @objc private func load() {
        refreshControl?.beginRefreshing()

        loader?.load { [weak self] _ in
            self?.refreshControl?.endRefreshing()
        }
    }
}
