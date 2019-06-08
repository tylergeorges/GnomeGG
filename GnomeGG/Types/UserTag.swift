//
//  UserTag.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/3/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import Foundation
import UIKit

class UserTag: NSObject, NSCoding {
    var color: String
    var nick: String
    
    static let colors = ["green", "yellow", "orange", "red", "purple", "blue", "sky", "lime", "pink", "black"]
    static let hexes = ["61BD4F", "F2D600", "FFAB4A", "EB5A46", "C377E0", "0079BF", "00C2E0", "51E898", "FF80CE", "4d4d4d"]
    
    init(nick: String, color: String) {
        self.nick = nick
        self.color = color
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        let nick = aDecoder.decodeObject(forKey: "nick") as! String
        let color = aDecoder.decodeObject(forKey: "color") as! String
        
        self.init(nick: nick, color: color)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(nick, forKey: "nick")
        aCoder.encode(color, forKey: "color")
    }
    
    func getColor() -> UIColor {
        return hexColorStringToUIColor(hex: UserTag.hexes[UserTag.colors.firstIndex(of: color)!])
    }
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
