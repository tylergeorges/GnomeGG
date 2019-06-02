//
//  LoginViewController.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/1/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var stepLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var addKeyButton: UIButton!
    @IBOutlet var instructions: Array<UIView>?
    
    let keyURL = "https://www.destiny.gg/login"
    
    var waitingForLoginKey = false

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(userReturned), name:
            UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    func userReturned() {
        guard waitingForLoginKey else {
            return
        }

        let pasteboardString: String? = UIPasteboard.general.string
        if let clipboard = pasteboardString {
            if clipboard.count >= 64 && clipboard.isAlphanumeric {
                alertSaveKey(clipboard: clipboard)
            } else if clipboard.isAlphanumeric {
                alertConfirmKey(clipboard: clipboard)
            }
        }
    }
    
    func receivedOauthCode(code: String, state: String) {
        dggAPI.getOauthToken(state: state, code: code, completion: {
            self.updateUI()
        })
    }
    
    func updateUI() {
        if settings.dggAccessToken == "" {
            stepLabel.text = "Step 1: Login with your dgg Account"
            loginButton.setTitle("Login with DGG", for: .normal)
            loginButton.isHidden = false
            for view in instructions! {
                view.isHidden = true
            }
        } else if settings.loginKey == "" {
            stepLabel.text = "Step 2: Acquire a Chat Login Key"
            loginButton.setTitle("Get login key", for: .normal)
            loginButton.isHidden = false
            for view in instructions! {
                view.isHidden = false
            }
        } else {
            stepLabel.text = "Login Key Acquired"
            loginButton.isHidden = true
            for view in instructions! {
                view.isHidden = true
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func alertSaveKey(clipboard: String) {
        let template = "Looks like the login key starting with \"%@\" is in your clipboard, login using this key?"
        let redactedKey = String(clipboard.prefix(5))
        let alert = UIAlertController(title: "Key Detected in clipboard", message: String(format: template, redactedKey), preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {action in
            settings.loginKey = clipboard
            self.dismiss(animated: true, completion: nil)
        }))
        
        
        self.present(alert, animated: true)
    }
    
    func alertConfirmKey(clipboard: String) {
        let template = "The text in your clipboard does not seem like it's a key (starts with \"%@\"), try logging in using it anyway?"
        let redactedKey = String(clipboard.prefix(5))
        let alert = UIAlertController(title: "Possible Key in clipboard", message: String(format: template, redactedKey), preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {action in
            settings.loginKey = clipboard
            self.dismiss(animated: true, completion: nil)
        }))
        
        
        self.present(alert, animated: true)
    }
    
    func alertInputKey() {
        let alert = UIAlertController(title: "Enter the Key", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "7KEYLVwmCERvaB4oas......"
        })
        
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { action in
            
            if let key = alert.textFields?.first?.text {
                settings.loginKey = key
                self.dismiss(animated: true, completion: nil)
            }
        }))
        
        self.present(alert, animated: true)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func loginTap(_ sender: Any) {
        if settings.dggAccessToken == "" {
            guard let url = dggAPI.getOauthURL() else { return }
            UIApplication.shared.open(url)
        } else {
            waitingForLoginKey = true
            guard let url = URL(string: keyURL) else { return }
            UIApplication.shared.open(url)

        }
    }
    
    @IBAction func doneTap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addKeyTap(_ sender: Any) {
        let alert = UIAlertController(title: "Where is the key?", message: "", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Copy from clipboard", style: .default, handler: {action in
            let pasteboardString: String? = UIPasteboard.general.string
            if let clipboard = pasteboardString {
                settings.loginKey = clipboard
                self.dismiss(animated: true, completion: nil)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Enter Manually", style: .default, handler: {action in
            self.alertInputKey()
        }))
        
        
        self.present(alert, animated: true)
    }
}

extension String {
    var isAlphanumeric: Bool {
        return !isEmpty && range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil
    }
}
