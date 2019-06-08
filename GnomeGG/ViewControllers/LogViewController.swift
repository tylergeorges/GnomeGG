//
//  LogViewController.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/8/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class LogViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

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
    var controllerIsActive = true

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var logImageView: UIImageView!
    @IBOutlet weak var logLabel: UILabel!
    @IBOutlet weak var nvActivityIndicatorView: NVActivityIndicatorView!
    
    var renderedMessages = [NSMutableAttributedString]()
    var messages = [DGGMessage]()
    
    var filteredMessages = [DGGMessage]()
    var filteredRenderedMessages = [NSMutableAttributedString]()
    
    var isLog = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isDynamic {
            refreshController()
        }
        
        colorSearchbar()
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension

        loadInitialMessages()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        controllerIsActive = false
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
            guard self.controllerIsActive else {
                return
            }

            self.logBackoff = self.logBackoff * 2
            self.loadInitialMessages()
        })
    }
    
    func doneLoading() {
        nvActivityIndicatorView.stopAnimating()
        updateData()
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
    
    func doneSearching() {
        filteredRenderedMessages = renderedMessages
        filteredMessages = messages
        searchBar.resignFirstResponder()
        tableView.reloadData()
    }
    
    func updateData() {
        guard !searchBar.isFirstResponder else {
            return
        }
        
        filteredRenderedMessages = renderedMessages
        filteredMessages = messages
    }
    
    // MARK: - SearchBar
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.text = ""
        doneSearching()
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
            doneSearching()
            return
        }
        
        guard searchText != "" else {
            doneSearching()
            return
        }

        filteredRenderedMessages = [NSMutableAttributedString]()
        filteredMessages = [DGGMessage]()

        for (i, message) in messages.enumerated()  {
            switch message {
            case .UserMessage(_, _, _,let data):
                if data.lowercased().contains(searchText) {
                    filteredRenderedMessages.append(renderedMessages[i])
                    filteredMessages.append(message)
                }
            default: break
            }
        
        }
        
        tableView.reloadData()
    }
    
    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "logCell", for: indexPath) as! ChatTableViewCell
        cell.selectionStyle = .none
        cell.renderMessage(message: filteredRenderedMessages[indexPath.row], messageEnum: filteredMessages[indexPath.row], isLog: isLog)
        
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
    
    private func colorSearchbar() {
        searchBar.setImage(UIImage(named: "search"), for: .search, state: .normal)
        for subView in searchBar.subviews
        {
            for subView1 in subView.subviews
            {
                if let textField = subView1 as? UITextField {
                    textField.backgroundColor = UIColor.gray
                    textField.placeholder = "Press Search Button to Search"
                    textField.textColor = UIColor.white
                }
            }
        }
    }

}
