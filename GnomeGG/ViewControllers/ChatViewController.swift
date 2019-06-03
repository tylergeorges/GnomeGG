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
// hide scroll down when suggestions are showing
// BDGG emotes https://raw.githubusercontent.com/BryceMatthes/chat-gui/master/assets/emotes.json
// https://raw.githubusercontent.com/BryceMatthes/chat-gui/master/assets/emotes/emoticons
// TOOLS
// -logs
// -keyword search
// SETTINGS
// dynamic constranits
// VV why dis message not work???
// "MSG {\"nick\":\"hotdoglover86\",\"features\":[\"subscriber\",\"flair9\",\"flair13\"],\"timestamp\":1559537867279,\"data\":\"Abathur\\nHmmStiny\\nShekels\\nAMAZIN\\nDANKMEMES\\nAYYYLMAO\\nHmmStiny\\nCheekerZ\\nNOBULLY\\nSlugstiny\\nDEATH\\nBlade\\nLOVE\\nDAFUK\\nNappa\\nOverRustle\\nMLADY\\nDANKMEMES\\nWEEWOO\\nPICNIC\\nShekels\\nGODSTINY\\nAYAYA\\nSNAP\\nAngelThump\\nFrankerZ\\nSOTRIGGERED\\nKappaRoss\\nBlubstiny\\nGameOfThrows\\nAbathur\\nHhhehhehe\\nDravewin\\nAbathur\\nHmmStiny\\nShekels\\nAMAZIN\\nDANKMEMES\\nAYYYLMAO\\nHmmStiny\\nCheekerZ\\nNOBULLY\\nSlugstiny\\nDEATH\\nBlade\\nLOVE\\nDAFUK\\nNappa\\nOverRustle\\nMLADY\\nDANKMEMES\\nWEEWOO\\nPICNIC\\nShekels\\nGODSTINY\\nAYAYA\\nSNAP\\nAngelThump\\nFrankerZ\\nSOTRIGGERED\"}"

import UIKit
import Starscream
import NVActivityIndicatorView

