//
//  dggMessage.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 5/30/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import Foundation
import SwiftyJSON

let chatFontSize: CGFloat = 14
let dggMessageColor = "b9b9b9"

class DGGParser {
    static let customCute = ["Polecat", "PolarBearFur"]
    
    static func parseUserMessage(message: String) -> DGGMessage? {
        if let dataFromString = message.data(using: .utf8, allowLossyConversion: false) {
            do {
                let json = try JSON(data: dataFromString)
                
                guard let nick = json["nick"].string else {
                    return nil
                }
                
                
                guard let featuresArray = json["features"].array else {
                    return nil
                }
                
                var features = featuresArray.map { $0.stringValue }
                
                if DGGParser.customCute.contains(nick) {
                    features.append("polecat")
                }

                guard let unixTimestamp = json["timestamp"].double else {
                    return nil
                }
                
                let timestamp = Date(timeIntervalSince1970: unixTimestamp / 1000)
                
                guard let data = json["data"].string else {
                    return nil
                }
                
                return .UserMessage(nick: nick, features: features, timestamp: timestamp, data: data)
                
            } catch {
                print("Error parsing message")
                return nil
            }
        } else {
            return nil
        }
    }
    
    static func parseBroadcastMessage(message: String) -> DGGMessage? {
        if let dataFromString = message.data(using: .utf8, allowLossyConversion: false) {
            do {
                let json = try JSON(data: dataFromString)
                
                guard let unixTimestamp = json["timestamp"].double else {
                    return nil
                }
                
                let timestamp = Date(timeIntervalSince1970: unixTimestamp / 1000)
                
                guard let data = json["data"].string else {
                    return nil
                }
                
                return .Broadcast(timestamp: timestamp, data: data)
                
            } catch {
                print("Error parsing message")
                return nil
            }
        } else {
            return nil
        }
    }
    
    static func parseNamesMessage(message: String) -> DGGMessage? {
        if let dataFromString = message.data(using: .utf8, allowLossyConversion: false) {
            do {
                let json = try JSON(data: dataFromString)
                
                guard let connectionCount = json["connectioncount"].int else {
                    return nil
                }
                
                guard let users = json["users"].array else {
                    return nil
                }
                
                var parsedUsers = [User]()
                
                for userJson in users {
                    guard let nick = userJson["nick"].string else {
                        continue
                    }
                    
                    guard let features = userJson["features"].array else {
                        continue
                    }
                    
                    var parsedFeatures = features.map {$0.stringValue}
                    
                    if DGGParser.customCute.contains(nick) {
                        parsedFeatures.append("polecat")
                    }
                    
                    parsedUsers.append(User(nick: nick, features: parsedFeatures))
                }
                
                return .Names(connectionCount: connectionCount, users: parsedUsers)
                
            } catch {
                print("Error parsing message")
                return nil
            }
        } else {
            return nil
        }
    }
    
    static func parseMuteMessage(message: String) -> DGGMessage? {
        if let dataFromString = message.data(using: .utf8, allowLossyConversion: false) {
            do {
                let json = try JSON(data: dataFromString)
                
                guard let nick = json["nick"].string else {
                    return nil
                }
                    
                let features = json["features"].arrayValue.map {$0.stringValue}
                
                guard let unixTimestamp = json["timestamp"].double else {
                    return nil
                }
                
                let timestamp = Date(timeIntervalSince1970: unixTimestamp / 1000)
                
                guard let target = json["data"].string else {
                    return nil
                }
                
                return .Mute(nick: nick, features: features, timestamp: timestamp, target: target)
                
            } catch {
                print("Error parsing message")
                return nil
            }
        } else {
            return nil
        }
    }
    
    static func parseBanMessage(message: String) -> DGGMessage? {
        if let dataFromString = message.data(using: .utf8, allowLossyConversion: false) {
            do {
                let json = try JSON(data: dataFromString)
                
                guard let nick = json["nick"].string else {
                    return nil
                }
                
                let features = json["features"].arrayValue.map {$0.stringValue}
                
                guard let unixTimestamp = json["timestamp"].double else {
                    return nil
                }
                
                let timestamp = Date(timeIntervalSince1970: unixTimestamp / 1000)
                
                guard let target = json["data"].string else {
                    return nil
                }
                
                return .Ban(nick: nick, features: features, timestamp: timestamp, target: target)
                
            } catch {
                print("Error parsing message")
                return nil
            }
        } else {
            return nil
        }
    }
    
