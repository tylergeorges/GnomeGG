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

class StalkViewController: LogViewController {
    var stalkedUser: String?
    
    let stalkURL = "https://polecat.me/api/stalk/%@"
    
    override func viewDidLoad() {
        isDynamic = true
        super.viewDidLoad()
    }
    
    
    override func loadMoreData() {
        guard !outOfData && !loadingDynamicData else {
            return
        }
        
        super.loadMoreData()
        getMessages()
    }

    private func getMessages() {
        guard let url = getStalkURL() else {
            return
        }
        
        print("getting messages " + String(offset))
        Alamofire.request(url, method: .get).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                self.offset += self.count
                
                if json.arrayValue.count < self.count {
                    self.outOfData = true
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
                    
                    let message: DGGMessage = .UserMessage(nick: nick, features: [], timestamp: Date(timeIntervalSince1970: Double(date/1000)), data: text)
                    self.messages.append(message)
                    self.renderedMessages.append(renderMessage(message: message, isLog: true))
                }
                
                self.doneLoading()
                
                
            case .failure(let error):
                print(error)
                self.loadFailed()
                return
            }
        }
    }
    
    
    
    @objc
    override func loadInitialMessages() {
        guard !loadingDynamicData else {
            return
        }
        
        super.loadInitialMessages()

        messages = [DGGMessage]()
        renderedMessages = [NSMutableAttributedString]()
        offset = 0
        outOfData = false
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
}
