//
//  MessageListingTableViewCell.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/7/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit

class MessageListingTableViewCell: UITableViewCell {

    @IBOutlet weak var unreadOrTotalLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var lastMessageDate: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func renderListing(listing: MessageListing) {
        let dateFormatter = DateFormatter()
        if Calendar.current.isDateInToday(listing.timestamp) {
            dateFormatter.dateFormat = "HH:mm"
        } else {
            dateFormatter.dateFormat = "MM/dd HH:mm"
        }
        
        lastMessageDate.text = dateFormatter.string(from: listing.timestamp)
        usernameLabel.text = listing.user
        lastMessageLabel.attributedText = DGGParser.styleText(message: listing.message)
        if listing.unread > 0 {
            unreadOrTotalLabel.text = "(" + String(listing.unread) + ")"
            unreadOrTotalLabel.alpha = 1
        } else {
            unreadOrTotalLabel.alpha = 0.5
            unreadOrTotalLabel.text = String(listing.read)
            unreadOrTotalLabel.backgroundColor = nil
        }
    }

}
