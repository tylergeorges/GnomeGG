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
    
    // App settings
    var notifications: Bool {
        didSet {
            defaults.set(notifications, forKey: DefaultKeys.notifications)
        }
    }
    
    // todo
    var syncSettings: Bool {
        didSet {
            defaults.set(syncSettings, forKey: DefaultKeys.syncSettings)
        }
    }
    
    var stalkHistory: [StringRecord] {
        didSet {
            do {
                let encodedData: Data = try NSKeyedArchiver.archivedData(withRootObject: stalkHistory, requiringSecureCoding: false)
                defaults.set(encodedData, forKey: DefaultKeys.stalkHistory)
            } catch let error {
                print(error)
            }
        }
    }
    
    var lookupHistory: [StringRecord] {
        didSet {
            do {
                let encodedData: Data = try NSKeyedArchiver.archivedData(withRootObject: lookupHistory, requiringSecureCoding: false)
                defaults.set(encodedData, forKey: DefaultKeys.lookupHistory)
            } catch let error {
                print(error)
            }
        }
    }
    
    var bbdggEmotes: Bool {
        didSet {
            defaults.set(bbdggEmotes, forKey: DefaultKeys.bbdggEmotes)
        }
    }
    
    // DGG settings
    
    var dggUsername: String {
        didSet {
            defaults.set(dggUsername, forKey: DefaultKeys.dggUsername)
        }
    }
    
    var dggCookie: String {
        didSet {
            defaults.set(dggCookie, forKey: DefaultKeys.dggCookie)
        }
    }
    
    var dggRememberCookie: String {
        didSet {
            defaults.set(dggRememberCookie, forKey: DefaultKeys.dggRememberCookie)
        }
    }
    
    var showTime: Bool {
        didSet {
            defaults.set(showTime, forKey: DefaultKeys.showTime)
        }
    }
    
    var hideFlairs: Bool {
        didSet {
            defaults.set(hideFlairs, forKey: DefaultKeys.hideFlairs)
        }
    }
    
    var nickHighlights: [String] {
        didSet {
            do {
                let encodedData: Data = try NSKeyedArchiver.archivedData(withRootObject: nickHighlights, requiringSecureCoding: false)
                defaults.set(encodedData, forKey: DefaultKeys.nickHighlights)
            } catch let error {
                print(error)
            }
        }
    }

    var showWhispersInChat: Bool {
        didSet {
            defaults.set(showWhispersInChat, forKey: DefaultKeys.showWhispersInChat)
        }
    }
    
    var autoCompletion: Bool {
        didSet {
            defaults.set(autoCompletion, forKey: DefaultKeys.autoCompletion)
        }
    }
    
    var hideNSFW: Bool {
        didSet {
            defaults.set(hideNSFW, forKey: DefaultKeys.hideNSFW)
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
    
    var dggUserSettings: [JSON]?
    
    
    let defaults = UserDefaults.standard
    
    // Key constants to use for settings storage
    struct DefaultKeys {
        static let notifications = "notifications"
        static let syncSettings = "syncSettings"
        static let dggUsername = "dggUsername"
        static let stalkHistory = "stalkHistory"
        static let usernameHighlights = "highlight"
        static let customHighlights = "customhighlight"
        static let ignoredUsers = "ignorenicks"
        static let userTags = "taggednicks"
        static let harshIgnore = "ignorementions"
        static let lookupHistory = "lookupHistory"
        static let bbdggEmotes = "bbdggEmotes"
        static let dggCookie = "dggCookie"
        static let dggRememberCookie = "dggRememberCookie"
        static let showTime = "showtime"
        static let hideFlairs = "hideflairicons"
        static let nickHighlights = "highlightnicks"
        static let showWhispersInChat = "showhispersinchat"
        static let autoCompletion = "autocompletehelper"
        static let hideNSFW = "hidensfw"
    }
    
    // Default values
    struct DefaultSettings {
        static let notifications = false
        static let syncSettings = true
        static let dggUsername = ""
        static let stalkHistory = [StringRecord(string: "Destiny", date: Date())]
        static let usernameHighlights = true
        static let customHighlights = [String]()
        static let ignoredUsers = [String]()
        static let userTags = [UserTag]()
        static let harshIgnore = false
        static let lookupHistory = [StringRecord]()
        static let bbdggEmotes = true
        static let dggCookie = ""
        static let dggRememberCookie = ""
        static let showTime = true
        static let hideFlairs = false
        static let nickHighlights = [String]()
        static let showWhispersInChat = true
        static let autoCompletion = true
        static let hideNSFW = false
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
        
        if defaults.object(forKey: DefaultKeys.syncSettings) != nil {
            syncSettings = defaults.bool(forKey: DefaultKeys.syncSettings)
        } else {
            syncSettings = DefaultSettings.syncSettings
        }
        
        if defaults.object(forKey: DefaultKeys.showTime) != nil {
            showTime = defaults.bool(forKey: DefaultKeys.showTime)
        } else {
            showTime = DefaultSettings.showTime
        }
        
        if defaults.object(forKey: DefaultKeys.hideFlairs) != nil {
            hideFlairs = defaults.bool(forKey: DefaultKeys.hideFlairs)
        } else {
            hideFlairs = DefaultSettings.hideFlairs
        }
        
        if defaults.object(forKey: DefaultKeys.showWhispersInChat) != nil {
            showWhispersInChat = defaults.bool(forKey: DefaultKeys.showWhispersInChat)
        } else {
            showWhispersInChat = DefaultSettings.showWhispersInChat
        }
        
        if defaults.object(forKey: DefaultKeys.autoCompletion) != nil {
            autoCompletion = defaults.bool(forKey: DefaultKeys.autoCompletion)
        } else {
            autoCompletion = DefaultSettings.autoCompletion
        }
        
        if defaults.object(forKey: DefaultKeys.hideNSFW) != nil {
            hideNSFW = defaults.bool(forKey: DefaultKeys.hideNSFW)
        } else {
            hideNSFW = DefaultSettings.hideNSFW
        }
        
        
        dggUsername = defaults.string(forKey: DefaultKeys.dggUsername) ?? DefaultSettings.dggUsername
        dggCookie = defaults.string(forKey: DefaultKeys.dggCookie) ?? DefaultSettings.dggCookie
        dggRememberCookie = defaults.string(forKey: DefaultKeys.dggRememberCookie) ?? DefaultSettings.dggRememberCookie
        
        let decodedStalkHistory  = defaults.data(forKey: DefaultKeys.stalkHistory)
        if let data = decodedStalkHistory {
            do {
                stalkHistory = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! [StringRecord]
            } catch let error {
                print(error)
                stalkHistory = DefaultSettings.stalkHistory
            }
        } else {
            print("error decoding stalk history")
            stalkHistory = DefaultSettings.stalkHistory
        }
        
        let decodedLookupHistory  = defaults.data(forKey: DefaultKeys.lookupHistory)
        if let data = decodedLookupHistory {
            do {
                lookupHistory = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! [StringRecord]
            } catch let error {
                print(error)
                lookupHistory = DefaultSettings.lookupHistory
            }
        } else {
            print("error decoding lookup history")
            lookupHistory = DefaultSettings.lookupHistory
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
        
        let nickHighlights = defaults.data(forKey: DefaultKeys.nickHighlights)
        if let data = nickHighlights {
            do {
                self.nickHighlights = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! [String]
            } catch let error {
                print(error)
                self.nickHighlights = DefaultSettings.nickHighlights
            }
        } else {
            self.nickHighlights = DefaultSettings.nickHighlights
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
        
        if defaults.object(forKey: DefaultKeys.bbdggEmotes) != nil {
            bbdggEmotes = defaults.bool(forKey: DefaultKeys.bbdggEmotes)
        } else {
            bbdggEmotes = DefaultSettings.bbdggEmotes
        }
    }
    
    func reset() {
        dggAPI.logOut()
        dggUsername = DefaultSettings.dggUsername
        dggCookie = DefaultSettings.dggCookie
        
        showTime = DefaultSettings.showTime
        hideFlairs = DefaultSettings.hideFlairs
        usernameHighlights = DefaultSettings.usernameHighlights
        customHighlights = DefaultSettings.customHighlights
        nickHighlights = DefaultSettings.nickHighlights
        userTags = DefaultSettings.userTags
        showWhispersInChat = DefaultSettings.showWhispersInChat
        ignoredUsers = DefaultSettings.ignoredUsers
        autoCompletion = DefaultSettings.autoCompletion
        hideNSFW = DefaultSettings.hideNSFW
        harshIgnore = DefaultSettings.harshIgnore
    }
    
    func parseDGGUserSettings(json: [JSON]) {
        dggUserSettings = json
        for setting in json {
            switch setting.arrayValue[0].stringValue {
            case DefaultKeys.showTime:
                if let bool = setting[1].bool {
                    showTime = bool
                }
            case DefaultKeys.hideFlairs:
                if let bool = setting[1].bool {
                    hideFlairs = bool
                }
            case DefaultKeys.usernameHighlights:
                if let bool = setting[1].bool {
                    usernameHighlights = bool
                }
            case DefaultKeys.customHighlights: customHighlights = setting[1].arrayValue.map {$0.stringValue}
            case DefaultKeys.nickHighlights: nickHighlights = setting[1].arrayValue.map {$0.stringValue}
            case DefaultKeys.userTags: userTags = parseUserTags(blob: setting[1])
            case DefaultKeys.showWhispersInChat:
                if let bool = setting[1].bool {
                    showWhispersInChat = bool
                }
            case DefaultKeys.ignoredUsers: ignoredUsers = setting[1].arrayValue.map {$0.stringValue}
            case DefaultKeys.autoCompletion:
                if let bool = setting[1].bool {
                    autoCompletion = bool
                }
            case DefaultKeys.hideNSFW:
                if let bool = setting[1].bool {
                    hideNSFW = bool
                }
            case DefaultKeys.harshIgnore:
                if let bool = setting[1].bool {
                    harshIgnore = bool
                }
            default: break
            }
        }
    }
    
    func getDGGSettingJSON() -> [JSON]? {
        guard let json = dggUserSettings else {
            return nil
        }

        for var setting in json {
            switch setting.arrayValue[0].stringValue {
            case DefaultKeys.showTime: setting[1].bool = showTime
            case DefaultKeys.hideFlairs: setting[1].bool = hideFlairs
            case DefaultKeys.usernameHighlights: setting[1].bool = usernameHighlights
            case DefaultKeys.customHighlights: setting[1].arrayObject = customHighlights
            case DefaultKeys.nickHighlights: setting[1].arrayObject = nickHighlights
            case DefaultKeys.userTags: setting[1] = userTagsToJSON()
            case DefaultKeys.showWhispersInChat: setting[1].bool = showWhispersInChat
            case DefaultKeys.ignoredUsers: setting[1].arrayObject = ignoredUsers
            case DefaultKeys.autoCompletion: setting[1].bool = autoCompletion
            case DefaultKeys.hideNSFW: setting[1].bool = hideNSFW
            case DefaultKeys.harshIgnore:  setting[1].bool = harshIgnore
            default: break
            }
        }
        
        return json
    }
    
    private func parseUserTags(blob: JSON) -> [UserTag] {
        var userTags = [UserTag]()
        
        for tag in blob.arrayValue {
            let tagArr = tag.arrayValue
            guard tagArr.count == 2 else {
                continue
            }
            
            userTags.append(UserTag(nick: tagArr[0].stringValue, color: tagArr[1].stringValue.lowercased()))
        }
        
        return userTags
    }
    
    private func userTagsToJSON() -> JSON {
        var jsonArray = [[String]]()
        for tag in userTags {
            var tagArray = [String]()
            tagArray.append(tag.nick)
            tagArray.append(tag.color)
            jsonArray.append(tagArray)
        }
        
        return JSON(arrayLiteral: jsonArray)
    }
}
