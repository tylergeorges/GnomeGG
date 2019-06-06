//
//  SettingsViewController.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/1/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import StoreKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var authWithDggButton: UIButton!
    @IBOutlet weak var setUsernameButton: UIButton!
    @IBOutlet weak var loggedInAsLabel: UILabel!
    @IBOutlet weak var resetUsernameButton: UIButton!
    @IBOutlet weak var rateTheAppButton: UIButton!
    @IBOutlet weak var doneBarButton: UIBarButtonItem!
    @IBOutlet weak var gnomeImageView: UIImageView!
    @IBOutlet weak var authWIthDggHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var setUsernameHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var harshIgnoreSwitch: UISwitch!
    @IBOutlet weak var chatHighlightSwitch: UISwitch!
    @IBOutlet weak var bbdggEmotesSwitch: UISwitch!
    
    let twitter = "https://twitter.com/tehpolecat"
    let overrustle = "https://overrustlelogs.net/"
    let github = "https://github.com/voloshink/GnomeGG"
    let dggChat = "https://www.destiny.gg/"
    
    var heightConstraints: CGFloat?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let random = Int.random(in: 0 ..< 4)
        gnomeImageView.isHidden = random != 0
        
        harshIgnoreSwitch.isOn = settings.harshIgnore
        chatHighlightSwitch.isOn = settings.usernameHighlights
        bbdggEmotesSwitch.isOn = settings.bbdggEmotes
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        heightConstraints = setUsernameHeightConstraint.constant
        updateUI()
    }
    
    func receivedOauthCode(code: String, state: String) {
        dggAPI.getOauthToken(state: state, code: code, completion: {
            self.updateUI()
        })
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private func updateUI() {
        loggedInAsLabel.text = "Logged in as: " + settings.dggUsername
        if settings.dggUsername != "" {
            authWithDggButton.isHidden = true
            setUsernameButton.isHidden = true
            loggedInAsLabel.isHidden = false
            setUsernameHeightConstraint.constant = 0
            authWIthDggHeightConstraint.constant = 0
            resetUsernameButton.isHidden = false
        } else {
            authWithDggButton.isHidden = false
            setUsernameButton.isHidden = false
            loggedInAsLabel.isHidden = true
            setUsernameHeightConstraint.constant = heightConstraints!
            authWIthDggHeightConstraint.constant = heightConstraints!
            resetUsernameButton.isHidden = true
        }
        
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        
        if identifier == "manageIgnores" {
            let destvc = segue.destination as! StringSettingViewController
            destvc.setting = .Ignores
        }
        
        if identifier == "manageHighlights" {
            let destvc = segue.destination as! StringSettingViewController
            destvc.setting = .Highlights
        }
    }
    
    @IBAction func doneTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func dggAuthTap(_ sender: Any) {
        guard let url = dggAPI.getOauthURL() else { return }
        UIApplication.shared.open(url)
    }

    @IBAction func setUsernameTap(_ sender: Any) {
        let alert = UIAlertController(title: "Enter Your Username", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "DankGnome"
        })
        
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { action in
            
            if let key = alert.textFields?.first?.text {
                settings.dggUsername = key
                self.updateUI()
            }
        }))
        
        self.present(alert, animated: true)
    }

    @IBAction func resetUsernameTap(_ sender: Any) {
        settings.dggUsername = ""
        settings.dggAccessToken = ""
        settings.dggRefreshToken = ""
        updateUI()
    }
    @IBAction func rateTheAppTap(_ sender: Any) {
        if #available( iOS 10.3,*){
            SKStoreReviewController.requestReview()
        }
    }
    @IBAction func chatButtonTap(_ sender: Any) {
        UIApplication.shared.open(URL(string: dggChat)!)
    }
    @IBAction func twitterButtonTap(_ sender: Any) {
        UIApplication.shared.open(URL(string: twitter)!)
    }
    @IBAction func githubButtonTap(_ sender: Any) {
        UIApplication.shared.open(URL(string: github)!)
    }
    
    @IBAction func overrustleButtonTap(_ sender: Any) {
        UIApplication.shared.open(URL(string: overrustle)!)
    }
    @IBAction func harshIgnoreSwitch(_ sender: Any) {
        settings.harshIgnore = harshIgnoreSwitch.isOn
    }
    @IBAction func chatHighlightSwitch(_ sender: Any) {
        settings.usernameHighlights = chatHighlightSwitch.isOn
    }
    @IBAction func bbdggEmoteSwitch(_ sender: Any) {
        settings.bbdggEmotes = bbdggEmotesSwitch.isOn
    }
}
