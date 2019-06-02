//
//  StalkRecord.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/2/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import Foundation

class StalkRecord: NSObject, NSCoding {
    var date: Date
    var nick: String
    
    init(nick: String, date: Date) {
        self.nick = nick
        self.date = date
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        let nick = aDecoder.decodeObject(forKey: "nick") as! String
        let date = aDecoder.decodeObject(forKey: "date") as! Date
        
        self.init(nick: nick, date: date)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(nick, forKey: "nick")
        aCoder.encode(date, forKey: "date")
    }
}