    static func parseDoorMessage(message: String) -> String? {
        if let dataFromString = message.data(using: .utf8, allowLossyConversion: false) {
            do {
                let json = try JSON(data: dataFromString)
                
                guard let nick = json["nick"].string else {
                    return nil
                }

                return nick
                
            } catch {
                print("Error parsing message")
                return nil
            }
        } else {
            return nil
        }
    }
    
    static func parseChatErrorMessage(message: String) -> DGGMessage? {
        let error = message.replacingOccurrences(of: "\"", with: "")
        var errorMessage = error
        switch error {
        case "toomanyconnections": errorMessage = "Too Many Chat Connections"
        case "protocolerror": errorMessage = "Protocol Error"
        case "needlogin": errorMessage = "You Are Not Logged In"
        case "nopermission": errorMessage = "You Do Not Have Permissions To Perform This Action"
        case "invalidmsg": errorMessage = "Invalid Message"
        case "muted": errorMessage = "You Are Muted"
        case "submode": errorMessage = "The Chat Is In Sub Mode"
        case "throttled": errorMessage = "You Are Sending Messages Too Fast"
        case "duplicate": errorMessage = "Message Identical To Your Last Message"
        case "notfound": errorMessage = "User Not Found"
        case "needbanreason": errorMessage = "Please Provide a Ban Reason"
        default: break
        }
        return .ChatErrorMessage(data: errorMessage)
    }
    
    static func parsePrivateMessage(message: String) -> DGGMessage? {
        if let dataFromString = message.data(using: .utf8, allowLossyConversion: false) {
            do {
                let json = try JSON(data: dataFromString)
                
                guard let nick = json["nick"].string else {
                    return nil
                }
                
                guard let unixTimestamp = json["timestamp"].double else {
                    return nil
                }
                
                let timestamp = Date(timeIntervalSince1970: unixTimestamp / 1000)
                
                guard let data = json["data"].string else {
                    return nil
                }
                
                guard let id = json["messageid"].int else {
                    return nil
                }
                
                return .PrivateMessage(timestamp: timestamp, nick: nick, data: data, id: id)
                
            } catch {
                print("Error parsing message")
                return nil
            }
        } else {
            return nil
        }
    }
    
    static func styleText(message: String) -> NSMutableAttributedString {
        return styleMessage(message: message, regularMessage: false, isLog: true)
    }
}

public enum DGGMessage {
    case UserMessage(nick: String, features: [String], timestamp: Date, data: String)
    case Combo(timestamp: Date, count: Int, emote: Emote)
    case Broadcast(timestamp: Date, data: String)
    case Names(connectionCount: Int, users: [User])
    case Disconnected(reason: String)
    case Connecting
    case Mute(nick: String, features: [String], timestamp: Date, target: String)
    case Ban(nick: String, features: [String], timestamp: Date, target: String)
    case InternalMessage(data: String)
    case ChatErrorMessage(data: String)
    case PrivateMessage(timestamp: Date, nick: String, data: String, id: Int)
}

public func ==(lhs: DGGMessage, rhs: DGGMessage) -> Bool {
    switch (lhs, rhs) {
    case let (.UserMessage(nick1, features1, timestamp1, data1),   .UserMessage(nick2, features2, timestamp2, data2)):
        return nick1 == nick2 && features1 == features2 && timestamp1 == timestamp2 && data1 == data2
    case let (.Combo(timestamp1, count1, emote1), .Combo(timestamp2, count2, emote2)):
        return timestamp1 == timestamp2 && count1 == count2 && emote1.prefix == emote2.prefix
    case let (.Broadcast(timestamp1, data1), .Broadcast(timestamp2, data2)):
        return timestamp1 == timestamp2 && data1 == data2
    case let (.Disconnected(reason1), .Disconnected(reason: reason2)):
        return reason1 == reason2
    case (.Connecting, .Connecting):
        return true
    default:
        return false
    }
}

