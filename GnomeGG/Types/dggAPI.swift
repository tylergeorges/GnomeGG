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

class DGGAPI {
    var flairs = [Flair]()
    var emotes = [Emote]()
    
    let flairEndpoint = "https://cdn.destiny.gg/4.2.0/flairs/flairs.json"
    let emoteEndpoint = "https://cdn.destiny.gg/4.2.0/emotes/emotes.json"
    let historyEndpoint = "https://www.destiny.gg/api/chat/history"
    let dggOauthURL = "https://www.destiny.gg/oauth/authorize"
    let dggTokenURL = "https://www.destiny.gg/oauth/token"
    let userInfoURL = "https://destiny.gg/api/userinfo"
    let clientID = "3YMN8kbRgCbPWW2l2dJzoD5kzCIv8SQa"
    let redirectURL = "gnome-gg://oauth/authorize"
    let codeVerifier = "jjEJi7X1CNrqvmfKMQzYXfNqR647cz6DEWpLmYMtDELDqQWclDoYMUwDKqas"
    let codeChallenge = "M2Y0N2ZiMTQxNTU3ZmY2NDIyNDI0OTc3ZDA1NTY4MWMyM2UwYTJiZGMzZWVhZGQ4MDk3NTQ0MGIxMDk1ZjIxNg=="
    var state: String?
    
    func getFlairList() {

        Alamofire.request(flairEndpoint, method: .get).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                for (_, flairJson) in json {
                    self.downloadFlair(json: flairJson)
                }
                
                self.flairs.append(Flair.init(name: "polecat", color: "e463cf", hidden: false, priority: 0, image: UIImage(named: "cherry")!, height: 18, width: 18))
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func getEmoteList() {
        Alamofire.request(emoteEndpoint, method: .get).validate().responseJSON { response in
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
        Alamofire.request(historyEndpoint, method: .get).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                let messages = json.arrayValue.map {$0.stringValue}
                completionHandler(messages)
            case .failure(let error):
                print(error)
                completionHandler([String]())
            }
        }
    }
    
    func getUserInfo(completionHandler: @escaping () -> Void) {
        guard let url = getUserInfoURL() else {
            return
        }
        
        Alamofire.request(url, method: .get).validate().responseJSON { response in
            if response.response?.statusCode == 403 {
                self.refreshAccessToken()
            }
            
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                
                guard let nick = json["nick"].string else {
                    // error authenticating
                    settings.dggUsername = ""
                    completionHandler()
                    return
                }
                
                settings.dggUsername = nick
                completionHandler()
                
                
            case .failure(let error):
                print(error)
                completionHandler()
            }
        }
        
    }
    
    func refreshAccessToken() {
        if settings.dggRefreshToken == "" {
            settings.dggUsername = ""
            return
        }
        
        guard let url = getRefreshURL() else {
            oauthFailed(reason: "Error Generating Refresh URL")
            return
        }
        
        Alamofire.request(url, method: .get).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                
                guard let accessToken = json["access_token"].string else {
                    self.oauthFailed(reason: "Access Token Not Found")
                    return
                }
                
                settings.dggAccessToken = accessToken
                print("got dgg access token")
                
                guard let refreshToken = json["refresh_token"].string else {
                    self.oauthFailed(reason: "Refresh Token Not Found")
                    return
                }
                
                settings.dggRefreshToken = refreshToken
                
                
            case .failure(let error):
                self.oauthFailed(reason: "Error Getting Access Token")
            }
        }
    }
    
    func getOauthToken(state: String, code: String, completion: @escaping () -> Void) {
        guard state == self.state! else {
            print("states don't match")
            // ERROR
            return
        }
        
        guard let tokenURL = getTokenURL(code: code) else {
            print("error making token url")
            // ERROR
            return
        }
        
        Alamofire.request(tokenURL, method: .get).validate().responseJSON { response in
            if response.response?.statusCode == 403 {
                self.refreshAccessToken()
            }
            
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                
                guard let accessToken = json["access_token"].string else {
                    return
                }
                
                settings.dggAccessToken = accessToken
                dggAPI.getUserInfo(completionHandler: completion)
                
                guard let refreshToken = json["refresh_token"].string else {
                    // error
                    return
                }
                
                settings.dggRefreshToken = refreshToken
                
                
            case .failure(let error):
                // error
                return
            }
        }
    }
    
    private func oauthFailed(reason: String) {
        print("Oauth failed with reason " + reason)
    }
    
    func getOauthURL() -> URL? {
        var components = URLComponents(string: dggOauthURL)
        
        var queries = [URLQueryItem]()
        queries.append(URLQueryItem(name: "response_type", value: "code"))
        queries.append(URLQueryItem(name: "client_id", value: clientID))
        queries.append(URLQueryItem(name: "redirect_uri", value: redirectURL))
        state = randomString(length: 30)
        queries.append(URLQueryItem(name: "state", value: state!))
        queries.append(URLQueryItem(name: "code_challenge", value: codeChallenge))
        
        
        components?.queryItems = queries
        return components?.url
    }
    
    private func getRefreshURL() -> URL? {
        var components = URLComponents(string: dggTokenURL)
        
        var queries = [URLQueryItem]()
        queries.append(URLQueryItem(name: "grant_type", value: "refresh_token"))
        queries.append(URLQueryItem(name: "client_id", value: clientID))
        queries.append(URLQueryItem(name: "refresh_token", value: settings.dggRefreshToken))
        
        components?.queryItems = queries
        return components?.url
    }
    
    func getTokenURL(code: String) -> URL? {
        var components = URLComponents(string: dggTokenURL)
        
        var queries = [URLQueryItem]()
        queries.append(URLQueryItem(name: "grant_type", value: "authorization_code"))
        queries.append(URLQueryItem(name: "code", value: code))
        queries.append(URLQueryItem(name: "client_id", value: clientID))
        queries.append(URLQueryItem(name: "redirect_uri", value: redirectURL))
        queries.append(URLQueryItem(name: "code_verifier", value: codeVerifier))
        
        components?.queryItems = queries
        return components?.url
    }
    
    private func getUserInfoURL() -> URL? {
        var components = URLComponents(string: userInfoURL)
        
        var queries = [URLQueryItem]()
        guard settings.dggAccessToken != "" else {
            return nil
        }

        queries.append(URLQueryItem(name: "token", value: settings.dggAccessToken))
        
        components?.queryItems = queries
        return components?.url
    }
    
    private func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
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
        
        getData(from: URL(string: url)!) { data, response, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async() {
                guard let image = UIImage(data: data) else {
                    print("error downloading image")
                    return
                }
                self.emotes.append(Emote.init(prefix: prefix, twitch: isTwitch, image: image, height: height, width: width))
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
        
        getData(from: URL(string: url)!) { data, response, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async() {
                guard let image = UIImage(data: data) else {
                    print("error downloading image")
                    return
                }
                self.flairs.append(Flair.init(name: name, color: color, hidden: hidden, priority: priority, image: image, height: height, width: width))
            }
        }
    }
    
    private func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
}

struct Flair {
    let name: String
    let color: String
    let hidden: Bool
    let priority: Int
    let image: UIImage
    let height: Int
    let width: Int
}

struct Emote {
    let prefix: String
    let twitch: Bool
    let image: UIImage
    let height: Int
    let width: Int
}

struct User {
    let nick: String
    let features: [String]
}
