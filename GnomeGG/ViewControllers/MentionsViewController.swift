//
//  MentionsViewController.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/2/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import NVActivityIndicatorView

class MentionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var messages = [DGGMessage]()
    var renderedMessages = [NSMutableAttributedString]()

    var offset = 0
    let count = 100
    var loadingMentions = false
    var outOfMentions = false
    var lastIndex = -1
    
    let mentionsBaseURL = "https://polecat.me/api/mentions/%@"
    
    
    @IBOutlet weak var loginLabel: UILabel!
    @IBOutlet weak var arrowImageView: UIImageView!
    @IBOutlet weak var mentionsTableView: UITableView!
    @IBOutlet weak var nvActivityIndicator: NVActivityIndicatorView!
    @IBOutlet weak var noMentionsLabel: UILabel!
    
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mentionsTableView.delegate = self
        mentionsTableView.dataSource = self
        refreshController()
        noMentionsLabel.isHidden = true
        // Do any additional setup after loading the view.
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        mentionsTableView.estimatedRowHeight = 200
        mentionsTableView.rowHeight = UITableView.automaticDimension
        
        
        loginLabel.isHidden = settings.dggUsername != ""
        arrowImageView.isHidden = settings.dggUsername != ""
        loadInitialMentions()
    }
    
    @objc
    private func loadInitialMentions() {
        print("load mentions")
        guard !loadingMentions else {
            return
        }

        nvActivityIndicator.startAnimating()
        messages = [DGGMessage]()
        renderedMessages = [NSMutableAttributedString]()
        offset = 0
        outOfMentions = false
        loadingMentions = false
        loadMentions()
    }
    
    private func refreshController() {
        refreshControl.tintColor = UIColor(red:1, green:1, blue:1, alpha:1.0)
        //        refreshControl.attributedTitle = NSAttributedString(string: "Fetching Listings ...")
        if #available(iOS 10.0, *) {
            mentionsTableView?.refreshControl = refreshControl
        } else {
            mentionsTableView?.addSubview(refreshControl)
        }
        
        refreshControl.addTarget(self, action: #selector(loadInitialMentions), for: .valueChanged)
    }
    
    private func loadMentions() {
        guard !loadingMentions && !outOfMentions else {
            return
        }

        loadingMentions = true
        guard let url = getMentionsURL() else {
            loadingMentions = false
            return
        }
        
        Alamofire.request(url, method: .get).validate().responseJSON { response in
            self.loadingMentions = false
            self.refreshControl.endRefreshing()
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                self.offset += self.count
                
                if json.arrayValue.count < self.count {
                    self.outOfMentions = true
                    if self.renderedMessages.count == 0 {
                        self.noMentionsLabel.isHidden = false
                        self.mentionsTableView.isHidden = true
                    }
                }
                
                if json.arrayValue.count != 0 {
                    self.noMentionsLabel.isHidden = true
                    self.mentionsTableView.isHidden = false
                }
                
                for mention in json.arrayValue.reversed() {
                    guard let date = mention["date"].int else {
                        continue
                    }
                    
                    guard let nick = mention["nick"].string else {
                        continue
                    }
                    
                    guard let text = mention["text"].string else {
                        continue
                    }
                    
                    let message: DGGMessage = .UserMessage(nick: nick, features: [], timestamp: Date(timeIntervalSince1970: Double(date/1000)), data: text)
                    self.messages.append(message)
                    self.renderedMessages.append(renderMessage(message: message, isLog: true))
                }
                
                self.mentionsTableView.reloadData()
                
                self.nvActivityIndicator.stopAnimating()
                
                
            case .failure(let error):
                print(error)
                return
            }
        }
    }
    
    private func getMentionsURL() -> URL? {
        guard settings.dggUsername != "" else {
            return nil
        }

        var components = URLComponents(string: String(format: mentionsBaseURL, settings.dggUsername))
    
        var queries = [URLQueryItem]()
        queries.append(URLQueryItem(name: "size", value: String(count)))
        queries.append(URLQueryItem(name: "offset", value: String(offset)))
    
        components?.queryItems = queries
        return components?.url
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    private func scrollToIndex(index: Int) {
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: index, section: 0)
            self.mentionsTableView.scrollToRow(at: indexPath, at: .top, animated: false)
        }
    }
    
    // MARK: - TableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return renderedMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // it's over for chatcels
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath) as! ChatTableViewCell
        cell.selectionStyle = .none
        cell.renderMessage(message: renderedMessages[indexPath.row], messageEnum: messages[indexPath.row], isLog: true)
        
        if !loadingMentions && !outOfMentions && lastIndex < indexPath.row && (indexPath.row + 10) > renderedMessages.count {
            loadMentions()
        }
        
        lastIndex = indexPath.row
        
        return cell
    }
    
}
