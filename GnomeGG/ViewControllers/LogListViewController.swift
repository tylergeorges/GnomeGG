//
//  LogListViewController.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/7/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class LogListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nvActivityIndicator: NVActivityIndicatorView!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var logListBackoff = 100
    
    var viewType: ViewType = .MonthView
    var selectedIndex: Int!
    var activeURL: String?
    
    var list = [LogListing]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
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
        return list.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "logListingCell", for: indexPath) as! LogListTableViewCell
        cell.selectionStyle = .none
        cell.renderListing(listing: list[indexPath.row])
        
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
    
     // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == "userLogSegue" {
                let destVC = segue.destination as! LogViewController
                destVC.overrustleURL = list[selectedIndex].urlComponent
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