public func renderMessage(message: DGGMessage, isLog: Bool = false) -> NSMutableAttributedString {
    switch message {
    case let .UserMessage(nick, features, timestamp, data):
        if isLog && features.count == 0 {
            let customFeatures = getFeatures(for: nick)
            return renderUserMessage(nick: nick, features: customFeatures, date: timestamp, data: data, isLog: true)
        } else {
            return renderUserMessage(nick: nick, features: features, date: timestamp, data: data, isLog: false)
        }
    case let .Combo(timestamp, count, emote):
        return renderCombo(emote: emote, count: count, timestamp: timestamp)
    case let .Broadcast(timestamp, data):
        return renderBroadcast(timestamp: timestamp, data: data)
    case let .Names(connectionCount, Users):
        return renderNames(connectionCount: connectionCount, userCount: Users.count)
    case let .Disconnected(reason):
        return renderDisconnect(reason: reason)
    case .Connecting:
        return renderConnecting()
    case let .Mute(nick, _, timestamp, target):
        return renderMute(timestamp: timestamp, banner: nick, target: target)
    case let .Ban(nick, _, timestamp, target):
        return renderBan(timestamp: timestamp, banner: nick, target: target)
    case let .InternalMessage(data):
        return renderInternalMessage(message: data)
    case let .ChatErrorMessage(data):
        return renderChatErrorMessage(message: data)
    case let .PrivateMessage(timestamp, nick, data, _):
        return renderPrivateMessage(nick: nick, timestamp: timestamp, data: data)
    }
}

private func renderUserMessage(nick: String, features: [String], date: Date, data: String, isLog: Bool = false) -> NSMutableAttributedString {
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
    let message = styleMessage(message: data, isLog: isLog)
    fullMessage.append(message)

    return fullMessage
}

private func renderPrivateMessage(nick: String, timestamp: Date, data: String) -> NSMutableAttributedString {
    let fullMessage = NSMutableAttributedString(string: "")
    
    let spacer = NSMutableAttributedString(string: " ")
    fullMessage.append(formatTimestamp(timestamp: timestamp))
    fullMessage.append(spacer)
    let usernameText = NSMutableAttributedString(string: nick)
    usernameText.addAttribute(.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: usernameText.length))
    fullMessage.append(usernameText)
    fullMessage.append(spacer)
    let actualMessage = styleMessage(message: "whispered: " + data, regularMessage: false, isLog: true)
    actualMessage.addAttribute(.foregroundColor, value: hexColorStringToUIColor(hex: dggMessageColor), range: NSRange(location: 0, length: actualMessage.length))
    fullMessage.append(actualMessage)
    
    return fullMessage
}

private func customFlair(image: UIImage, width: Int, height: Int) -> NSMutableAttributedString {
    let flairAttachement = NSTextAttachment()
    flairAttachement.image = image
    flairAttachement.bounds = CGRect(x: 0, y: -5, width: width, height: height)
    let flairString = NSMutableAttributedString(attachment: flairAttachement)
    return flairString
}

private func renderCombo(emote: Emote, count: Int, timestamp: Date) -> NSMutableAttributedString {
    let fullMessage = NSMutableAttributedString(string: "")
    fullMessage.append(formatTimestamp(timestamp: timestamp))
    fullMessage.append(NSAttributedString(string: " "))
    fullMessage.append(NSAttributedString(string: " "))
    fullMessage.append(styleMessage(message: emote.prefix, regularMessage: false))
    fullMessage.append(NSAttributedString(string: " "))
    
    
    let countText = NSMutableAttributedString(string: String(count))
    countText.addAttribute(.foregroundColor, value: hexColorStringToUIColor(hex: "dedede"), range: NSRange(location: 0, length: countText.length))
    var fontSize = chatFontSize
    
    if count < 3 {
        fontSize = chatFontSize
    } else if count < 5 {
        fontSize = chatFontSize + 1
    } else if count < 10 {
        fontSize = chatFontSize + 3
    } else if count < 20 {
        fontSize = chatFontSize + 5
    } else if count < 30 {
        fontSize = chatFontSize + 7
    } else if count < 40 {
        fontSize = chatFontSize + 9
    } else if count < 50 {
        fontSize = chatFontSize + 11
    } else if count < 60 {
        fontSize = chatFontSize + 13
    } else {
        fontSize = chatFontSize + 15
    }
    
    let font = UIFont(name: "Roboto-Regular", size: fontSize)
    countText.addAttribute(.font, value: font!, range: NSRange(location: 0, length: countText.length))
    
    fullMessage.append(countText)
    
    let xText = NSMutableAttributedString(string: " X ")
    xText.addAttribute(.foregroundColor, value: hexColorStringToUIColor(hex: "dedede"), range: NSRange(location: 0, length: xText.length))
    fullMessage.append(xText)
    
    let comboText = NSMutableAttributedString(string: "C-C-C-COMBO")
    comboText.addAttribute(.foregroundColor, value: hexColorStringToUIColor(hex: "999999"), range: NSRange(location: 0, length: comboText.length))
    fullMessage.append(comboText)
    
    return fullMessage
}

