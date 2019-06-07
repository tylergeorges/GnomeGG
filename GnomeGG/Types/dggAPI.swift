//
//  dggAPI.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 5/31/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import SwiftyJSON
import NotificationBannerSwift

class DGGAPI {
    var flairs = [Flair]()
    var emotes = [Emote]()
    
    let flairEndpoint = "https://cdn.destiny.gg/4.2.0/flairs/flairs.json"
    let emoteEndpoint = "https://cdn.destiny.gg/4.2.0/emotes/emotes.json"
    let bbdggEmoteEndpoint = "https://polecat.me/api/bbdgg_emotes"
    let historyEndpoint = "https://www.destiny.gg/api/chat/history"
    let userInfoEndpoint = "https://www.destiny.gg/api/chat/me"

    var backgroundSessionManager: SessionManager?
    var activeSessionManager: SessionManager?
    
    init() {
        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: "me.polecat.app.background")
        backgroundConfiguration.timeoutIntervalForRequest = 2
        backgroundConfiguration.timeoutIntervalForResource = 2
        backgroundSessionManager = Alamofire.SessionManager(configuration: backgroundConfiguration)
        
        let activeConfiguration = URLSessionConfiguration.default
        activeConfiguration.timeoutIntervalForRequest = 3
        activeConfiguration.timeoutIntervalForResource = 3
        activeSessionManager = Alamofire.SessionManager(configuration: activeConfiguration)
    }
    
    
    func getFlairList() {
        activeSessionManager!.request(flairEndpoint, method: .get).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                for (_, flairJson) in json {
                    self.downloadFlair(json: flairJson)
                }
                self.flairs.append(Flair.init(name: "polecat", label: "App Only Cute Label", color: "e463cf", hidden: false, priority: 0, image: UIImage(named: "cherry")!, height: 18, width: 18))
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func getEmoteList() {
        activeSessionManager!.request(emoteEndpoint, method: .get).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                for (_, emoteJosn) in json {
                    self.downloadEmote(json: emoteJosn)
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func getBBDGGEmoteList() {
        activeSessionManager!.request(bbdggEmoteEndpoint, method: .get).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                for (_, emoteJosn) in json {
                    self.downloadEmote(json: emoteJosn)
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func getHistory(completionHandler: @escaping  ([String]) -> Void) {
        activeSessionManager!.request(historyEndpoint, method: .get).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                let messages = json.arrayValue.map {$0.stringValue}
                completionHandler(messages)
            case .failure(let error):
                print("=======GET HISTORY ERROR=======")
                print(error)
                print("=======GET HISTORY ERROR=======")
                completionHandler([String]())
            }
        }
    }
    
    func getUserSettings() {
        let headers: HTTPHeaders = [
            "Cookie": "sid=" + settings.dggCookie,
        ]

        activeSessionManager!.request(userInfoEndpoint, headers: headers).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                print("got user settings")
                let json = JSON(value)
                if let nick = json["nick"].string {
                    settings.dggUsername = nick
                    print("User nick: " + nick)
                } else {
                    guard let username = json["username"].string else {
                        return
                    }
                    print("User nick: " + username)
                    settings.dggUsername = username
                }
                
                guard let dggSettings = json["settings"].array else {
                    return
                }
                
                print("got user settings json")
                
                settings.parseDGGUserSettings(json: dggSettings)
            case .failure(let error):
                if response.response?.statusCode == 403 {
                    print("cookie invalidated")
                    settings.reset()
                } else {
                    print(error)
                }
            }
        }
    }
    
    private func downloadEmote(json: JSON) {
        guard let imageInfo = json["image"].array else {
            return
        }
        
        guard let url = imageInfo[0]["url"].string else {
            return
        }
        
        guard let prefix = json["prefix"].string else {
            return
        }
        
        let isTwitch = json["twitch"].bool ?? false
        
        guard let height = imageInfo[0]["height"].int else {
            return
        }
        
        guard let width = imageInfo[0]["width"].int else {
            return
        }
        
        let isBBDGG = json["bbdgg"].bool ?? false
        
        getData(from: URL(string: url)!) { data, response, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async() {
                guard let image = UIImage(data: data) else {
                    print("error downloading image")
                    return
                }
                self.emotes.append(Emote.init(prefix: prefix, twitch: isTwitch, bbdgg: isBBDGG, image: image, height: height, width: width))
            }
        }
    }
    
    private func downloadFlair(json: JSON) {
        guard let imageInfo = json["image"].array else {
            return
        }
        
        guard let url = imageInfo[0]["url"].string else {
            return
        }
        
        guard let name = json["name"].string else {
            return
        }
        
        var color = json["color"].stringValue
        if color == "" {
            color = "#FFFFFF"
        }

        let priority = json["priority"].int ?? 999
        let hidden = json["hidden"].bool ?? false
        
        guard let height = imageInfo[0]["height"].int else {
            return
        }
        
        guard let width = imageInfo[0]["width"].int else {
            return
        }
        
        guard let label = json["label"].string else {
            return
        }
        
        getData(from: URL(string: url)!) { data, response, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async() {
                guard let image = UIImage(data: data) else {
                    print("error downloading image")
                    return
                }
                self.flairs.append(Flair.init(name: name, label: label, color: color, hidden: hidden, priority: priority, image: image, height: height, width: width))
            }
        }
    }
    
    private func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    private func showAuthenticationError(reason: String) {
        let banner = NotificationBanner(title: "Authorization Error", subtitle: reason, style: .danger)
        banner.show()
    }
    
    private func showAuthenticationSuccess() {
//        let banner = NotificationBanner(title: "Authentication Succeful", subtitle: "Authenticated as " + settings.dggUsername, style: .success)
//        banner.show()
    }
}

struct Flair {
    let name: String
    let label: String
    let color: String
    let hidden: Bool
    let priority: Int
    let image: UIImage
    let height: Int
    let width: Int
}

public struct Emote {
    let prefix: String
    let twitch: Bool
    let bbdgg: Bool
    let image: UIImage
    let height: Int
    let width: Int
}

public struct User {
    let nick: String
    let features: [String]
}
