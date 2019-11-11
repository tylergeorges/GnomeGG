//
//  ToolsViewController.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/3/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit

class ToolsViewController: UIViewController {
    
    @IBOutlet weak var mentionsButton: UIButton!

    let twitch = "https://www.twitch.tv/destiny"
    let youtube = "https://www.youtube.com/user/Destiny"
    let reddit = "https://www.reddit.com/r/Destiny/"
    let discord = "https://www.destiny.gg/discord"
    let instagram = "https://www.instagram.com/destiny/"

    @IBOutlet weak var yeeImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        let random = Int.random(in: 0 ..< 20)
        yeeImageView.isHidden = random != 0
        
        mentionsButton.isEnabled = settings.dggUsername != ""
    }

    
    @IBAction func twitchTap(_ sender: Any) {
        UIApplication.shared.open(URL(string: twitch)!)
    }

    @IBAction func youtubeTap(_ sender: Any) {
        UIApplication.shared.open(URL(string: youtube)!)
    }

    @IBAction func redditTap(_ sender: Any) {
        UIApplication.shared.open(URL(string: reddit)!)
    }

    @IBAction func discordTap(_ sender: Any) {
        UIApplication.shared.open(URL(string: discord)!)
    }

    @IBAction func instagramTap(_ sender: Any) {
        UIApplication.shared.open(URL(string: instagram)!)
    }
}
