//
//  StalkRecord.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/2/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import Foundation

class StringRecord: NSObject, NSCoding {
    var date: Date
    var string: String
    
    init(string: String, date: Date) {
        self.string = string
        self.date = date
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        let string = aDecoder.decodeObject(forKey: "string") as! String
        let date = aDecoder.decodeObject(forKey: "date") as! Date
        
        self.init(string: string, date: date)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(string, forKey: "string")
        aCoder.encode(date, forKey: "date")
    }
}
