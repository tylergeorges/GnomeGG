//
//  LogListViewController.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/7/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class LogListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nvActivityIndicator: NVActivityIndicatorView!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var logListBackoff = 100
    
    var viewType: ViewType = .MonthView
    var selectedIndex: Int!
    var activeURL: String?
    
    var list = [LogListing]()
    var filteredList = [LogListing]()

    override func viewDidLoad() {
        super.viewDidLoad()

        colorSearchbar()
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        tableView.rowHeight = 50
        
        tableView.isHidden = true
        loadingLabel.isHidden = false
        loadingLabel.text = "Loading Logs"
        imageView.isHidden = false
        
        loadLogs()
        
    }
    
    private func loadLogs() {
        nvActivityIndicator.startAnimating()
        
        switch viewType {
        case .MonthView:
            dggAPI.getMonthLogs(completionHandler: { messages in
                self.nvActivityIndicator.stopAnimating()
                
                if let messages = messages {
                    self.tableView.isHidden = false
                    self.loadingLabel.isHidden = false
                    self.imageView.isHidden = false
                    self.list = messages
                    self.filteredList = messages
                    self.tableView.reloadData()
                } else {
                    self.loadingLabel.text = "Error Getting Logs"
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(self.logListBackoff), execute: {
                        self.logListBackoff = self.logListBackoff * 2
                        self.loadLogs()
                    })
                }
                
            })
        case .DayView:
            dggAPI.getDaysLogs(for: activeURL!, completionHandler: { messages in
                self.nvActivityIndicator.stopAnimating()
                
                if let messages = messages {
                    self.tableView.isHidden = false
                    self.loadingLabel.isHidden = false
                    self.imageView.isHidden = false
                    self.list = messages
                    self.filteredList = messages
                    self.tableView.reloadData()
                } else {
                    self.loadingLabel.text = "Error Getting Logs"
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(self.logListBackoff), execute: {
                        self.logListBackoff = self.logListBackoff * 2
                        self.loadLogs()
                    })
                }
            })
        case .UserView:
            dggAPI.getUserListLogs(for: activeURL!, completionHandler: { messages in
                self.nvActivityIndicator.stopAnimating()
                
                if let messages = messages {
                    self.tableView.isHidden = false
                    self.loadingLabel.isHidden = false
                    self.imageView.isHidden = false
                    self.list = messages
                    self.filteredList = messages
                    self.tableView.reloadData()
                } else {
                    self.loadingLabel.text = "Error Getting Logs"
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(self.logListBackoff), execute: {
                        self.logListBackoff = self.logListBackoff * 2
                        self.loadLogs()
                    })
                }
            })
        }
    }
    
    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "logListingCell", for: indexPath) as! LogListTableViewCell
        cell.selectionStyle = .none
        cell.renderListing(listing: filteredList[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let selectedItem = list[selectedIndex]
        if selectedItem.isFolder {
            let vc = storyboard.instantiateViewController(withIdentifier: "LogListViewController") as! LogListViewController
            vc.activeURL = selectedItem.urlComponent
            vc.viewType = viewType.next()
            navigationController?.pushViewController(vc, animated: true)
        } else {
            performSegue(withIdentifier: "userLogSegue", sender: self)
        }
    }
    
    // MARK: - SearchBar
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.text = ""
        doneSearching()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard searchText != "" else {
            doneSearching()
            return
        }
        
        let search = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        var found = [LogListing]()
        for listing in list {
            if listing.title.lowercased().contains(search) {
                found.append(listing)
            }
        }
        
        filteredList = found
        tableView.reloadData()
    }
    
    private func doneSearching() {
        filteredList = list
        tableView.reloadData()
        searchBar.resignFirstResponder()
    }
    
     // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == "userLogSegue" {
                let destVC = segue.destination as! OverrustleLogViewController
                destVC.overrustleURL = filteredList[selectedIndex].urlComponent
            }
        }
    }
    
    // MARK: - Private
    private func colorSearchbar() {
        searchBar.setImage(UIImage(named: "search"), for: .search, state: .normal)
        for subView in searchBar.subviews
        {
            for subView1 in subView.subviews
            {
                
                if subView1 is UITextField {
                    subView1.backgroundColor = UIColor.gray
                }
            }
            
        }
    }
}

enum ViewType {
    case MonthView
    case DayView
    case UserView
    
    func next() -> ViewType {
        switch self {
        case .MonthView: return .DayView
        case .DayView: return .UserView
        case .UserView: return .UserView
        }
    }
}
