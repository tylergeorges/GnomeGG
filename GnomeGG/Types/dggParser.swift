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
                    
                    let parsedFeatures = features.map {$0.stringValue}
                    
                    parsedUsers.append(User(nick: nick, features: parsedFeatures))
                }
                
                return .Names(connectionCount: connectionCount, Users: parsedUsers)
                
            } catch {
                print("Error parsing message")
                return nil
            }
        } else {
            return nil
        }
    }
    
    // MUTE {"nick":"Bot","features":["protected","bot"],"timestamp":1559360986565,"data":"Majestic_Gopher"}
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
}

enum DGGMessage {
    case UserMessage(nick: String, features: [String], timestamp: Date, data: String)
    case Combo(timestamp: Date, count: Int, emote: Emote)
    case Broadcast(timestamp: Date, data: String)
    case Names(connectionCount: Int, Users: [User])
    case Disconnected(reason: String)
    case Connecting
    case Mute(nick: String, features: [String], timestamp: Date, target: String)
}
