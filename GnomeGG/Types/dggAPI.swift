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
import SwiftSoup

class DGGAPI {
    var flairs = [Flair]()
    var emotes = [Emote]()
    
    private let flairEndpoint = "https://cdn.destiny.gg/4.2.0/flairs/flairs.json"
    private let emoteEndpoint = "https://cdn.destiny.gg/4.2.0/emotes/emotes.json"
    private let bbdggEmoteEndpoint = "https://polecat.me/api/bbdgg_emotes"
    private let historyEndpoint = "https://www.destiny.gg/api/chat/history"
    private let userInfoEndpoint = "https://www.destiny.gg/api/chat/me"
    private let logOutEndpoint = "https://www.destiny.gg/logout"
    private let streamEndpoint = "https://www.destiny.gg/api/info/stream"
    private let messagesEndpoint = "https://www.destiny.gg/api/messages/inbox"
    private let userMessageEndpoint = "https://www.destiny.gg/api/messages/usr/%@/inbox"
    private let messageOpenEndpoint = "https://www.destiny.gg/api/messages/msg/%@/open"
    private let pingEndpoint = "https://www.destiny.gg/ping"
    private let overrustleBaseEndpoint = "https://overrustlelogs.net/"
    private let overrustleMonthsEndpoint = "https://overrustlelogs.net/Destinygg%20chatlog/"
    private let streamStatusEndpoint = "https://www.destiny.gg/api/info/stream"
    private let saveSettingsEndpoint = "https://www.destiny.gg/api/chat/me/settings"
    
    var flairListBackoff = 100
    var emoteListBackoff = 100
    
    var totalEmotes: Int?
    var totalBBDGGEmotes: Int?
    

    var backgroundSessionManager: SessionManager?
    var activeSessionManager: SessionManager?
    
    init() {
        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: "me.polecat.app.background")
        backgroundConfiguration.timeoutIntervalForRequest = 2
        backgroundConfiguration.timeoutIntervalForResource = 2
        backgroundSessionManager = Alamofire.SessionManager(configuration: backgroundConfiguration)
        
