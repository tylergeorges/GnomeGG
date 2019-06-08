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
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var logImageView: UIImageView!
    @IBOutlet weak var logLabel: UILabel!
    @IBOutlet weak var nvActivityIndicatorView: NVActivityIndicatorView!
    
    var renderedMessages = [NSMutableAttributedString]()
    var messages = [DGGMessage]()
    
    var overrustleURL: String?
    
    var isReversed = false
    
    var isLog = true

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        loadInitialMessages()
    }
    
    func loadInitialMessages() {
        nvActivityIndicatorView.startAnimating()
        tableView.isHidden = true
        logImageView.isHidden = false
        logLabel.text = loadingText
        logLabel.isHidden = false
        
        dggAPI.getUserLogs(for: overrustleURL!, completionHandler: { messages in
            self.nvActivityIndicatorView.stopAnimating()
            guard var messages = messages else {
                self.loadFailed()
                return
            }
            
            if self.isReversed {
                messages = messages.reversed()
            }
            
            DispatchQueue.global(qos: .utility).async {
                for message in messages {
                    guard let parsedMessage = DGGParser.parseOverrustleLogLine(line: message) else {
                        print("error parsing message")
                        continue
                    }
                    
                    self.renderedMessages.append(renderMessage(message: parsedMessage, isLog: self.isLog))
                    self.messages.append(parsedMessage)
                    
                    if self.messages.count % 100 == 0 {
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                            self.tableView.isHidden = false
                            self.logLabel.isHidden = true
                            self.logImageView.isHidden = true
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.tableView.isHidden = false
                    self.logLabel.isHidden = true
                    self.logImageView.isHidden = true
                }
            }
        })
    }
    
    func loadFailed() {
        logLabel.text = errorText
        tableView.isHidden = true
        logLabel.isHidden = false
        logImageView.isHidden = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(self.logBackoff), execute: {
            self.logBackoff = self.logBackoff * 2
            self.loadInitialMessages()
        })
    }
    
    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return renderedMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "logCell", for: indexPath) as! ChatTableViewCell
        cell.selectionStyle = .none
        cell.renderMessage(message: renderedMessages[indexPath.row], messageEnum: messages[indexPath.row], isLog: isLog)
        
        return cell
    }

}
