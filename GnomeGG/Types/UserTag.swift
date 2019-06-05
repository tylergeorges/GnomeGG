//
//  UserTag.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/3/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import Foundation

class UserTag: NSObject, NSCoding {
    var color: String
    var nick: String
    
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
}
