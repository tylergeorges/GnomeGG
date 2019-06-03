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
    var currentMessage: DGGMessage?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func renderMessage(message: DGGMessage, isLog: Bool = false) {
        if let currentMessage = currentMessage {
            guard !(currentMessage == message) else {
                return
            }
        }
        currentMessage = message
        
        switch message {
        case let .UserMessage(nick, features, timestamp, data):
            if isLog && features.count == 0 {
                let customFeatures = getFeatures(for: nick)
                renderUserMessage(nick: nick, features: customFeatures, date: timestamp, data: data, isLog: true)
            } else {
                renderUserMessage(nick: nick, features: features, date: timestamp, data: data, isLog: false)
            }
        case let .Combo(timestamp, count, emote):
            renderCombo(emote: emote, count: count, timestamp: timestamp)
        case let .Broadcast(timestamp, data):
            renderBroadcast(timestamp: timestamp, data: data)
        case let .Names(connectionCount, Users):
            renderNames(connectionCount: connectionCount, userCount: Users.count)
        case let .Disconnected(reason):
            renderDisconnect(reason: reason)
        case .Connecting:
            renderConnecting()
        case let .Mute(nick, _, timestamp, target):
            renderMute(timestamp: timestamp, banner: nick, target: target)
        case let .Ban(nick, _, timestamp, target):
            renderBan(timestamp: timestamp, banner: nick, target: target)
        }

    }
    
    private func renderUserMessage(nick: String, features: [String], date: Date, data: String, isLog: Bool = false) {
        let fullMessage = NSMutableAttributedString(string: "")
        
        fullMessage.append(formatTimestamp(timestamp: date))
        
        
        var hasFlairs = [Flair]()
        
        for flair in dggAPI.flairs where features.contains(flair.name) {
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
                flairAttachement.bounds = CGRect(x: 0, y: -5, width: flair.width, height: flair.height)
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
        let message = styleMessage(message: data)
        fullMessage.append(message)

        messageTextView.attributedText = fullMessage
    }
    
    private func customFlair(image: UIImage, width: Int, height: Int) -> NSMutableAttributedString {
        let flairAttachement = NSTextAttachment()
        flairAttachement.image = image
        flairAttachement.bounds = CGRect(x: 0, y: -5, width: width, height: height)
        let flairString = NSMutableAttributedString(attachment: flairAttachement)
        return flairString
    }
    
    private func renderCombo(emote: Emote, count: Int, timestamp: Date) {
        let fullMessage = NSMutableAttributedString(string: "")
        fullMessage.append(formatTimestamp(timestamp: timestamp))
        fullMessage.append(NSAttributedString(string: " "))
        fullMessage.append(NSAttributedString(string: " "))
        fullMessage.append(styleMessage(message: emote.prefix, regularMessage: false))
        

        let countText = NSMutableAttributedString(string: String(count))
        countText.addAttribute(.foregroundColor, value: hexColorStringToUIColor(hex: "dedede"), range: NSRange(location: 0, length: countText.length))
        fullMessage.append(countText)
        
        let xText = NSMutableAttributedString(string: " X ")
        xText.addAttribute(.foregroundColor, value: hexColorStringToUIColor(hex: "dedede"), range: NSRange(location: 0, length: xText.length))
        fullMessage.append(xText)
        
        let comboText = NSMutableAttributedString(string: "C-C-C-COMBO")
        comboText.addAttribute(.foregroundColor, value: hexColorStringToUIColor(hex: "999999"), range: NSRange(location: 0, length: comboText.length))
        fullMessage.append(comboText)
        
        messageTextView.attributedText = fullMessage
    }
    
    private func renderBroadcast(timestamp: Date, data: String) {
        let fullMessage = NSMutableAttributedString(string: "")
        fullMessage.append(formatTimestamp(timestamp: timestamp))
        fullMessage.append(NSAttributedString(string: " "))
        fullMessage.append(styleMessage(message: data))
        fullMessage.addAttribute(.backgroundColor, value: hexColorStringToUIColor(hex: "151515"), range: NSRange(location: 0, length: fullMessage.length))
        fullMessage.addAttribute(.foregroundColor, value: hexColorStringToUIColor(hex: "edea12"), range: NSRange(location: 0, length: fullMessage.length))
        messageTextView.attributedText = fullMessage
    }
    
    private func renderNames(connectionCount: Int, userCount: Int) {
        let spacer = NSAttributedString(string: " ")
        let fullMessage = NSMutableAttributedString(string: "")
        fullMessage.append(formatTimestamp(timestamp: Date()))
        fullMessage.append(spacer)
        fullMessage.append(customFlair(image: UIImage(named: "infobadge")!, width: 16, height: 16))
        fullMessage.append(spacer)
        let username = (settings.dggUsername != "") ? settings.dggUsername : "Anonymous"
        let template = "Connected to Websocket as %@. %d connections, %d users."
        let message = NSMutableAttributedString(string: String(format: template, username, connectionCount, userCount))
        message.addAttribute(.foregroundColor, value: hexColorStringToUIColor(hex: "FFFFFFF"), range: NSRange(location: 0, length: message.length))
        fullMessage.append(message)
        
        messageTextView.attributedText = fullMessage
    }
    
    private func renderConnecting() {
        let spacer = NSAttributedString(string: " ")
        let fullMessage = NSMutableAttributedString(string: "")
        fullMessage.append(formatTimestamp(timestamp: Date()))
        fullMessage.append(spacer)
        fullMessage.append(customFlair(image: UIImage(named: "infobadge")!, width: 16, height: 16))
        fullMessage.append(spacer)
        let message = NSMutableAttributedString(string: "Connecting to Chat...")
        message.addAttribute(.foregroundColor, value: hexColorStringToUIColor(hex: "FFFFFFF"), range: NSRange(location: 0, length: message.length))
        fullMessage.append(message)
        messageTextView.attributedText = fullMessage
    }
    
    private func renderDisconnect(reason: String) {
        let spacer = NSAttributedString(string: " ")
        let fullMessage = NSMutableAttributedString(string: "")
        fullMessage.append(formatTimestamp(timestamp: Date()))
        fullMessage.append(spacer)
        fullMessage.append(customFlair(image: UIImage(named: "errorbadge")!, width: 16, height: 16))
        fullMessage.append(spacer)
        let template = "Lost Connection to Server. Reason: %@"
        let message = NSMutableAttributedString(string: String(format: template, reason))
        message.addAttribute(.foregroundColor, value: hexColorStringToUIColor(hex: "FFFFFFF"), range: NSRange(location: 0, length: message.length))
        fullMessage.append(message)
        
        messageTextView.attributedText = fullMessage
    }
    
    private func renderMute(timestamp: Date, banner: String, target: String) {
        let spacer = NSAttributedString(string: " ")
        let fullMessage = NSMutableAttributedString(string: "")
        fullMessage.append(formatTimestamp(timestamp: timestamp))
        fullMessage.append(spacer)
        fullMessage.append(customFlair(image: UIImage(named: "warningbadge")!, width: 16, height: 16))
        fullMessage.append(spacer)
        let template = "%@ muted by %@"
        let message = NSMutableAttributedString(string: String(format: template, target, banner))
        message.addAttribute(.foregroundColor, value: hexColorStringToUIColor(hex: "FFFFFFF"), range: NSRange(location: 0, length: message.length))
        fullMessage.append(message)
        
        messageTextView.attributedText = fullMessage
    }
    
    private func renderBan(timestamp: Date, banner: String, target: String) {
        let spacer = NSAttributedString(string: " ")
        let fullMessage = NSMutableAttributedString(string: "")
        fullMessage.append(formatTimestamp(timestamp: timestamp))
        fullMessage.append(spacer)
        fullMessage.append(customFlair(image: UIImage(named: "warningbadge")!, width: 16, height: 16))
        fullMessage.append(spacer)
        let template = "%@ banned by %@"
        let message = NSMutableAttributedString(string: String(format: template, target, banner))
        message.addAttribute(.foregroundColor, value: hexColorStringToUIColor(hex: "FFFFFFF"), range: NSRange(location: 0, length: message.length))
        fullMessage.append(message)
        
        messageTextView.attributedText = fullMessage
    }
    
    private func formatTimestamp(timestamp: Date) -> NSMutableAttributedString {
        let dateFormatter = DateFormatter()
        if Calendar.current.isDateInToday(timestamp) {
            dateFormatter.dateFormat = "HH:mm"
        } else {
            dateFormatter.dateFormat = "MM/dd HH:mm"
        }
        
        let dateText = NSMutableAttributedString(string: dateFormatter.string(from: timestamp))
        dateText.addAttribute(.foregroundColor, value: hexColorStringToUIColor(hex: "414141"), range: NSRange(location: 0, length: dateText.length))
        
        return dateText
    }
    
    private func styleMessage(message: String, regularMessage: Bool = true) -> NSMutableAttributedString {
        var words = message.split(separator: " ")
        let styledMessage = NSMutableAttributedString(string: "")

        let lowerWords = message.lowercased().split(separator: " ")
        let hasNSFW = lowerWords.contains("nsfw")
        let hasSpoiler = lowerWords.contains("spoiler")
        let hasNSFL = lowerWords.contains("nsfl")
        let isAction = message.lowercased().starts(with: "/me ")
        let isEpic = message.lowercased().starts(with: ">")
        
        if isAction {
            words.removeFirst()
            words.insert(" ", at: 0)
        } else if regularMessage {
            words.insert(":", at: 0)
        }
        
        for (i, word) in words.enumerated() {
            guard word != " " else {
                continue
            }

            var isEmote = false

            for emote in dggAPI.emotes where emote.prefix == word {
                isEmote = true
                let emoteAttachement = NSTextAttachment()
                emoteAttachement.image = emote.image
                emoteAttachement.bounds = CGRect(x: 0, y: -5, width: emote.width, height: emote.height)
                let emoteString = NSMutableAttributedString(attachment: emoteAttachement)
                styledMessage.append(emoteString)
            }
            
            if !isEmote {
                let wordString = String(word)
                if wordString.isValidURL {
                    let urlString = NSMutableAttributedString(string: wordString)
                    urlString.addAttribute(.link, value: wordString, range: NSRange(location: 0, length: urlString.length))

                    urlString.addAttribute(.foregroundColor, value: hexColorStringToUIColor(hex: "02C2FF"), range: NSRange(location: 0, length: urlString.length))
                    if (hasNSFW || hasSpoiler) && !hasNSFL {
                        urlString.addAttribute(.underlineColor, value: hexColorStringToUIColor(hex: "FF0000"), range: NSRange(location: 0, length: urlString.length))
                        urlString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.union(NSUnderlineStyle.patternDot).rawValue, range: NSRange(location: 0, length: urlString.length))
                    }
                    
                    if hasNSFL {
                        urlString.addAttribute(.underlineColor, value: hexColorStringToUIColor(hex: "FFF000"), range: NSRange(location: 0, length: urlString.length))
                        urlString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.union(NSUnderlineStyle.patternDot).rawValue, range: NSRange(location: 0, length: urlString.length))
                    }
                    
                    styledMessage.append(urlString)
                } else {
                    let plainMessage = NSMutableAttributedString(string: wordString)
                    let color = isEpic ? "6CA528" : "b9b9b9"
                    // ok this is epic
                    plainMessage.addAttribute(.foregroundColor, value: hexColorStringToUIColor(hex: color), range: NSRange(location: 0, length: plainMessage.length))
                    styledMessage.append(plainMessage)
                }
                
            }
            
            if i + 1 != words.count {
                styledMessage.append(NSAttributedString(string: " "))
            }
            
            if isAction {
                let italicsFont = UIFont(name: "Helvetica-Oblique", size: 14.0)!
                styledMessage.addAttribute(.font, value: italicsFont, range: NSRange(location: 0, length: styledMessage.length))
            }
            
        }
        
        return styledMessage
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
    
    private func getFeatures(for user: String) -> [String] {
        for u in users where user.lowercased() == u.nick.lowercased() {
            return u.features
        }
        
        return [String]()
    }

}

extension String {
    var isValidURL: Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }
}
