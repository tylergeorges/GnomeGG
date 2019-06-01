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

class SettingsViewController: UIViewController {

    @IBOutlet weak var authWithDggButton: UIButton!
    @IBOutlet weak var setUsernameButton: UIButton!
    @IBOutlet weak var loggedInAsLabel: UILabel!
    @IBOutlet weak var resetUsernameButton: UIButton!
    @IBOutlet weak var rateTheAppButton: UIButton!
    @IBOutlet weak var doneBarButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateUI()
        
    }
    
    func receivedOauthCode(code: String, state: String) {
        dggAPI.getOauthToken(state: state, code: code, completion: {
            self.updateUI()
        })
    }
    
    
    
    private func updateUI() {
        if settings.dggUsername != "" {
            authWithDggButton.isHidden = true
            setUsernameButton.isHidden = true
            loggedInAsLabel.isHidden = false
            loggedInAsLabel.text = "Logged in as: " + settings.dggUsername
            resetUsernameButton.isHidden = false
        } else {
            authWithDggButton.isHidden = false
            setUsernameButton.isHidden = false
            loggedInAsLabel.isHidden = true
            loggedInAsLabel.text = "Logged in as: " + settings.dggUsername
            resetUsernameButton.isHidden = true
        }
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
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
    }
    @IBAction func twitterButtonTap(_ sender: Any) {
    }
    @IBAction func githubButtonTap(_ sender: Any) {
    }
    
}
