//
//  StringSettingTableViewCell.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/4/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit

class StringSettingTableViewCell: UITableViewCell {

    @IBOutlet weak var string: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
