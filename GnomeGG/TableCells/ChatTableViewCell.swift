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
    @IBOutlet weak var tagColorView: UIView!
    
    let defaultBackgroundColor = UIColor.black
    let highlightBackgroundColor = hexColorStringToUIColor(hex: "06263e")
    let broadcastBackgroundColor = hexColorStringToUIColor(hex: "151515")
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func renderMessage(message: NSMutableAttributedString, messageEnum: DGGMessage, isLog: Bool = false) {
        var backgroundColor = defaultBackgroundColor

        if !isLog {
            switch messageEnum {
            case let .UserMessage(nick, _, _, data):
                if settings.usernameHighlights && settings.dggUsername != "" {
                    if containsWord(string: data, keyword: settings.dggUsername) {
                        backgroundColor = highlightBackgroundColor
                    }
                }
                
                for keyword in settings.customHighlights {
                    if containsWord(string: data, keyword: keyword) {
                        backgroundColor = highlightBackgroundColor
                    }
                }
                
                tagColorView.backgroundColor = UIColor.black
                for userTag in settings.userTags where nick.lowercased() == userTag.nick.lowercased() {
                    tagColorView.backgroundColor = userTag.getColor()
                }
            case .Broadcast: backgroundColor = broadcastBackgroundColor
            case .PrivateMessage: backgroundColor = broadcastBackgroundColor
            default: break
            }
        }
        
        // hack to make it so uitextview is opaque and not rendered as a blended layer
        for subview in messageTextView.subviews {
            subview.backgroundColor = backgroundColor
        }
        
        self.backgroundColor = backgroundColor
        
        
        messageTextView.attributedText = message
        
        
    }
    
}

private func UIColorFromRGB(rgbValue: UInt) -> UIColor {
    return UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}

private func hexColorStringToUIColor(hex: String) -> UIColor {
    return UIColorFromRGB(rgbValue: UInt(hex, radix: 16)!)
}

public func containsWord(string: String, keyword: String) -> Bool {
    let words = string.lowercased().split(separator: " ")
    for word in words {
        if word == keyword.lowercased() {
            return true
        }
    }
    
    return false
}
