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
// combos
// emotes
// links
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
    
    @IBOutlet weak var chatTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        messages.append(parsedMessage)
        chatTableView.reloadData()
        scrollToBottom()
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
        print("got some text: \(text)")
        let components = text.components(separatedBy: " ")
        let type = components[0]
        let rest = components[1...].joined(separator: " ")
        
        switch type {
        case "MSG": newMessage(message: rest)
        default: return
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
    
    // MARK: - Utility
    private func scrollToBottom(animated: Bool = false){
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: self.messages.count-1, section: 0)
            self.chatTableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
        }
    }

}

