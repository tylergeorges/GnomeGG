//
//  LogViewController.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/8/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class LogViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var logBackoff = 100
    
    var loadingText = "Loading Logs"
    var errorText = "Error Loading Logs"
    
    var offset = 0
    let count = 100
    var loadingDynamicData = false
    var outOfData = false
    
    var lastIndex = -1
    
    private let refreshControl = UIRefreshControl()
    
    var isDynamic = false
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var logImageView: UIImageView!
    @IBOutlet weak var logLabel: UILabel!
    @IBOutlet weak var nvActivityIndicatorView: NVActivityIndicatorView!
    
    var renderedMessages = [NSMutableAttributedString]()
    var messages = [DGGMessage]()
    
    var isLog = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isDynamic {
            refreshController()
        }

        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension

        loadInitialMessages()
    }

    @objc
    func loadInitialMessages() {
        nvActivityIndicatorView.startAnimating()
        
        tableView.isHidden = true
        logImageView.isHidden = false
        logLabel.text = loadingText
        logLabel.isHidden = false
    }
    
    func loadMoreData() {
        nvActivityIndicatorView.startAnimating()
        loadingDynamicData = true
    }
    
    func loadFailed() {
        nvActivityIndicatorView.stopAnimating()
        logLabel.text = errorText
        tableView.isHidden = true
        logLabel.isHidden = false
        logImageView.isHidden = false
        loadingDynamicData = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(self.logBackoff), execute: {
            self.logBackoff = self.logBackoff * 2
            self.loadInitialMessages()
        })
    }
    
    func doneLoading() {
        nvActivityIndicatorView.stopAnimating()
        tableView.reloadData()
        tableView.isHidden = false
        logLabel.isHidden = true
        logImageView.isHidden = true
        loadingDynamicData = false
        refreshControl.endRefreshing()
        
        if messages.count == 0 {
            tableView.isHidden = true
            logLabel.text = "No Messages To Load"
            logLabel.isHidden = false
            logImageView.isHidden = false
        }
    }
    
    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return renderedMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "logCell", for: indexPath) as! ChatTableViewCell
        cell.selectionStyle = .none
        cell.renderMessage(message: renderedMessages[indexPath.row], messageEnum: messages[indexPath.row], isLog: isLog)
        
        if !loadingDynamicData && !outOfData && lastIndex < indexPath.row && (indexPath.row + 10) > renderedMessages.count {
            loadMoreData()
        }
        
        lastIndex = indexPath.row
    
        return cell
    }
    
    
    private func refreshController() {
        refreshControl.tintColor = UIColor(red:1, green:1, blue:1, alpha:1.0)
        if #available(iOS 10.0, *) {
            tableView?.refreshControl = refreshControl
        } else {
            tableView?.addSubview(refreshControl)
        }
        
        refreshControl.addTarget(self, action: #selector(loadInitialMessages), for: .valueChanged)
    }

}
