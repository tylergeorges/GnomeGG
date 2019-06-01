//
//  dggMessage.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 5/30/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import Foundation
import SwiftyJSON

class DGGParser {
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
                
                // memes
                if nick == "Polecat" || nick == "PolarBearFur" {
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
}

enum DGGMessage {
    case UserMessage(nick: String, features: [String], timestamp: Date, data: String)
    case Combo(timestamp: Date, count: Int, emote: Emote)
    case Broadcast(timestamp: Date, data: String)
}
