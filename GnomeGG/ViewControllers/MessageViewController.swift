//
//  MessageViewController.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/7/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit
import Starscream
import NVActivityIndicatorView

class MessageViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, WebSocketDelegate, UITextViewDelegate {
    
    var messages = [DGGMessage]()
    var renderedMessages = [NSMutableAttributedString]()
    
    var DMedUser: String!
    
    let dggWebsocketURL = "https://www.destiny.gg/ws"
    
    var websocketBackoff = 100
    var chatInputHeight: CGFloat?
    var suggestionsHeight: CGFloat?
    
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
        
        
        chatInputTextView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        print("getting private history")
        dggAPI.getUserMessages(user: DMedUser, completionHandler: { messages in
            self.nvActivityIndicatorView.stopAnimating()
            guard let messages = messages else {
                // handle ui
                return
            }
            
            for message in messages.reversed() {
                self.newMessage(message: .PrivateMessage(timestamp: message.timestamp, nick: message.from, data: message.message, id: -1))
            }
            
            if let websocket = websocket {
                websocket.delegate = self
            }
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
    }
    
    private func newMessage(message: DGGMessage) {
        switch(message) {
        case .PrivateMessage(_, let nick, _, _):
            if nick.lowercased() != DMedUser.lowercased() && nick.lowercased() != settings.dggUsername.lowercased() {
                return
            }
        default: return
        }
        
        messages.append(message)
        let renderedMessage = renderMessage(message: message)
        renderedMessages.append(renderedMessage)
        chatTableView.insertRows(at: [IndexPath(row: messages.count - 1, section: 0)], with: .bottom)
        
        if !disableAutoScrolling {
            scrollToBottom()
        }
        
        switch(message) {
        case .PrivateMessage(_, let nick, _, let id):
            if nick.lowercased() == DMedUser.lowercased() {
                if id != -1 {
                    dggAPI.markMessageAsOpen(id: id)
                }
            }
        default: return
        }
    }
    
    // MARK: - Websocket Delegate
    func websocketDidConnect(socket: WebSocketClient) {
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        let components = text.components(separatedBy: " ")
        let type = components[0]
        let rest = components[1...].joined(separator: " ")
        switch type {
        case "PRIVMSG":
            if let message = DGGParser.parsePrivateMessage(message: rest) {
                switch message {
                case .PrivateMessage: break
                default: return
                }
                newMessage(message: message)
            }
        default: break
        }
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print("got some data: \(data.count)")
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
            components[components.count - 1] = nick
        }
        
        components.append("")
        chatInputTextView.text = components.joined(separator: " ")
        suggestionsScrollView.isHidden = true
        suggestionsHeightConstraints.constant = 0
    }
    
    private func addScrollDownButton() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(scrollToBottom))
        scrollDownLabel.addGestureRecognizer(tap)
    }
    
    private func runOnUIThread(_ block: @escaping () -> Void) {
        DispatchQueue.main.async(execute: block)
    }
    
    private func updateUI() {
        sendButton.isHidden = false
        chatInputTextView.isHidden = false
        sendButton.isEnabled = websocket?.isConnected ?? false
        
        chatInputHeightConstraint.constant = chatInputHeight!
    }
    
    private func generateSuggestions(text: String, firstWord: Bool = false) -> [Suggestion] {
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
    
        // send private message
        let privateMessageTemplate = "PRIVMSG {\"nick\":\"%@\",\"data\":\"%@\"}"
        websocket?.write(string: String(format: privateMessageTemplate, DMedUser, words.joined(separator: " ")))
        newMessage(message: .PrivateMessage(timestamp: Date(), nick: settings.dggUsername, data: words.joined(separator: " "), id: -1))
        return
    
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
    
    @IBAction func sendTap(_ sender: Any) {
        if chatInputTextView.text.count == 0 {
            chatInputTextView.resignFirstResponder()
            sendButton.setImage(UIImage(named: "send"), for: .normal)
        }
        suggestionsScrollView.isHidden = true
        suggestionsHeightConstraints.constant = 0
        sendNewMessage()
    }
}