        let activeConfiguration = URLSessionConfiguration.default
        activeConfiguration.timeoutIntervalForRequest = 1
        activeConfiguration.timeoutIntervalForResource = 1
        activeSessionManager = Alamofire.SessionManager(configuration: activeConfiguration)
    }
    
    
    func getFlairList() {
        activeSessionManager!.request(flairEndpoint, method: .get).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                print("got flairs")
                for (_, flairJson) in json {
                    self.downloadFlair(json: flairJson)
                }
                self.flairs.append(Flair.init(name: "polecat", label: "App Only Cute Label", color: "e463cf", hidden: false, priority: 0, image: UIImage(named: "cherry")!, height: 18, width: 18))
            case .failure(let error):
                print(error)
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(self.flairListBackoff), execute: {
                    self.flairListBackoff = self.flairListBackoff * 2
                    self.getFlairList()
                })
            }
        }
    }
    
    func getEmoteList(completionHandler: @escaping () -> Void) {
        activeSessionManager!.request(emoteEndpoint, method: .get).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                print("got emotes")
                self.totalEmotes = json.arrayValue.count
                for (_, emoteJosn) in json {
                    self.downloadEmote(json: emoteJosn, completionHandler: completionHandler)
                }
                completionHandler()
            case .failure(let error):
                print(error)
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(self.emoteListBackoff), execute: {
                    self.emoteListBackoff = self.emoteListBackoff * 2
                    self.getEmoteList(completionHandler: completionHandler)
                })
            }
        }
    }
    
    func getBBDGGEmoteList(completionHandler: @escaping () -> Void) {
        activeSessionManager!.request(bbdggEmoteEndpoint, method: .get).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                self.totalBBDGGEmotes = json.arrayValue.count
                for (_, emoteJosn) in json {
                    self.downloadEmote(json: emoteJosn, completionHandler: completionHandler)
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
    
    func ping() {
        let headers: HTTPHeaders = [
            "Cookie": getCookieString(),
        ]
        backgroundSessionManager?.request(pingEndpoint, headers: headers).validate().response { response in
            print("Ping " + String(response.response?.statusCode ?? 999))
        }
    }
    
    func getStreamStatus(completionHandler: @escaping  (StreamStatus?) -> Void) {
        backgroundSessionManager!.request(streamStatusEndpoint).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                guard let live = json["live"].bool else {
                    completionHandler(nil)
                    return
                }
                
                if let host = json["host"]["name"].string {
                    completionHandler(.Hosting(stream: host))
                    return
                }
                
                if live {
                    completionHandler(.Live)
                } else {
                    completionHandler(.Offline)
                }
            case .failure(let error):
                print(error)
                completionHandler(nil)
            }
        }
    }
    
    func checkForNewCookies() {
        for cookie in HTTPCookieStorage.shared.cookies! {
            if cookie.domain == ".www.destiny.gg"  {
                if cookie.name == "sid" {
                    if cookie.value != settings.dggCookie {
                        print("New session cookie found")
                        settings.dggCookie = cookie.value
                    }
                }
                
                if cookie.name == "rememberme" {
                    if cookie.value != settings.dggRememberCookie {
                        print("New rememberme cookie found")
                        settings.dggRememberCookie = cookie.value
                    }
                }
            }
        }
    }
    
    func getUserSettings(initalSync: Bool = false) {
        let headers: HTTPHeaders = [
            "Cookie": getCookieString(),
        ]

        activeSessionManager!.request(userInfoEndpoint, headers: headers).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                print("got user settings")
                self.checkForNewCookies()
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
                if dggSettings.count == 0 {
                    settings.syncSettings = false
                } else {
                    settings.parseDGGUserSettings(json: dggSettings, initialSync: true)
                }
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
    
    func logOut() {
        let headers: HTTPHeaders = [
            "Cookie": getCookieString(),
        ]
        
        backgroundSessionManager!.request(logOutEndpoint, headers: headers).validate().response { response in}
    }
    
    func getMessages(completionHandler: @escaping  ([MessageListing]?) -> Void) {
        let headers: HTTPHeaders = [
            "Cookie": getCookieString(),
        ]
        
        backgroundSessionManager!.request(messagesEndpoint, method: .get, headers: headers).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                var messages = [MessageListing]()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")

                for entry in json.arrayValue {
                    guard let timestamp = entry["timestamp"].string else {
                        continue
                    }
                    
                    guard let date = dateFormatter.date(from: timestamp) else {
                        print("error parsing date stamp")
                        continue
                    }
                    
                    guard let nick = entry["user"].string else {
                        continue
                    }
                    
                    guard let unread = entry["unread"].string else {
                        continue
                    }
                    
                    guard let read = entry["read"].string else {
                        continue
                    }
                    
                    guard let readInt = Int(read) else {
                        continue
                    }
                    
                    guard let unreadInt = Int(unread) else {
                        continue
                    }
                    
                    guard let message = entry["message"].string else {
                        continue
                    }
                    
                    messages.append(MessageListing(timestamp: date, user: nick, unread: unreadInt, read: readInt, message: message))
                }
                completionHandler(messages)
            case .failure(let error):
                print(error)
                completionHandler(nil)
            }
        }
    }
    
    func getUserMessages(user: String, completionHandler: @escaping  ([PrivateMessage]?) -> Void) {
        let headers: HTTPHeaders = [
            "Cookie": getCookieString(),
        ]

        let url = String(format: userMessageEndpoint, user)
        activeSessionManager!.request(url, method: .get, headers: headers).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                var messages = [PrivateMessage]()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                
                for entry in json.arrayValue {
                    guard let timestamp = entry["timestamp"].string else {
                        continue
                    }
                    
                    guard let date = dateFormatter.date(from: timestamp) else {
                        print("error parsing date stamp")
                        continue
                    }
                    
                    guard let from = entry["from"].string else {
                        continue
                    }
                    
                    guard let to = entry["to"].string else {
                        continue
                    }
                    
                    guard let message = entry["message"].string else {
                        continue
                    }
                    
                    messages.append(PrivateMessage(message: message, timestamp: date, from: from, to: to))
                }
                completionHandler(messages)
            case .failure(let error):
                print(error)
                completionHandler(nil)
            }
        }
    }
    
    func markMessageAsOpen(id: Int) {
        let headers: HTTPHeaders = [
            "Cookie": getCookieString(),
        ]
        
        let url = String(format: messageOpenEndpoint, String(id))
        backgroundSessionManager!.request(url, method: .post, headers: headers).validate().response { response in
            print("Open " + String(response.response?.statusCode ?? 999))
        }
    }
    
    func saveSettings() {
        var request = URLRequest(url: URL(string: saveSettingsEndpoint)!)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue(getCookieString(), forHTTPHeaderField: "Cookie")
        guard let json = settings.getDGGSettingJSON() else {
            return
        }
        
        do {
            request.httpBody = try JSON(json).rawData()
        } catch let error {
            print(error)
            return
        }
        
        backgroundSessionManager!.request(request).validate().response { response in
            print("save " + String(response.response?.statusCode ?? 999))
        }
    }
    
    func getMonthLogs(completionHandler: @escaping ([LogListing]?) -> Void) {
        getOverrustleLogs(url: overrustleMonthsEndpoint, completionHandler: completionHandler)
    }
    
    func getDaysLogs(for monthURL: String, completionHandler: @escaping ([LogListing]?) -> Void) {
        let url = overrustleBaseEndpoint + monthURL
        getOverrustleLogs(url: url, completionHandler: completionHandler)
    }
    
    func getUserListLogs(for userURL: String, completionHandler: @escaping ([LogListing]?) -> Void) {
        let url = overrustleBaseEndpoint + userURL
        getOverrustleLogs(url: url, completionHandler: completionHandler)
    }
    
    func getUserLogs(for userURL: String, completionHandler: @escaping ([String]?) -> Void) {
        let url = overrustleBaseEndpoint + userURL.replacingOccurrences(of: " ", with: "%20") + ".txt"
        backgroundSessionManager!.request(url).responseString { response in
            guard let text = response.result.value else {
                completionHandler(nil)
                return
            }
            
            let lines = text.split(separator: ("\n"))
            var strings = [String]()
            for line in lines {
                strings.append(String(line))
            }
            completionHandler(strings)
        }
    }
    
    private func downloadEmote(json: JSON, completionHandler: @escaping () -> Void) {
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
                if self.emotes.count == ((self.totalEmotes ?? 0) + (self.totalBBDGGEmotes ?? 0)) {
                    completionHandler()
                }
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
    
    private func getCookieString() -> String {
        var output = "sid=" + settings.dggCookie
        if settings.dggRememberCookie != "" {
            output += "; rememberme=" + settings.dggRememberCookie
        }
        
        return output
    }
    
    private func getOverrustleLogs(url: String, completionHandler: @escaping ([LogListing]?) -> Void) {
        let escapedURL = url.replacingOccurrences(of: " ", with: "%20")
        Alamofire.request(escapedURL).responseString { response in
            guard let html = response.result.value else {
                completionHandler(nil)
                return
            }
            
            do {
                let doc: Document = try SwiftSoup.parse(html)
                let list: Element = try doc.select(".list-group").first()!
                
                var listings = [LogListing]()
                for item in list.children() {
                    let title = try item.text()
                    let url = try item.attr("href")
                    let classes = try item.select("i").first()!.className()
                    var isFolder = false
                    if classes.contains("fa-folder") {
                        isFolder = true
                    } else if classes.contains("fa-file") {
                        isFolder = false
                    } else {
                        print("Unknown item parsed")
                        continue
                    }
                    listings.append(LogListing(isFolder: isFolder, title: title, urlComponent: url))
                }
                
                completionHandler(listings)
            } catch Exception.Error(_, let message) {
                print(message)
                completionHandler(nil)
            } catch {
                print("error")
                completionHandler(nil)
            }
        }
    }
    
    
    private func showAuthenticationSuccess() {
//        let banner = NotificationBanner(title: "Authentication Succeful", subtitle: "Authenticated as " + settings.dggUsername, style: .success)
//        banner.show()
    }
}

enum StreamStatus {
    case Live
    case Offline
    case Hosting(stream: String)
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

public struct MessageListing {
    let timestamp: Date
    let user: String
    let unread: Int
    let read: Int
    let message: String
}

public struct PrivateMessage {
    let message: String
    let timestamp: Date
    let from: String
    let to: String
}

public struct LogListing{
    let isFolder: Bool
    let title: String
    let urlComponent: String
}
