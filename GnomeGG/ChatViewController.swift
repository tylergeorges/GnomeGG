//
//  FirstViewController.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 5/30/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit
import Starscream

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, WebSocketDelegate {
    
    var messages = [String]()
    var websocket: WebSocket?
    
    let dggWebsocketURL = "https://www.destiny.gg/ws"
    
    @IBOutlet weak var chatTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        chatTableView.delegate = self
        chatTableView.dataSource = self
        
        websocket = WebSocket(url: URL(string: dggWebsocketURL)!)
        if let websocket = websocket {
            websocket.delegate = self
            websocket.connect()
        }
    }
    
    // MARK: - Websocket Delegate
    func websocketDidConnect(socket: WebSocketClient) {
        print("websocket is connected")
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("websocket is disconnected: \(error?.localizedDescription)")
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        print("got some text: \(text)")
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
        cell.rederMessage(debug: messages[indexPath.row])
        
        return cell
    }

}

