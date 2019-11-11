//
//  UserNote.swift
//  GnomeGG
//
//  Created by Polecat on 10/7/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import Foundation

class UserNote: NSObject, NSCoding {
    var nick: String
    var note: String

    init(nick: String, note: String) {
        self.nick = nick
        self.note = note
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        let nick = aDecoder.decodeObject(forKey: "nick") as! String
        let note = aDecoder.decodeObject(forKey: "note") as! String
        
        self.init(nick: nick, note: note)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(nick, forKey: "nick")
        aCoder.encode(note, forKey: "note")
    }
}
