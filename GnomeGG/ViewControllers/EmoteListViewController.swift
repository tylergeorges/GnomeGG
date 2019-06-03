//
//  EmoteListViewController.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/3/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit

class EmoteListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var emoteTableView: UITableView!
    
    let emotes = dggAPI.emotes.sorted(by: {$0.prefix < $1.prefix })
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emoteTableView.rowHeight = 45
        
        emoteTableView.delegate = self
        emoteTableView.dataSource = self
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - TableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return emotes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "emoteCell", for: indexPath) as! EmoteTableViewCell
        cell.selectionStyle = .none
        cell.renderEmote(emote: emotes[indexPath.row])
        
        return cell
    }

}
