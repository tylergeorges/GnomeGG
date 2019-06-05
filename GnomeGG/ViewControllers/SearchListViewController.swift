//
//  SearchListViewController.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/5/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit

class SearchListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet weak var newSearchButton: UIButton!
    @IBOutlet weak var searchTableView: UITableView!
    
    
    var searchKeyword: String?
    
    var searchHistory = [StringRecord]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchTableView.dataSource = self
        searchTableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        searchTableView.rowHeight = 45
        searchHistory = settings.lookupHistory.sorted(by: {$0.date.timeIntervalSince1970 > $1.date.timeIntervalSince1970})
        searchTableView.reloadData()
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
        
        if identifier == "searchKeyword" {
            let destVC = segue.destination as! SearchViewController
            destVC.searchTerm = searchKeyword
        }
    }
    
    // MARK: - TableView
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        searchKeyword = searchHistory[indexPath.row].string
        for (i, record) in settings.lookupHistory.enumerated() where record.string.lowercased() == searchHistory[indexPath.row].string.lowercased() {
            settings.lookupHistory[i].date = Date()
        }
        
        self.performSegue(withIdentifier: "searchKeyword", sender: self)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            for (i, record) in settings.lookupHistory.enumerated() where record.string.lowercased() == searchHistory[indexPath.row].string.lowercased() {
                settings.lookupHistory.remove(at: i)
            }
            searchHistory.remove(at: indexPath.row)
            tableView.reloadData()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchHistory.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchKeywordCell", for: indexPath) as! stringRecordTableViewCell
        cell.selectionStyle = .none
        
        cell.renderCell(record: searchHistory[indexPath.row])
        
        return cell
    }
    
    private func promptForTerm() {
        let alert = UIAlertController(title: "Enter a Search Term", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "NSFW"
        })
        
        alert.addAction(UIAlertAction(title: "Search", style: .default, handler: { action in
            
            if let keyword = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
                var inArray = false
                
                for (i, record) in settings.lookupHistory.enumerated() where record.string.lowercased() == keyword.lowercased() {
                    inArray = true
                    settings.lookupHistory[i].date = Date()
                }
                
                if !inArray {
                    settings.lookupHistory.append(StringRecord(string: keyword, date: Date()))
                }
                
                self.searchKeyword = keyword
                self.performSegue(withIdentifier: "searchKeyword", sender: nil)
            }
        }))
        
        self.present(alert, animated: true)
    }
    
    @IBAction func searchTap(_ sender: Any) {
        promptForTerm()
    }
    
}
