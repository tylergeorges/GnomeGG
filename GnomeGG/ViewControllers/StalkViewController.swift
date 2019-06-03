//
//  StalkViewController.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/2/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import NVActivityIndicatorView

class StalkViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var stalkTableView: UITableView!
    @IBOutlet weak var nvActivityIndicatorView: NVActivityIndicatorView!
    @IBOutlet weak var noMessagesLabel: UILabel!
    
    var messages = [DGGMessage]()
    var offset = 0
    let count = 100
    var loadingStalks = false
    var outOfStalks = false
    var lastIndex = -1
    var stalkedUser: String?
    
    let stalkURL = "https://polecat.me/api/stalk/%@"
    
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        noMessagesLabel.isHidden = true
        stalkTableView.dataSource = self
        stalkTableView.delegate = self
        
        refreshController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadInitialStalks()
    }
    
    private func getMessages() {
        guard let url = getStalkURL() else {
            return
        }
        
        Alamofire.request(url, method: .get).validate().responseJSON { response in
            self.loadingStalks = false
            self.refreshControl.endRefreshing()
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                self.offset += self.count
                
                if json.arrayValue.count < self.count {
                    self.outOfStalks = true
                    if self.messages.count == 0 {
                        self.noMessagesLabel.isHidden = false
                        self.stalkTableView.isHidden = true
                    }
                }
                
                if json.arrayValue.count != 0 {
                    self.noMessagesLabel.isHidden = true
                    self.stalkTableView.isHidden = false
                }
                
                for stalk in json.arrayValue.reversed() {
                    guard let date = stalk["date"].int else {
                        continue
                    }
                    
                    guard let nick = stalk["nick"].string else {
                        continue
                    }
                    
                    guard let text = stalk["text"].string else {
                        continue
                    }
                    
                    self.messages.append(.UserMessage(nick: nick, features: [], timestamp: Date(timeIntervalSince1970: Double(date/1000)), data: text))
                }
                
                self.stalkTableView.reloadData()
                
                self.nvActivityIndicatorView.stopAnimating()
                
                
            case .failure(let error):
                print(error)
                return
            }
        }
    }
    
    
    
    @objc
    private func loadInitialStalks() {
        guard !loadingStalks else {
            return
        }
        
        nvActivityIndicatorView.startAnimating()
        messages = [DGGMessage]()
        offset = 0
        outOfStalks = false
        loadingStalks = false
        getMessages()
    }
    
    private func getStalkURL() -> URL? {
        guard let stalkedUser = stalkedUser else {
            return nil
        }
        
        var components = URLComponents(string: String(format: stalkURL, stalkedUser))
        
        var queries = [URLQueryItem]()
        queries.append(URLQueryItem(name: "size", value: String(count)))
        queries.append(URLQueryItem(name: "offset", value: String(offset)))
        
        components?.queryItems = queries
        return components?.url
    }
        
    
    private func refreshController() {
        refreshControl.tintColor = UIColor(red:1, green:1, blue:1, alpha:1.0)
        if #available(iOS 10.0, *) {
            stalkTableView?.refreshControl = refreshControl
        } else {
            stalkTableView?.addSubview(refreshControl)
        }
        
        refreshControl.addTarget(self, action: #selector(loadInitialStalks), for: .valueChanged)
    }
    
    // MARK: - TableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // it's over for chatcels
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath) as! ChatTableViewCell
        cell.selectionStyle = .none
        cell.renderMessage(message: messages[indexPath.row], isLog: true)
        
        if !loadingStalks && !outOfStalks && lastIndex < indexPath.row && (indexPath.row + 10) > messages.count {
            getMessages()
        }
        
        lastIndex = indexPath.row
        
        return cell
    }
}
