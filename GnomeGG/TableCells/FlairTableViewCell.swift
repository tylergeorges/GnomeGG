//
//  FlairTableViewCell.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/3/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit

class FlairTableViewCell: UITableViewCell {

    @IBOutlet weak var flairImageLabel: UILabel!
    @IBOutlet weak var isHiddenLabel: UILabel!
    @IBOutlet weak var flairLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func renderFlair(flair: Flair) {
        isHiddenLabel.text = flair.hidden ? "Hidden" : "Visible"
        
        let flairLabelString = NSMutableAttributedString(string: flair.label)
        flairLabelString.addAttribute(.foregroundColor, value: hexColorStringToUIColor(hex: flair.color.replacingOccurrences(of: "#", with: "")), range: NSRange(location: 0, length: flairLabelString.length))
        
        flairLabel.attributedText = flairLabelString
        
        let flairAttachement = NSTextAttachment()
        flairAttachement.image = flair.image
        flairAttachement.bounds = CGRect(x: 0, y: -5, width: flair.width, height: flair.height)
        let flairString = NSMutableAttributedString(attachment: flairAttachement)
        flairImageLabel.attributedText = flairString
    }
    
    private func hexColorStringToUIColor(hex: String) -> UIColor {
        return UIColorFromRGB(rgbValue: UInt(hex, radix: 16)!)
    }
    
    private func UIColorFromRGB(rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
