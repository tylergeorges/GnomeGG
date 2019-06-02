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
    
    
    let defaults = UserDefaults.standard
    
    // Key constants to use for settings storage
    struct DefaultKeys {
        static let loginKey = "loginKey"
        static let notifications = "notifications"
        static let dggAccessToken = "dggAccessToken"
        static let dggRefreshToken = "dggRefreshToken"
        static let dggUsername = "dggUsername"
        static let stalkHistory = "stalkHistory"
    }
    
    // Default values
    struct DefaultSettings {
        static let loginKey = ""
        static let notifications = false
        static let dggAccessToken = ""
        static let dggRefreshToken = ""
        static let dggUsername = ""
        static let stalkHistory = [StalkRecord]()
    }
    
    init() {
        
        if defaults.object(forKey: DefaultKeys.notifications) != nil {
            notifications = defaults.bool(forKey: DefaultKeys.notifications)
        } else {
            notifications = DefaultSettings.notifications
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
        
    }
}
