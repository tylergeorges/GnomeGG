//
//  UserTagListViewController.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/8/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit

class UserTagListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 45
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            settings.userTags.remove(at: indexPath.row)
            settings.userNotes.remove(at: indexPath.row)
            tableView.reloadData()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.userTags.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userTagCell", for: indexPath) as! UserTagTableViewCell
        cell.selectionStyle = .none
        
        cell.renderUserTag(tag: settings.userTags[indexPath.row])
        
        return cell
    }
    
    private func promptForWord() {
        let title = "Enter a Username"
        
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "DankGnome"
        })
        
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { action in
            
            if let word = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
                for tag in settings.userTags where word.lowercased() == tag.nick.lowercased() {
                    return
                }
                settings.userTags.append(UserTag(nick: word, color: "black"))
                settings.userNotes.append(UserNote(nick: word, note: ""))
                self.tableView.reloadData()
            }
            
            }))
        self.present(alert, animated: true)
    }
    
    @IBAction func doneTap(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addString(_ sender: Any) {
        promptForWord()
    }
}
