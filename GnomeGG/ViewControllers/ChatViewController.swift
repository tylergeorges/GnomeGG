//
//  FirstViewController.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 5/30/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//



import UIKit
import Swift
import NVActivityIndicatorView
import MKToolTip

var users = [User]()
var websocket: URLSessionWebSocketTask?

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, URLSessionDelegate {
    
    var receiverRunning = false
    var messages = [DGGMessage]()
    var renderedMessages = [NSMutableAttributedString]()
    
    let dggWebsocketURL = "wss://chat.destiny.gg/ws"
    
    
    @IBOutlet weak var refreshBarButton: UIBarButtonItem!
    
    var websocketBackoff = 100
    var dontRecover = false
    var authenticatedWebsocket = false
    var loadingHistory = false
    var chatInputHeight: CGFloat?
    var suggestionsHeight: CGFloat?
    
    var killSocket = false
    var ressetingSocket = false
    // scroll tracking
    var lastContentOffset: CGFloat = 0
    var disableAutoScrolling = false {
        didSet {
            scrollDownLabel.isHidden = !disableAutoScrolling
        }
    }
    
    let chatCommands = ["/me", "/message", "/ignore", "/unignore", "/w", "/msg", "/reply"]
    
    var lastMessageFrom: String?
    var connectionCookie: String?
    
    var activeSuggestions = [Suggestion]()
    var lastComboableEmote: Emote?
    
    
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var scrollDownLabel: UILabel!
    @IBOutlet weak var nvActivityIndicatorView: NVActivityIndicatorView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var chatInputTextView: UITextView!
    @IBOutlet weak var suggestionsScrollView: UIScrollView!
    @IBOutlet weak var suggestionsStackView: UIStackView!
    @IBOutlet weak var chatInputHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var suggestionsHeightConstraints: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        chatInputHeight = chatInputHeightConstraint.constant
        suggestionsHeight = suggestionsHeightConstraints.constant
        nvActivityIndicatorView.startAnimating()
        
        scrollDownLabel.isHidden = true
        suggestionsScrollView.isHidden = true
        suggestionsHeightConstraints.constant = 0
        addScrollDownButton()
        
        print("getting flairs")
        dggAPI.getFlairList()
        print("getting emotes")
        dggAPI.getEmoteList(completionHandler: {
            for (i, message) in self.messages.enumerated() {
                self.renderedMessages[i] = renderMessage(message: message)
            }
            self.chatTableView.reloadData()
        })
        print("getting bbdgg emotes")
        dggAPI.getBBDGGEmoteList(completionHandler: {
            for (i, message) in self.messages.enumerated() {
                self.renderedMessages[i] = renderMessage(message: message)
            }
            self.chatTableView.reloadData()
        })
        
        Timer.scheduledTimer(timeInterval: 5*60, target: self, selector: #selector(getStreamStatus), userInfo: nil, repeats: true)
        getStreamStatus()
        
        chatInputTextView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        print("getting user settings")
        if settings.dggCookie != "" {
            dggAPI.getUserSettings(initalSync: false, loggedIn: { success in
                if (!success) {
                    self.logout()
                }
            })
        }
        
        print("getting history")
        loadingHistory = true
        dggAPI.getHistory(completionHandler: { oldMessages in
            print("got history")
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
        
        
        if settings.dggCookie != "" {
            if !authenticatedWebsocket && true || settings.dggCookie != (connectionCookie ?? "") {
                if !loadingHistory {
                    print("connect2")
                    connectToWebsocket()
                }
            }
        } else {
            if authenticatedWebsocket {
                authenticatedWebsocket = false
                connectToWebsocket()
            }
        }
    }
    
    func createNewSocket() {
        var request = URLRequest(url: URL(string: "wss://chat.destiny.gg/ws")!)
        request.setValue("https://www.destiny.gg", forHTTPHeaderField: "Origin")
        request.timeoutInterval = 5
        authenticatedWebsocket = settings.dggCookie != ""
        if authenticatedWebsocket {
            let cookieTemplate = "sid=%@"
            request.setValue(String(format: cookieTemplate, settings.dggCookie), forHTTPHeaderField: "Cookie")
        }
        
        let urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let ws = urlSession.webSocketTask(with: request)
        websocket = ws
        dontRecover = false
        ws.resume()
        websocketDidConnect()
        if !receiverRunning {
            receiveMessage()
            sendPing()
            receiverRunning = true
        }
    }
    
    func connectToWebsocket() {
        print("connect to websocket")
        refreshBarButton.isEnabled = false
        
        if let ws = websocket {
            if ws.state == .running {
                self.dontRecover = true
                killSocket = true
            }
        } else {
            createNewSocket()
        }

    }
    
    private func newMessage(message: DGGMessage) {
        switch message {
        case let .UserMessage(nick, _, _, data):
            for user in settings.ignoredUsers where user.lowercased() == nick.lowercased() {
                return
            }
            
            if settings.harshIgnore {
                for user in settings.ignoredUsers {
                    if containsWord(string: data, keyword: user) {
                        return
                    }
                }
            }
            
            if settings.hideNSFW && data.lowercased().contains("nsfw") || data.lowercased().contains("nsfl") {
                return
            }
        case .PrivateMessage:
            guard settings.showWhispersInChat else {
                return
            }
        default: break
        }
        
        let wasCombo = handleCombo(message: message)
        
        if !wasCombo {
            messages.append(message)
            let renderedMessage = renderMessage(message: message)
            renderedMessages.append(renderedMessage)
            chatTableView.insertRows(at: [IndexPath(row: messages.count - 1, section: 0)], with: .bottom)
        } else {
            chatTableView.reloadRows(at: [IndexPath(row: messages.count - 1, section: 0)], with: .none)
        }
        
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
        case .Combo(let timestamp, let count, let emote):
            let updateCombo: DGGMessage = .Combo(timestamp: timestamp, count: count + 1, emote: emote)
            messages[messages.count - 1] = updateCombo
            renderedMessages[renderedMessages.count - 1] = renderMessage(message: updateCombo)
        case .UserMessage(_, _, let timestamp, _):
            let newCombo: DGGMessage = .Combo(timestamp: timestamp, count: 2, emote: emote)
            messages[messages.count - 1] = newCombo
            renderedMessages[renderedMessages.count - 1] = renderMessage(message: newCombo)
        default: return false
        }
        
        self.lastComboableEmote = emote
        return true
    }
    
    // MARK: - Websocket Delegate
    func websocketDidConnect() {
        websocketBackoff = 100
        connectionCookie = settings.dggCookie
        updateUI()
        ressetingSocket = false
        
        if settings.firstLaunch && settings.dggCookie == "" {
            guard let path = Bundle.main.path(forResource: "eula", ofType: "txt") else {
                return
            }
            do {
                let eula = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
                let alert = UIAlertController(title: "iOS App – End User License Agreement (EULA)", message: eula, preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Accept", style: .default, handler: { action in
                    settings.firstLaunch = false
                    let preference = ToolTipPreferences()
                    preference.drawing.bubble.color = .white
                    preference.drawing.arrow.tipCornerRadius = 0
                    preference.drawing.message.color = .black
                    
                    self.settingsButton.showToolTip(identifier: "identifier", title: nil, message: "Sign-in to chat!", button: nil, arrowPosition: .top, preferences: preference, delegate: nil)
                }))
                
                self.present(alert, animated: true)
            } catch {
                return
            }
        }
    }
    
    
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("did become invalid \(error)")
//        websocketDidDisconnect(error: error)
    }
    
    func disconnectWebsocket(error: Error?) {
        guard !ressetingSocket else {
            return
        }
        ressetingSocket = true
        updateUI()
        
        if let error = error {
            print(error)
//            newMessage(message: .Disconnected(reason: error.localizedDescription))
        } else {
            newMessage(message: .Disconnected(reason: "Killing Old Connection"))
        }
        
        guard let ws = websocket else {
            return
        }
        
        ws.cancel(with: .goingAway, reason: nil)
        websocket = nil
        self.killSocket = false
        print("preparing to reset")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(self.websocketBackoff), execute: {
            self.websocketBackoff = self.websocketBackoff * 2
            print("connect to websocket")
            self.connectToWebsocket()
        })
    }
    
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        print("connected")
    }
    
    func receiveMessage() {
        guard let ws = websocket else {
            return
        }

        ws.receive { result in
            switch result {
            case .failure(let error):
                print("Error in receiving message: \(error)")
                self.receiverRunning = false
                DispatchQueue.main.async {
                    self.disconnectWebsocket(error: error)
                }
                return
            case .success(let message):
                switch message {
                case .string(let text):
                    DispatchQueue.main.async {
                        self.websocketDidReceiveMessage(text: text)
                    }
                case .data: break
                default: break
                }
            }
            
            if self.killSocket {
                self.receiverRunning = false
                DispatchQueue.main.async {
                    self.disconnectWebsocket(error: nil)
                }
            } else {
                self.receiveMessage()
            }
        }
    }
    
    func sendPing() {
        guard let ws = websocket else {
            return
        }
        
        ws.sendPing { (error) in
            if let error = error {
                print("Sending PING failed: \(error)")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                self.sendPing()
            }
        }
    }
    
    func websocketDidReceiveMessage(text: String) {
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
        case "UNMUTE":
            if let message = DGGParser.parseUnmuteMessage(message: rest) {
                newMessage(message: message)
            }
        case "UNBAN":
            if let message = DGGParser.parseUnbanMessage(message: rest) {
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
        case "ERR":
            if let error = DGGParser.parseChatErrorMessage(message: rest) {
                newMessage(message: error)
            }
        case "PRIVMSGSENT":
            newMessage(message: .InternalMessage(data: "Your Message Has Been Sent"))
        case "PRIVMSG":
            if let message = DGGParser.parsePrivateMessage(message: rest) {
                switch message {
                case let .PrivateMessage(_, nick,_, _): lastMessageFrom = nick
                default: break
                }
                newMessage(message: message)
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
        for u in users where u.nick.lowercased() == user.lowercased() {
            return
        }
        users.append(User(nick: user, features: [String]()))
    }
    
    // MARK: - Textview
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        suggestionsScrollView.isHidden = true
        suggestionsHeightConstraints.constant = 0
        sendNewMessage()
        
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        guard let text = textView.text else {
            suggestionsScrollView.isHidden = true
            suggestionsHeightConstraints.constant = 0
            sendButton.setImage(UIImage(named: "cancel"), for: .normal)
            return
        }
        
        if text.count == 0 && chatInputTextView.isFirstResponder {
            sendButton.setImage(UIImage(named: "cancel"), for: .normal)
        } else {
            sendButton.setImage(UIImage(named: "send"), for: .normal)
        }
        
        if text.lowercased() == "/reply " {
            if let target = lastMessageFrom {
                textView.text = "/message " + target + " "
                suggestionsScrollView.isHidden = true
                suggestionsHeightConstraints.constant = 0
            } else {
                textView.text = ""
                suggestionsScrollView.isHidden = true
                suggestionsHeightConstraints.constant = 0
            }
        }
        
        guard text.last != " " else {
            suggestionsScrollView.isHidden = true
            suggestionsHeightConstraints.constant = 0
            return
        }
        
        let words = text.components(separatedBy: " ")
        guard let lastWord = words.last else {
            suggestionsScrollView.isHidden = true
            suggestionsHeightConstraints.constant = 0
            return
        }
        
        guard lastWord.count > 2 else {
            suggestionsScrollView.isHidden = true
            suggestionsHeightConstraints.constant = 0
            return
        }
        
        suggestionsStackView.removeAllArrangedSubviews()
        let suggestions = generateSuggestions(text: lastWord, firstWord: words.count == 1)
        activeSuggestions = suggestions
        for (i, suggestion) in suggestions.enumerated() {
            let label = PaddingLabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
            label.leftInset = 20
            label.rightInset = 20
            
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
            label.layer.cornerRadius = 25
            label.backgroundColor = UIColor.black
            let tap = UITapGestureRecognizer(target: self, action: #selector(suggestionTapped(sender:)))
            label.addGestureRecognizer(tap)
            
            suggestionsStackView.addArrangedSubview(label)
        }
        
        if suggestions.count > 0 {
            suggestionsScrollView.isHidden = false
            suggestionsHeightConstraints.constant = suggestionsHeight!
        } else {
            suggestionsScrollView.isHidden = true
            suggestionsHeightConstraints.constant = 0
        }
        
        
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            //            sendButton.setImage(UIImage(named: "send"), for: .normal)
            //            textView.resignFirstResponder()
            if textView.text.count == 0 {
                textView.resignFirstResponder()
                sendButton.setImage(UIImage(named: "send"), for: .normal)
            } else {
                sendNewMessage()
            }
            
            return false
        }
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        sendButton.setImage(UIImage(named: "send"), for: .normal)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text.count == 0 {
            sendButton.setImage(UIImage(named: "cancel"), for: .normal)
        }
        
    }
    
    // MARK: - TableView
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.count]
        
        switch message {
        case let .UserMessage(nick, _, _, _): print(nick)
        default: break
        }
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return renderedMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // it's over for chatcels
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath) as! ChatTableViewCell
        cell.selectionStyle = .none
        cell.renderMessage(message: renderedMessages[indexPath.row], messageEnum: messages[indexPath.row])
        
        return cell
    }
    
    // MARK: - Scroll View
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.lastContentOffset = scrollView.contentOffset.y
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView is UITableView else {
            return
        }
        
        if (self.lastContentOffset > scrollView.contentOffset.y) {
            if !disableAutoScrolling {
                disableAutoScrolling = true
            }
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
            let indexPath = IndexPath(row: self.renderedMessages.count-1, section: 0)
            self.chatTableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
        }
    }
    
    @objc
    private func suggestionTapped(sender: UITapGestureRecognizer? = nil) {
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
            if nick == "/reply" && components.count == 1 {
                if let target = lastMessageFrom {
                    chatInputTextView.text = "/message " + target + " "
                    suggestionsScrollView.isHidden = true
                    suggestionsHeightConstraints.constant = 0
                } else {
                    chatInputTextView.text = ""
                    suggestionsScrollView.isHidden = true
                    suggestionsHeightConstraints.constant = 0
                }
                
                return
            }
            components[components.count - 1] = nick
        }
        
        components.append("")
        chatInputTextView.text = components.joined(separator: " ")
        suggestionsScrollView.isHidden = true
        suggestionsHeightConstraints.constant = 0
    }
    
    private func addScrollDownButton() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(ChatViewController.scrollToBottom))
        scrollDownLabel.addGestureRecognizer(tap)
    }
    
    private func runOnUIThread(_ block: @escaping () -> Void) {
        DispatchQueue.main.async(execute: block)
    }
    
    private func logout() {
        settings.reset()
        if authenticatedWebsocket {
            connectToWebsocket()
        }
    }
    
    private func updateUI() {
        sendButton.isHidden = !authenticatedWebsocket
        chatInputTextView.isHidden = !authenticatedWebsocket
        
        sendButton.isEnabled = websocket?.state == .running
        
        if authenticatedWebsocket {
            chatInputHeightConstraint.constant = chatInputHeight!
        } else {
            chatInputHeightConstraint.constant = 0
        }
        
        if websocket?.state == .running {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.refreshBarButton.isEnabled = true
            }
        } else {
            refreshBarButton.isEnabled = false
        }
    }
    
    private func generateSuggestions(text: String, firstWord: Bool = false) -> [Suggestion] {
        var suggestions = [Suggestion]()
        
        guard settings.autoCompletion else {
            return suggestions
        }
        
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
        
        if firstWord {
            for command in chatCommands {
                if command.lowercased().starts(with: matchText) {
                    suggestions.append(.User(nick: command))
                }
            }
        }
        
        return suggestions
    }
    
    private func sendNewMessage() {
        defer {
            chatInputTextView.text = ""
            if chatInputTextView.isFirstResponder {
                sendButton.setImage(UIImage(named: "cancel"), for: .normal)
            }
        }
        
        guard let message = chatInputTextView.text else {
            return
        }
        
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\n", with: " ")
        guard trimmedMessage != "" else {
            return
        }
        
        let words = trimmedMessage.split(separator: " ")
        
        for command in chatCommands where words.first?.lowercased() == command {
            if command == "/ignore" {
                if words.count == 1 {
                    newMessage(message: .InternalMessage(data: "Ignored users: " + settings.ignoredUsers.joined(separator: ", ")))
                    return
                } else if words.count > 1 {
                    let target = words[1]
                    for ignored in settings.ignoredUsers where ignored.lowercased() == target.lowercased() {
                        newMessage(message: .InternalMessage(data: target + " already ignored"))
                        return
                    }
                    
                    settings.ignoredUsers.append(String(target))
                    newMessage(message: .InternalMessage(data: target + " ignored"))
                    return
                } else {
                    return
                }
            }
            
            if command == "/unignore" {
                if words.count < 2 {
                    return
                } else {
                    let target = words[1]
                    for (i, ignored) in settings.ignoredUsers.enumerated() where ignored.lowercased() == target.lowercased() {
                        settings.ignoredUsers.remove(at: i)
                        newMessage(message: .InternalMessage(data: target + " unignored"))
                        return
                    }
                    
                    newMessage(message: .InternalMessage(data: target + " is not ignored"))
                }
            }
            
            // TODO simplify to one write call
            print("test")
            if command == "/w" || command == "/message" || command == "/msg" {
                if words.count < 3 {
                    return
                }
                
                // send private message
                let privateMessageTemplate = "PRIVMSG {\"nick\":\"%@\",\"data\":\"%@\"}"
                let message = URLSessionWebSocketTask.Message.string(String(format: privateMessageTemplate, String(words[1]), words[2...].joined(separator: " ")))
                websocket?.send(message) { error in
                    if let error = error {
                        print("WebSocket couldn’t send message because: \(error)")
                    }
                }
                
                return
            }
        }
        
        // send the message
        let messageTemplate = "MSG {\"data\":\"%@\"}"
        let escapedMessage = trimmedMessage.replacingOccurrences(of: "\"", with: "\\\"", options: .literal, range: nil)
        let chatMessage = URLSessionWebSocketTask.Message.string(String(format: messageTemplate, escapedMessage))
        websocket?.send(chatMessage) { error in
            if let error = error {
                print("WebSocket couldn’t send message because: \(error)")
            }
        }
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
    
    @objc
    private func getStreamStatus() {
        dggAPI.getStreamStatus(completionHandler: { status in
            guard let status = status else {
                self.navigationBar.topItem?.title = ""
                return
            }
            
            switch status {
            case .Live: self.navigationBar.topItem?.title = "Stream Live"
            case .Offline: self.navigationBar.topItem?.title = "Stream Offline"
            case .Hosting(let stream): self.navigationBar.topItem?.title = "Hosting: " + stream
            }
        })
    }
    
    @IBAction func sendTap(_ sender: Any) {
        if chatInputTextView.text.count == 0 {
            chatInputTextView.resignFirstResponder()
            sendButton.setImage(UIImage(named: "send"), for: .normal)
        }
        suggestionsScrollView.isHidden = true
        suggestionsHeightConstraints.constant = 0
        sendNewMessage()
    }
    
    @IBAction func refreshTap(_ sender: UIBarButtonItem) {
        connectToWebsocket()
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
