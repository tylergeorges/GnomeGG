//
//  customTabBarController.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/2/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit

class CustomTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        selectedIndex = 1
        
        Timer.scheduledTimer(timeInterval: 5*60, target: self, selector: #selector(getUnreads), userInfo: nil, repeats: true)
        Timer.scheduledTimer(timeInterval: 10*60, target: self, selector: #selector(ping), userInfo: nil, repeats: true)
    }
    
    @objc
    private func getUnreads() {
        guard settings.dggCookie != "" else {
            return
        }
        
        guard selectedIndex != 3 else {
            return
        }
        
        print("checking for new messages")
        
        dggAPI.getMessages(completionHandler: {messages in
            var unreads = 0
            
            guard let messages = messages else {
                return
            }
            
            for message in messages {
                unreads += message.unread
            }
            
            if unreads > 0 {
                self.tabBar.items?[3].badgeValue = String(unreads)
            } else {
                self.tabBar.items?[3].badgeValue = nil
            }
            
        })
    }
    
    @objc
    private func ping() {
        dggAPI.ping()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
