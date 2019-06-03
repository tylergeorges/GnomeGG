//
//  StalkListViewController.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/2/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit

class StalkListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var newUserButton: UIButton!
    @IBOutlet weak var stalkedTableView: UITableView!
    
    var selectedUser: String?
    
    var stalkHistory = [StalkRecord]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        stalkedTableView.dataSource = self
        stalkedTableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        stalkedTableView.rowHeight = 45
        stalkHistory = settings.stalkHistory.sorted(by: {$0.date.timeIntervalSince1970 > $1.date.timeIntervalSince1970})
        stalkedTableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        
        if identifier == "stalkUser" {
            let destVC = segue.destination as! StalkViewController
            destVC.stalkedUser = selectedUser
        }
    }
    
    // MARK: - TableView
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedUser = stalkHistory[indexPath.row].nick
        for (i, record) in settings.stalkHistory.enumerated() where record.nick.lowercased() == stalkHistory[indexPath.row].nick.lowercased() {
            settings.stalkHistory[i].date = Date()
        }
        
        self.performSegue(withIdentifier: "stalkUser", sender: self)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            for (i, record) in settings.stalkHistory.enumerated() where record.nick.lowercased() == stalkHistory[indexPath.row].nick.lowercased() {
                settings.stalkHistory.remove(at: i)
            }
            stalkHistory.remove(at: indexPath.row)
            tableView.reloadData()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stalkHistory.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "stalkedUserCell", for: indexPath) as! StalkHistoryTableViewCell
        cell.selectionStyle = .none
        
        cell.renderCell(record: stalkHistory[indexPath.row])
        
        return cell
    }
    
    private func promptForName() {
        let alert = UIAlertController(title: "Enter a Username", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "DankGnome"
        })
        
        alert.addAction(UIAlertAction(title: "Stalk", style: .default, handler: { action in
            
            if let username = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
                var inArray = false
                
                for (i, record) in settings.stalkHistory.enumerated() where record.nick.lowercased() == username.lowercased() {
                    inArray = true
                    settings.stalkHistory[i].date = Date()
                }
                
                if !inArray {
                    settings.stalkHistory.append(StalkRecord(nick: username, date: Date()))
                }
                
                self.selectedUser = username
                self.performSegue(withIdentifier: "stalkUser", sender: nil)
            }
        }))
        
        self.present(alert, animated: true)
    }
    
    @IBAction func newUserTap(_ sender: Any) {
        promptForName()
    }
    
}
