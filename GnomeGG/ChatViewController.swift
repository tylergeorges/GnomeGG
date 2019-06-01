//
//  FirstViewController.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 5/30/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//


// TODO:
// CHAT
// >greentext in current year
// /me
// links
// nsfw nsfl spoiler highlights
// cap number of stored messages so the app doesn't explode eventually
// highlights
// chat suggestions
// MENTIONS
// TOOLS
// SETTINGS

import UIKit
import Starscream

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, WebSocketDelegate {
    
    let dggAPI = DGGAPI()
    
    var messages = [DGGMessage]()
    var websocket: WebSocket?
    
    let dggWebsocketURL = "https://www.destiny.gg/ws"
    
    var websocketBackoff = 100
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollDownLabel.isHidden = true
        addScrollDownButton()
        
        dggAPI.getFlairList()
        dggAPI.getEmoteList()
        
        chatTableView.delegate = self
        chatTableView.dataSource = self
        
        websocket = WebSocket(url: URL(string: dggWebsocketURL)!)
        if let websocket = websocket {
            websocket.delegate = self
            websocket.connect()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        chatTableView.estimatedRowHeight = 200
        chatTableView.rowHeight = UITableView.automaticDimension
    }
    
    private func newMessage(message: String) {
        guard let parsedMessage = DGGParser.parseUserMessage(message: message) else {
            return
        }
        
        
        let wasCombo = handleCombo(message: parsedMessage)
        
        if !wasCombo {
            messages.append(parsedMessage)
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
        
        // 2 cases, ongoing combo or no combo
        switch messages.last! {
        case .Combo(let timestamp, let count, let emote): messages[messages.count - 1] = .Combo(timestamp: timestamp, count: count + 1, emote: emote)
        case .UserMessage(_, _, let timestamp, _): messages[messages.count - 1] = .Combo(timestamp: timestamp, count: 2, emote: emote)
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
            self.websocketBackoff = self.websocketBackoff * 2
            self.websocket?.connect()
        })
        if let error = error as? WSError {
            print(error)
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
        case "MSG": newMessage(message: rest)
        default: print("got some text: \(text)")
        }
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
        cell.rederMessage(message: messages[indexPath.row], flairs: dggAPI.flairs, emotes: dggAPI.emotes)
        
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

}

