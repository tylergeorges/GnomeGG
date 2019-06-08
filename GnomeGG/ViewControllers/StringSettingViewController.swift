//
//  StringSettingViewController.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/4/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit

class StringSettingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var setting: SettingType?
    
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
            switch setting! {
            case .Highlights: settings.customHighlights.remove(at: indexPath.row)
            case .Ignores: settings.ignoredUsers.remove(at: indexPath.row)
            case .NickHighlights: settings.nickHighlights.remove(at: indexPath.row)
            }
            tableView.reloadData()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch setting! {
        case .Highlights: return settings.customHighlights.count
        case .Ignores: return settings.ignoredUsers.count
        case .NickHighlights: return settings.nickHighlights.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "stringSettingCell", for: indexPath) as! StringSettingTableViewCell
        cell.selectionStyle = .none
        
        switch setting! {
        case .Highlights: cell.string.text = settings.customHighlights[indexPath.row]
        case .Ignores: cell.string.text = settings.ignoredUsers[indexPath.row]
        case .NickHighlights: cell.string.text = settings.nickHighlights[indexPath.row]
        }

        return cell
    }
    
    private func promptForWord() {
        var title = ""
        
        switch setting! {
        case .Highlights: title = "Enter a Keyword"
        case .Ignores: title = "Enter a Username"
        case .NickHighlights: title = "Enter a Username"
        }

        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "DankGnome"
        })
        
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { action in
            
            if let word = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
                
                switch self.setting! {
                case .Highlights:
                    for string in settings.customHighlights where word.lowercased() == string.lowercased() {
                        return
                    }
                    settings.customHighlights.append(word)
                case .Ignores:
                    for string in settings.ignoredUsers where word.lowercased() == string.lowercased() {
                        return
                    }
                    settings.ignoredUsers.append(word)
                case .NickHighlights:
                    for string in settings.nickHighlights where word.lowercased() == string.lowercased() {
                        return
                    }
                    settings.nickHighlights.append(word)
                }
                
                
               
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

enum SettingType {
    case Highlights
    case Ignores
    case NickHighlights
}