var users = [User]()

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, WebSocketDelegate, UITextViewDelegate {
    
    var messages = [DGGMessage]()
    
    var websocket: WebSocket?
    
    let dggWebsocketURL = "https://www.destiny.gg/ws"
    
    var websocketBackoff = 100
    var dontRecover = false
    var authenticatedWebsocket = false
    var loadingHistory = false
    var chatInputHeight: CGFloat?
    
    // scroll tracking
    var lastContentOffset: CGFloat = 0
    var disableAutoScrolling = false {
        didSet {
            scrollDownLabel.isHidden = !disableAutoScrolling
        }
    }
    
    var activeSuggestions = [Suggestion]()
    var lastComboableEmote: Emote?
    
    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var scrollDownLabel: UILabel!
    @IBOutlet weak var nvActivityIndicatorView: NVActivityIndicatorView!
    @IBOutlet weak var loginBarButton: UIBarButtonItem!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var chatInputTextView: UITextView!
    @IBOutlet weak var suggestionsScrollView: UIScrollView!
    @IBOutlet weak var suggestionsStackView: UIStackView!
    @IBOutlet weak var chatInputHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        chatInputHeight = chatInputHeightConstraint.constant
        nvActivityIndicatorView.startAnimating()
        
        scrollDownLabel.isHidden = true
        suggestionsScrollView.isHidden = true
        addScrollDownButton()
        
        dggAPI.getFlairList()
        dggAPI.getEmoteList()
        
        chatInputTextView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)


        
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
            
            print("got history, connect to websocket")
            self.loadingHistory = false
            self.connectToWebsocket()
        })
        
        chatTableView.delegate = self
        chatTableView.dataSource = self
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        chatTableView.estimatedRowHeight = 200
        chatTableView.rowHeight = UITableView.automaticDimension
        updateUI()

        print("Connected?")
        print(websocket?.isConnected)
        
        if settings.loginKey == "" {
            loginBarButton.title = "Login"
        } else {
            loginBarButton.title = "Logout"
            
            if !authenticatedWebsocket && !(websocket?.isConnected ?? true) {
                if !loadingHistory {
                    connectToWebsocket()
                }
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
        updateUI()
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("websocket is disconnected: \(error?.localizedDescription)")
        print("reconnecting")
        updateUI()
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
                switch message {
                case let .Names(_, newUsers): users = newUsers
                default: return
                }
            }
        case "MUTE":
            if let message = DGGParser.parseMuteMessage(message: rest) {
                newMessage(message: message)
            }
        case "BAN":
            if let message = DGGParser.parseBanMessage(message: rest) {
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
    
    // MARK: - Textview
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        suggestionsScrollView.isHidden = true
        // send the message
        chatInputTextView.text = ""
        
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        guard let text = textView.text else {
            suggestionsScrollView.isHidden = true
            return
        }
        
        guard text.last != " " else {
            suggestionsScrollView.isHidden = true
            return
        }
        
        let words = text.components(separatedBy: " ")
        guard let lastWord = words.last else {
            suggestionsScrollView.isHidden = true
            return
        }
        
        guard lastWord.count > 2 else {
            suggestionsScrollView.isHidden = true
            return
        }
        
        suggestionsStackView.removeAllArrangedSubviews()
        let suggestions = generateSuggestions(text: lastWord)
        activeSuggestions = suggestions
        for (i, suggestion) in suggestions.enumerated() {
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
            label.center = CGPoint(x: 160, y: 285)
            label.textAlignment = .center
            
            switch suggestion {
            case let .Emote(emote):
                let emoteAttachement = NSTextAttachment()
                emoteAttachement.image = emote.image
                emoteAttachement.bounds = CGRect(x: 0, y: -5, width: emote.width, height: emote.height)
                let emoteString = NSMutableAttributedString(attachment: emoteAttachement)
                label.attributedText = emoteString
            case let .User(nick):
                label.text = nick
                label.textColor = UIColor.white
            }
            label.isUserInteractionEnabled = true
            label.tag = i
            label.layer.masksToBounds = true
            label.layer.cornerRadius = 5
            label.backgroundColor = UIColor.black
            let tap = UITapGestureRecognizer(target: self, action: #selector(suggestionTapped(sender:)))
            label.addGestureRecognizer(tap)
            
            suggestionsStackView.addArrangedSubview(label)
        }
        
        if suggestions.count > 0 {
            suggestionsScrollView.isHidden = false
        } else {
            suggestionsScrollView.isHidden = true
        }
        
        
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
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
        cell.renderMessage(message: messages[indexPath.row])
        
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
    
    @objc
    private func suggestionTapped(sender: UITapGestureRecognizer? = nil) {
        print("suggestion tapped!")
        guard let tag = sender?.view?.tag else {
            return
        }
        
        guard let text = chatInputTextView.text else {
            return
        }
        
        let suggestion = activeSuggestions[tag]
        var components = text.components(separatedBy: " ")
        
        switch suggestion {
        case let .Emote(emote):
            components[components.count - 1] = emote.prefix
        case let .User(nick):
            components[components.count - 1] = nick
        }
        
        components.append("")
        chatInputTextView.text = components.joined(separator: " ")
        suggestionsScrollView.isHidden = true
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
    
    private func updateUI() {
        sendButton.isHidden = !authenticatedWebsocket
        chatInputTextView.isHidden = !authenticatedWebsocket
        sendButton.isEnabled = websocket?.isConnected ?? false
        
        if authenticatedWebsocket {
            chatInputHeightConstraint.constant = chatInputHeight!
        } else {
            chatInputHeightConstraint.constant = 0
        }
    }
    
    private func generateSuggestions(text: String) -> [Suggestion] {
        var suggestions = [Suggestion]()
        
        let matchText = text.lowercased()
        
        for emote in dggAPI.emotes {
            if emote.prefix.lowercased().starts(with: matchText) {
                suggestions.append(.Emote(emote: emote))
            }
        }
        
        for user in users {
            if user.nick.lowercased().starts(with: matchText) {
                suggestions.append(.User(nick: user.nick))
            }
        }
        
        return suggestions
    }
    
    @objc
    func keyboardWillHide() {
        self.view.frame.origin.y = 0
    }
    
    @objc
    func keyboardWillChange(notification: NSNotification) {
        
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if chatInputTextView.isFirstResponder {
                self.view.frame.origin.y = -(keyboardSize.height - tabBarController!.tabBar.frame.height)
            }
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

    @IBAction func sendTap(_ sender: Any) {
        chatInputTextView.resignFirstResponder()
        suggestionsScrollView.isHidden = true
        
        // send the message
        chatInputTextView.text = ""
    }
}

enum Suggestion {
    case Emote(emote: Emote)
    case User(nick: String)
}

extension UIStackView {
    
    func removeAllArrangedSubviews() {
        
        let removedSubviews = arrangedSubviews.reduce([]) { (allSubviews, subview) -> [UIView] in
            self.removeArrangedSubview(subview)
            return allSubviews + [subview]
        }
        
        // Deactivate all constraints
        NSLayoutConstraint.deactivate(removedSubviews.flatMap({ $0.constraints }))
        
        // Remove the views from self
        removedSubviews.forEach({ $0.removeFromSuperview() })
    }
}
