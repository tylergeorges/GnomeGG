//
//  TestViewController.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/6/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit
import WebKit
import Alamofire
import SwiftyJSON

class LoginViewController: UIViewController, WKNavigationDelegate {

    let loginURL = "https://www.destiny.gg/login"
    let authURL = "https://www.destiny.gg/auth/"
    
    @IBOutlet weak var loginWebview: WKWebView!
    @IBOutlet weak var authStackView: UIStackView!
    @IBOutlet weak var choseSignInLabel: UILabel!
    @IBOutlet weak var cookieLabel: UILabel!
    @IBOutlet weak var rememberMeSwitch: UISwitch!
    @IBOutlet weak var rememberMeView: UIView!
    @IBOutlet weak var cookieImage: UIImageView!
    
    var tempCookie = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginWebview.isHidden = true
        choseSignInLabel.isHidden = false
        authStackView.isHidden = false
        rememberMeView.isHidden = false
        cookieLabel.isHidden = true
        cookieImage.isHidden = true

        loginWebview.navigationDelegate = self
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {

        if (decidePolicyFor.request.url!.absoluteString.starts(with: authURL)) {
            decisionHandler(.cancel)

            loginWebview.isHidden = true
            cookieImage.isHidden = false
            cookieLabel.isHidden = false

            Alamofire.request(decidePolicyFor.request.url!, method: .get).validate().response { response in
                var sessionID: String?
                var rememberMe: String?

                for cookie in HTTPCookieStorage.shared.cookies! {
                    if cookie.domain == ".www.destiny.gg"  {
                        if cookie.name == "sid" {
                            sessionID = cookie.value
                        }
                        
                        if cookie.name == "rememberme" {
                            rememberMe = cookie.value
                        }
                    }
                }
                        
                if self.rememberMeSwitch.isOn && rememberMe == nil {
                    print("expected a remember me cookie but it was not found")
                }
                
                guard let sid = sessionID else {
                    print("Session id cookie not returned")
                    return
                }
                
                settings.dggCookie = sid
                
                if let rememberCookie = rememberMe {
                    settings.dggRememberCookie = rememberCookie
                }
                
                self.cookieLabel.text = "Getting Your Information"
                dggAPI.getUserSettings()
                self.dismiss(animated: true, completion: nil)
            }
        } else {
            decisionHandler(.allow)
        }
    }
    
    private func logIn(with provider: String) {
        authStackView.isHidden = true
        choseSignInLabel.isHidden = true
        rememberMeView.isHidden = true
        
        var parameters: Parameters = ["authProvider": provider]
        
        if rememberMeSwitch.isOn {
            parameters["rememberme"] = "on"
        }

        Alamofire.request(loginURL, method: .post, parameters: parameters).validate().response { response in
            self.loginWebview.isHidden = false
            self.loginWebview.load(URLRequest(url: response.response!.url!))
        }
    }
    
    @IBAction func cancelTap(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func twitchTap(_ sender: Any) {
        logIn(with: "twitch")
    }
    @IBAction func googleTap(_ sender: Any) {
        logIn(with: "google")
    }
    @IBAction func twitterTap(_ sender: Any) {
        logIn(with: "twitter")
    }
    @IBAction func redditTap(_ sender: Any) {
        logIn(with: "reddit")
    }
    @IBAction func discordTap(_ sender: Any) {
        logIn(with: "discord")
    }
    
}
