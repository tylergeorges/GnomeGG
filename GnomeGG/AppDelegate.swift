//
//  AppDelegate.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 5/30/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey  : Any] = [:]) -> Bool {
        guard let host = url.host else {
            return true
        }
        
        print(url.absoluteString)
        
        guard host == "oauth" else {
            return true
        }

        guard let parameters = url.queryParameters else {
            return true
        }
        
        guard let code = parameters["code"] else {
            return true
        }
        
        guard let state = parameters["state"] else {
            return true
        }
        
        guard var topController = UIApplication.shared.keyWindow?.rootViewController else  {
            return true
        }

        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
            
        
        if let settingsViewController = topController as? SettingsViewController {
            settingsViewController.receivedOauthCode(code: code, state: state)
            return true
        }
        
        if let loginViewController = topController as? LoginViewController {
            loginViewController.receivedOauthCode(code: code, state: state)
            return true
        }
        
        
        
        return true
    }
}

let settings = Settings()
let dggAPI = DGGAPI()

extension URL {
    public var queryParameters: [String: String]? {
        guard
            let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else { return nil }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }
}
