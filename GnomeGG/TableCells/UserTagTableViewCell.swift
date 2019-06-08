//
//  UserTagTableViewCell.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/8/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit
import DropDown

class UserTagTableViewCell: UITableViewCell {

    @IBOutlet weak var colorLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    var userTag: UserTag!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func renderUserTag(tag: UserTag) {
        self.userTag = tag
        nameLabel.text = tag.nick
        nameLabel.textColor = tag.getColor()
        colorLabel.text = tag.color
        
        colorLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapFunction))
        colorLabel.addGestureRecognizer(tap)
    }
    
    @objc
    func tapFunction(sender:UITapGestureRecognizer) {
        let dropDown = DropDown()
        dropDown.anchorView = colorLabel
        dropDown.dataSource = UserTag.colors
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            self.userTag.color = item
            
            for tag in settings.userTags where tag.nick.lowercased() == self.userTag.nick.lowercased() {
                tag.color = item
            }
            
            let tableView = self.superview as! UITableView
            tableView.reloadData()
        }
        
        dropDown.show()
    }

}
