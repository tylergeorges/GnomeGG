//
//  Settings.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/1/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import Foundation
import SwiftyJSON

class Settings {
    
    // MARK: Properties
    var notifications: Bool {
        didSet {
            defaults.set(notifications, forKey: DefaultKeys.notifications)
        }
    }
    
    var loginKey: String {
        didSet {
            defaults.set(loginKey, forKey: DefaultKeys.loginKey)
        }
    }
    
    var dggAccessToken: String {
        didSet {
            defaults.set(dggAccessToken, forKey: DefaultKeys.dggAccessToken)
        }
    }
    
    var dggRefreshToken: String {
        didSet {
            defaults.set(dggRefreshToken, forKey: DefaultKeys.dggRefreshToken)
        }
    }
    
    var dggUsername: String {
        didSet {
            defaults.set(dggUsername, forKey: DefaultKeys.dggUsername)
        }
    }
    
    var stalkHistory: [StalkRecord] {
        didSet {
            do {
                let encodedData: Data = try NSKeyedArchiver.archivedData(withRootObject: stalkHistory, requiringSecureCoding: false)
                defaults.set(encodedData, forKey: DefaultKeys.stalkHistory)
            } catch let error {
                print(error)
            }
        }
    }
    
    var customHighlights: [String] {
        didSet {
            do {
                let encodedData: Data = try NSKeyedArchiver.archivedData(withRootObject: customHighlights, requiringSecureCoding: false)
                defaults.set(encodedData, forKey: DefaultKeys.customHighlights)
            } catch let error {
                print(error)
            }
        }
    }
    
    var ignoredUsers: [String] {
        didSet {
            do {
                let encodedData: Data = try NSKeyedArchiver.archivedData(withRootObject: ignoredUsers, requiringSecureCoding: false)
                defaults.set(encodedData, forKey: DefaultKeys.ignoredUsers)
            } catch let error {
                print(error)
            }
        }
    }
    
    var userTags: [UserTag] {
        didSet {
            do {
                let encodedData: Data = try NSKeyedArchiver.archivedData(withRootObject: userTags, requiringSecureCoding: false)
                defaults.set(encodedData, forKey: DefaultKeys.userTags)
            } catch let error {
                print(error)
            }
        }
    }
    
    var usernameHighlights: Bool {
        didSet {
            defaults.set(usernameHighlights, forKey: DefaultKeys.usernameHighlights)
        }
    }
    
    var harshIgnore: Bool {
        didSet {
            defaults.set(harshIgnore, forKey: DefaultKeys.harshIgnore)
        }
    }
    
    
    let defaults = UserDefaults.standard
    
    // Key constants to use for settings storage
    struct DefaultKeys {
        static let loginKey = "loginKey"
        static let notifications = "notifications"
        static let dggAccessToken = "dggAccessToken"
        static let dggRefreshToken = "dggRefreshToken"
        static let dggUsername = "dggUsername"
        static let stalkHistory = "stalkHistory"
        static let usernameHighlights = "usernameHighlights"
        static let customHighlights = "customHighlights"
        static let ignoredUsers = "ignoredUsers"
        static let userTags = "userTags"
        static let harshIgnore = "harshIgnore"
    }
    
    // Default values
    struct DefaultSettings {
        static let loginKey = ""
        static let notifications = false
        static let dggAccessToken = ""
        static let dggRefreshToken = ""
        static let dggUsername = ""
        static let stalkHistory = [StalkRecord(nick: "Destiny", date: Date())]
        static let usernameHighlights = true
        static let customHighlights = [String]()
        static let ignoredUsers = [String]()
        static let userTags = [UserTag]()
        static let harshIgnore = false
    }
    
    init() {
        
        if defaults.object(forKey: DefaultKeys.notifications) != nil {
            notifications = defaults.bool(forKey: DefaultKeys.notifications)
        } else {
            notifications = DefaultSettings.notifications
        }
        
        if defaults.object(forKey: DefaultKeys.usernameHighlights) != nil {
            usernameHighlights = defaults.bool(forKey: DefaultKeys.usernameHighlights)
        } else {
            usernameHighlights = DefaultSettings.usernameHighlights
        }
        
        loginKey = defaults.string(forKey: DefaultKeys.loginKey) ?? DefaultSettings.loginKey
        dggAccessToken = defaults.string(forKey: DefaultKeys.dggAccessToken) ?? DefaultSettings.dggAccessToken
        dggRefreshToken = defaults.string(forKey: DefaultKeys.dggRefreshToken) ?? DefaultSettings.dggRefreshToken
        dggUsername = defaults.string(forKey: DefaultKeys.dggUsername) ?? DefaultSettings.dggUsername
        
        let decodedStalkHistory  = defaults.data(forKey: DefaultKeys.stalkHistory)
        if let data = decodedStalkHistory {
            do {
                stalkHistory = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! [StalkRecord]
            } catch let error {
                print(error)
                stalkHistory = DefaultSettings.stalkHistory
            }
        } else {
            print("error decoding stalk history")
            stalkHistory = DefaultSettings.stalkHistory
        }
        
        let customHighlights = defaults.data(forKey: DefaultKeys.customHighlights)
        if let data = customHighlights {
            do {
                self.customHighlights = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! [String]
            } catch let error {
                print(error)
                self.customHighlights = DefaultSettings.customHighlights
            }
        } else {
            self.customHighlights = DefaultSettings.customHighlights
        }
        
        let ignoredUsers = defaults.data(forKey: DefaultKeys.ignoredUsers)
        if let data = ignoredUsers {
            do {
                self.ignoredUsers = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! [String]
            } catch let error {
                print(error)
                self.ignoredUsers = DefaultSettings.ignoredUsers
            }
        } else {
            self.ignoredUsers = DefaultSettings.ignoredUsers
        }
        
        let userTags = defaults.data(forKey: DefaultKeys.userTags)
        if let data = userTags {
            do {
                self.userTags = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! [UserTag]
            } catch let error {
                print(error)
                self.userTags = DefaultSettings.userTags
            }
        } else {
            self.userTags = DefaultSettings.userTags
        }
        
        if defaults.object(forKey: DefaultKeys.harshIgnore) != nil {
            harshIgnore = defaults.bool(forKey: DefaultKeys.harshIgnore)
        } else {
            harshIgnore = DefaultSettings.harshIgnore
        }
    }
}
