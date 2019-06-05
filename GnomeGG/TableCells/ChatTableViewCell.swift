//
//  ChatTableViewCell.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 5/30/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit

class ChatTableViewCell: UITableViewCell {

    @IBOutlet weak var messageTextView: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func renderMessage(message: NSMutableAttributedString, messageEnum: DGGMessage, isLog: Bool = false) {
        // hack to make it so uitextview is opaque and not rendered as a blended layer
        for subview in messageTextView.subviews {
            subview.backgroundColor = UIColor.black;
        }
        
        messageTextView.attributedText = message
        
        
//        self.backgroundColor = hexColorStringToUIColor(hex: "151515")
    }
    
}
