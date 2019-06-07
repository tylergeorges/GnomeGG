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
    
    @IBOutlet weak var loginWebview: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loginWebview.navigationDelegate = self
        let loginRequest = URLRequest(url: URL(string: loginURL)!)
        loginWebview.load(loginRequest)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        if (decidePolicyFor.request.url!.absoluteString.starts(with: "https://www.destiny.gg/auth/")) {
            decisionHandler(.cancel)
            loginWebview.isHidden = true
            Alamofire.request(decidePolicyFor.request.url!, method: .get).validate().response { response in
                for cookie in HTTPCookieStorage.shared.cookies! {
                    if cookie.domain == ".www.destiny.gg" && cookie.name == "sid" {
                        settings.dggCookie = cookie.value
                        // todo update label to mention getting settings
                        dggAPI.getUserSettings()
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        } else {
            decisionHandler(.allow)
        }
    }
    
    @IBAction func cancelTap(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    

}