private func renderBroadcast(timestamp: Date, data: String) -> NSMutableAttributedString {
    let fullMessage = NSMutableAttributedString(string: "")
    fullMessage.append(formatTimestamp(timestamp: timestamp))
    fullMessage.append(NSAttributedString(string: " "))
    fullMessage.append(styleMessage(message: data))
    fullMessage.addAttribute(.foregroundColor, value: hexColorStringToUIColor(hex: "edea12"), range: NSRange(location: 0, length: fullMessage.length))
    return fullMessage
}

private func renderNames(connectionCount: Int, userCount: Int) -> NSMutableAttributedString {
    let spacer = NSAttributedString(string: " ")
    let fullMessage = NSMutableAttributedString(string: "")
    fullMessage.append(formatTimestamp(timestamp: Date()))
    fullMessage.append(spacer)
    fullMessage.append(customFlair(image: UIImage(named: "infobadge")!, width: 16, height: 16))
    fullMessage.append(spacer)
    let username = (settings.dggUsername != "") ? settings.dggUsername : ((settings.dggCookie != "") ? "User" : "Anonymous")
    let template = "Connected to Websocket as %@. %d connections, %d users."
    let message = NSMutableAttributedString(string: String(format: template, username, connectionCount, userCount))
    message.addAttribute(.foregroundColor, value: hexColorStringToUIColor(hex: "FFFFFFF"), range: NSRange(location: 0, length: message.length))
    fullMessage.append(message)
    
    return fullMessage
}

private func renderConnecting() -> NSMutableAttributedString {
    let spacer = NSAttributedString(string: " ")
    let fullMessage = NSMutableAttributedString(string: "")
    fullMessage.append(formatTimestamp(timestamp: Date()))
    fullMessage.append(spacer)
    fullMessage.append(customFlair(image: UIImage(named: "infobadge")!, width: 16, height: 16))
    fullMessage.append(spacer)
    let message = NSMutableAttributedString(string: "Connecting to Chat...")
    message.addAttribute(.foregroundColor, value: hexColorStringToUIColor(hex: "FFFFFFF"), range: NSRange(location: 0, length: message.length))
    fullMessage.append(message)
    return fullMessage
}

private func renderDisconnect(reason: String) -> NSMutableAttributedString {
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
    
    return fullMessage
}

private func renderMute(timestamp: Date, banner: String, target: String) -> NSMutableAttributedString {
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
    
    
    return fullMessage
}

private func renderBan(timestamp: Date, banner: String, target: String) -> NSMutableAttributedString {
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
    
    return fullMessage
}

private func renderInternalMessage(message: String) -> NSMutableAttributedString {
    let spacer = NSAttributedString(string: " ")
    let fullMessage = NSMutableAttributedString(string: "")
    fullMessage.append(formatTimestamp(timestamp: Date()))
    fullMessage.append(spacer)
    fullMessage.append(customFlair(image: UIImage(named: "infobadge")!, width: 16, height: 16))
    fullMessage.append(spacer)
    let message = NSMutableAttributedString(string: message)
    message.addAttribute(.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: message.length))
    fullMessage.append(message)
    return fullMessage
}

private func renderChatErrorMessage(message: String) -> NSMutableAttributedString {
    let spacer = NSAttributedString(string: " ")
    let fullMessage = NSMutableAttributedString(string: "")
    fullMessage.append(formatTimestamp(timestamp: Date()))
    fullMessage.append(spacer)
    fullMessage.append(customFlair(image: UIImage(named: "errorbadge")!, width: 16, height: 16))
    fullMessage.append(spacer)
    let message = NSMutableAttributedString(string: message)
    message.addAttribute(.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: message.length))
    fullMessage.append(message)
    return fullMessage
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

private func styleMessage(message: String, regularMessage: Bool = true, isLog: Bool = false) -> NSMutableAttributedString {
    var words = message.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ")
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
        var isEmote = false
        
        for emote in dggAPI.emotes where emote.prefix == word {
            guard !(emote.bbdgg && !settings.bbdggEmotes) else {
                continue
            }
            
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
