//
//  LogListTableViewCell.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/7/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit

class LogListTableViewCell: UITableViewCell {

    @IBOutlet weak var labelView: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func renderListing(listing: LogListing) {
        labelView.text = listing.title.replacingOccurrences(of: ".txt", with: "")
        if listing.isFolder {
            iconImageView.image = UIImage(named: "folder")
        } else {
            iconImageView.image = UIImage(named: "document")
        }
    }

}
