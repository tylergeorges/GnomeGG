//
//  ChatTableViewCell.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 5/30/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit

class ChatTableViewCell: UITableViewCell {

    @IBOutlet weak var messageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func rederMessage(message: DGGMessage, flairs: [Flair], emotes: [Emote]) {
        switch message {
        case let .UserMessage(nick, features, timestamp, data):
            renderUserMessage(nick: nick, features: features, date: timestamp, data: data, flairs: flairs, emotes: emotes)
        case let .Combo(timestamp, count, emote):
            renderCombo(emote: emote, count: count, timestamp: timestamp)
        }
        
    }
    
    private func renderUserMessage(nick: String, features: [String], date: Date, data: String, flairs: [Flair], emotes: [Emote]) {
        let fullMessage = NSMutableAttributedString(string: "")
        
        fullMessage.append(formatTimestamp(timestamp: date))
        
        
        var hasFlairs = [Flair]()
        
        for flair in flairs where features.contains(flair.name) {
            hasFlairs.append(flair)
        }
        
        var topPriority = 999
        var topColor = "#FFFFFF"
        
        for flair in hasFlairs.sorted(by: {$0.priority < $1.priority}) {
            if flair.priority < topPriority {
                topPriority = flair.priority
                topColor = flair.color
            }
            
            if !flair.hidden {
                let flairAttachement = NSTextAttachment()
                flairAttachement.image = flair.image
                flairAttachement.bounds = CGRect(x: 0, y: 0, width: flair.width, height: flair.height)
                let flairString = NSMutableAttributedString(attachment: flairAttachement)
                fullMessage.append(NSAttributedString(string: " "))
                fullMessage.append(flairString)
            }
        }
        
        let nickText = " " + nick
        let usernameText = NSMutableAttributedString(string: nickText)
        
        let color = topColor.replacingOccurrences(of: "#", with: "")
        usernameText.addAttribute(.foregroundColor, value: hexColorStringToUIColor(hex: color), range: NSRange(location: 0, length: usernameText.length))
        fullMessage.append(usernameText)
        let messageText = ": " + data
//        let message = NSMutableAttributedString(string: messageText)
        let message = emotifyMessage(message: messageText, emotes: emotes)
        message.addAttribute(.foregroundColor, value: hexColorStringToUIColor(hex: "b9b9b9"), range: NSRange(location: 0, length: message.length))
        fullMessage.append(message)

     
        messageLabel.attributedText = fullMessage
    }
    
    private func renderCombo(emote: Emote, count: Int, timestamp: Date) {
        let fullMessage = NSMutableAttributedString(string: "")
        fullMessage.append(formatTimestamp(timestamp: timestamp))
        fullMessage.append(emotifyMessage(message: emote.prefix, emotes: [emote]))
        
        // mutable for future styling
        // #dedede
        let countText = NSMutableAttributedString(string: String(count))
        countText.addAttribute(.foregroundColor, value: hexColorStringToUIColor(hex: "dedede"), range: NSRange(location: 0, length: countText.length))
        fullMessage.append(countText)
        
        let xText = NSMutableAttributedString(string: " X ")
        xText.addAttribute(.foregroundColor, value: hexColorStringToUIColor(hex: "dedede"), range: NSRange(location: 0, length: xText.length))
        fullMessage.append(xText)
        
        let comboText = NSMutableAttributedString(string: "C-C-C-COMBO")
        comboText.addAttribute(.foregroundColor, value: hexColorStringToUIColor(hex: "999999"), range: NSRange(location: 0, length: comboText.length))
        fullMessage.append(comboText)
        
        messageLabel.attributedText = fullMessage
    }
    
    private func formatTimestamp(timestamp: Date) -> NSMutableAttributedString {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let dateText = NSMutableAttributedString(string: dateFormatter.string(from: timestamp))
        dateText.addAttribute(.foregroundColor, value: hexColorStringToUIColor(hex: "414141"), range: NSRange(location: 0, length: dateText.length))
        
        return dateText
    }
    
    private func emotifyMessage(message: String, emotes: [Emote]) -> NSMutableAttributedString {
        let words = message.split(separator: " ")
        let emotifiedMessage = NSMutableAttributedString(string: "")
        
        for (i, word) in words.enumerated() {
            var isEmote = false
            for emote in emotes where emote.prefix == word {
                isEmote = true
                let emoteAttachement = NSTextAttachment()
                emoteAttachement.image = emote.image
                emoteAttachement.bounds = CGRect(x: 0, y: -5, width: emote.width, height: emote.height)
                let emoteString = NSMutableAttributedString(attachment: emoteAttachement)
                emotifiedMessage.append(emoteString)
            }
            
            if !isEmote {
                emotifiedMessage.append(NSAttributedString(string: String(word)))
            }
            
            if i + 1 != words.count {
                emotifiedMessage.append(NSAttributedString(string: " "))
            }
        }
        
        return emotifiedMessage
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

}
