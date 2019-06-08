//
//  EmoteTableViewCell.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/3/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit

class EmoteTableViewCell: UITableViewCell {

    @IBOutlet weak var prefixLabel: UILabel!
    @IBOutlet weak var emoteLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func renderEmote(emote: Emote) {
        prefixLabel.text = emote.prefix
        sourceLabel.text = emote.bbdgg ? "BBDestinyGG" : "DestinyGG"
        
        let emoteAttachement = NSTextAttachment()
        emoteAttachement.image = emote.image
        emoteAttachement.bounds = CGRect(x: 0, y: -5, width: emote.width, height: emote.height)
        let emoteString = NSMutableAttributedString(attachment: emoteAttachement)
        emoteLabel.attributedText = emoteString
    }

}
