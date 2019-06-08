//
//  MessageListViewController.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/7/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class MessageListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var nvActivityIndicactor: NVActivityIndicatorView!
    @IBOutlet weak var messageImageView: UIImageView!
    @IBOutlet weak var messageListTableView: UITableView!
    
    private let refreshControl = UIRefreshControl()
    
    var messageListings = [MessageListing]()
    
    var selectedIndex: Int!
    
    var messageListBackoff = 100
    
    override func viewDidLoad() {
        super.viewDidLoad()

        messageListTableView.dataSource = self
        messageListTableView.delegate = self
        refreshController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard settings.dggCookie != "" else {
            messageListTableView.isHidden = true
            statusLabel.text = "Sign in to see private messages"
            statusLabel.isHidden = false
            messageImageView.isHidden = false
            return
        }
        
        loadMessages()
    }
    
    @objc
    private func loadMessages() {
        messageListTableView.isHidden = true
        statusLabel.isHidden = true
        messageImageView.isHidden = true
        nvActivityIndicactor.startAnimating()
        
        dggAPI.getMessages(completionHandler: { messages in
            self.nvActivityIndicactor.stopAnimating()
            self.refreshControl.endRefreshing()
            if let messages = messages {

                self.messageListings = messages.sorted(by: {$0.timestamp.timeIntervalSince1970 > $1.timestamp.timeIntervalSince1970})
                self.statusLabel.isHidden = true
                self.messageImageView.isHidden = true
                self.messageListTableView.reloadData()
                self.messageListTableView.isHidden = false
                
                var unreads = 0
                
                for message in messages {
                    unreads += message.unread
                }
                
                if unreads > 0 {
                    self.tabBarController?.tabBar.items?[3].badgeValue = String(unreads)
                } else {
                    self.tabBarController?.tabBar.items?[3].badgeValue = nil
                }
            } else {
                self.statusLabel.isHidden = false
                self.statusLabel.text = "No Messages Found"
                self.messageImageView.isHidden = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(self.messageListBackoff), execute: {
                    
                    self.messageListBackoff = self.messageListBackoff * 2
                    self.loadMessages()
                })
            }
        })
    }
    
    private func refreshController() {
        refreshControl.tintColor = UIColor(red:1, green:1, blue:1, alpha:1.0)
        if #available(iOS 10.0, *) {
            messageListTableView?.refreshControl = refreshControl
        } else {
            messageListTableView?.addSubview(refreshControl)
        }
        
        refreshControl.addTarget(self, action: #selector(loadMessages), for: .valueChanged)
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "messageSegue" {
            let destVC = segue.destination as! MessageViewController
            destVC.DMedUser = messageListings[selectedIndex].user
        }
    }
    
    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageListings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "messageListingCell", for: indexPath) as! MessageListingTableViewCell
        cell.selectionStyle = .none
        cell.renderListing(listing: messageListings[indexPath.row])
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        performSegue(withIdentifier: "messageSegue", sender: self)
    }
}
