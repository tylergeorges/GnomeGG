//
//  FlairListViewController.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/3/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit

class FlairListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{

    @IBOutlet weak var flairTableView: UITableView!

    let flairs = dggAPI.flairs.sorted(by: {$0.priority < $1.priority })
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        flairTableView.rowHeight = 45
        
        flairTableView.delegate = self
        flairTableView.dataSource = self
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - TableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return flairs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "flairCell", for: indexPath) as! FlairTableViewCell
        cell.selectionStyle = .none
        cell.renderFlair(flair: flairs[indexPath.row])
        
        return cell
    }
}
