//
//  FirstViewController.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 5/30/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//


// TODO:
// CHAT
// cap number of stored messages so the app doesn't explode eventually
// highlights
// chat suggestions
// MENTIONS
// TOOLS
// SETTINGS

import UIKit
import Starscream
import NVActivityIndicatorView

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, WebSocketDelegate {
    
    var messages = [DGGMessage]()
    var users = [User]()
    var websocket: WebSocket?
    
    let dggWebsocketURL = "https://www.destiny.gg/ws"
    
    var websocketBackoff = 100
    var dontRecover = false
    var authenticatedWebsocket = false
    
    // scroll tracking
    var lastContentOffset: CGFloat = 0
    var disableAutoScrolling = false {
        didSet {
            scrollDownLabel.isHidden = !disableAutoScrolling
        }
    }
    
    var lastComboableEmote: Emote?
    
    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var scrollDownLabel: UILabel!
    @IBOutlet weak var nvActivityIndicatorView: NVActivityIndicatorView!
    @IBOutlet weak var loginBarButton: UIBarButtonItem!
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nvActivityIndicatorView.startAnimating()
        
        scrollDownLabel.isHidden = true
        addScrollDownButton()
        
        dggAPI.getFlairList()
        dggAPI.getEmoteList()

        dggAPI.getUserInfo(completionHandler: {
            if settings.dggUsername != "" {
                print("Logged in as: " + settings.dggUsername)
//                self.title = "Logged in as: " + settings.dggUsername
            }
        })

        dggAPI.getHistory(completionHandler: { oldMessages in
            self.nvActivityIndicatorView.stopAnimating()
            self.nvActivityIndicatorView.isHidden = true
            
            for msg in oldMessages {
                guard let message = DGGParser.parseUserMessage(message: msg.components(separatedBy: " ")[1...].joined(separator: " ")) else {
                    continue
                }

                self.newMessage(message: message)
            }
            
            self.connectToWebsocket()
        })
        
        chatTableView.delegate = self
        chatTableView.dataSource = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        chatTableView.estimatedRowHeight = 200
        chatTableView.rowHeight = UITableView.automaticDimension
        
        if settings.loginKey == "" {
            loginBarButton.title = "Login"
        } else {
            loginBarButton.title = "Logout"
            
            if !authenticatedWebsocket {
                connectToWebsocket()
            }
        }
    }
    
    private func connectToWebsocket() {
        
        var request = URLRequest(url: URL(string: dggWebsocketURL)!)
        request.timeoutInterval = 5
        authenticatedWebsocket = settings.loginKey != ""
        if authenticatedWebsocket {
            let cookieTemplate = "authtoken=%@"
            request.setValue(String(format: cookieTemplate, settings.loginKey), forHTTPHeaderField: "Cookie")
        }
        
        if let websocket = websocket {
            self.dontRecover = true
            if websocket.isConnected {
                websocket.disconnect()
                newMessage(message: .Disconnected(reason: "Updating Socket"))
            }
            
            self.websocket = nil
        }
        
        websocket = WebSocket(request: request)
        if let websocket = websocket {
            websocket.delegate = self
            dontRecover = false
            websocket.connect()
        }
    }
    
    private func newMessage(message: DGGMessage) {
        
        let wasCombo = handleCombo(message: message)
        
        if !wasCombo {
            messages.append(message)
        }
        chatTableView.reloadData()
        
        if !disableAutoScrolling {
            scrollToBottom()
        }
    }
    
    private func getEmote(word: String) -> Emote? {
        for emote in dggAPI.emotes where emote.prefix == word {
            return emote
        }
        
        return nil
    }
    
    private func handleCombo(message: DGGMessage) -> Bool {
        guard case .UserMessage(_, _, _, let data) = message else {
            self.lastComboableEmote = nil
            return false
        }
        
        guard let lastComboableEmote = lastComboableEmote else {
            self.lastComboableEmote = getEmote(word: data)
            return false
        }
        
        guard let emote = getEmote(word: data) else {
            self.lastComboableEmote = nil
            return false
        }
        
        guard lastComboableEmote.prefix == emote.prefix else {
            self.lastComboableEmote = emote
            return false
        }
        
        switch messages.last! {
        case .Combo(let timestamp, let count, let emote): messages[messages.count - 1] = .Combo(timestamp: timestamp, count: count + 1, emote: emote)
        case .UserMessage(_, _, let timestamp, _): messages[messages.count - 1] = .Combo(timestamp: timestamp, count: 2, emote: emote)
        default: return false
        }
        
        self.lastComboableEmote = emote
        return true
    }
    
    // MARK: - Websocket Delegate
    func websocketDidConnect(socket: WebSocketClient) {
        print("websocket is connected")
        websocketBackoff = 100
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("websocket is disconnected: \(error?.localizedDescription)")
        print("reconnecting")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(self.websocketBackoff), execute: {
            guard self.dontRecover else {
                return
            }

            self.websocketBackoff = self.websocketBackoff * 2
            self.newMessage(message: .Connecting)
            self.connectToWebsocket()
        })
        if let error = error as? WSError {
            print(error)
            newMessage(message: .Disconnected(reason: error.message))
            if error.code == 0 {
                print("timed out")
            }
        }
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        let components = text.components(separatedBy: " ")
        let type = components[0]
        let rest = components[1...].joined(separator: " ")
        
        switch type {
        case "MSG":
            if let message = DGGParser.parseUserMessage(message: rest) {
                newMessage(message: message)
            }
        case "BROADCAST":
            if let message = DGGParser.parseBroadcastMessage(message: rest) {
                newMessage(message: message)
            }
        case "NAMES":
            if let message = DGGParser.parseNamesMessage(message: rest) {
                newMessage(message: message)
            }
        case "MUTE":
            if let message = DGGParser.parseMuteMessage(message: rest) {
                newMessage(message: message)
            }
        case "QUIT":
            if let user = DGGParser.parseDoorMessage(message: rest) {
                userLeft(user: user)
            }
        case "JOIN":
            if let user = DGGParser.parseDoorMessage(message: rest) {
                userJoined(user: user)
            }
        default: print("got some text: \(text)")
        }
    }
    
    private func userLeft(user: String) {
        for (i, u) in users.enumerated() where u.nick == user {
            users.remove(at: i)
        }
    }
    
    private func userJoined(user: String) {
        users.append(User(nick: user, features: [String]()))
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print("got some data: \(data.count)")
    }

    // MARK: - TableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // it's over for chatcels
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath) as! ChatTableViewCell
        cell.selectionStyle = .none
        cell.rederMessage(message: messages[indexPath.row])
        
        return cell
    }
    
    // MARK: - Scroll View
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.lastContentOffset = scrollView.contentOffset.y
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (self.lastContentOffset > scrollView.contentOffset.y) {
            disableAutoScrolling = true
        }
        
        let height = scrollView.frame.size.height
        let contentYoffset = scrollView.contentOffset.y
        let distanceFromBottom = scrollView.contentSize.height - contentYoffset
        if (distanceFromBottom - 5) < height {
            disableAutoScrolling = false
        }
    }
    
    // MARK: - Utility
    @objc
    private func scrollToBottom(animated: Bool = false) {
        disableAutoScrolling = false
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: self.messages.count-1, section: 0)
            self.chatTableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
        }
    }
    
    private func addScrollDownButton() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(ChatViewController.scrollToBottom))
        scrollDownLabel.addGestureRecognizer(tap)
    }
    
    private func runOnUIThread(_ block: @escaping () -> Void) {
        DispatchQueue.main.async(execute: block)
    }
    
    private func logout() {
        settings.loginKey = ""
        settings.dggAccessToken = ""
        settings.dggRefreshToken = ""
        settings.dggUsername = ""
        loginBarButton.title = "Login"
        if authenticatedWebsocket {
            connectToWebsocket()
        }
    }

    @IBAction func loginTap(_ sender: Any) {
        if settings.loginKey == "" {
            performSegue(withIdentifier: "loginSegue", sender: self)
        } else {
            let alert = UIAlertController(title: "Logout?", message: "Are you sure you want to log out?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Yee", style: .default, handler: {action in
                self.logout()
            }))
            
            self.present(alert, animated: true)
        }
    }
}

