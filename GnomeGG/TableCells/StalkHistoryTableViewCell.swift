//
//  StalkHistoryTableViewCell.swift
//  GnomeGG
//
//  Created by Kirill Voloshin on 6/2/19.
//  Copyright © 2019 Kirill Voloshin. All rights reserved.
//

import UIKit

class StalkHistoryTableViewCell: UITableViewCell {

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func renderCell(record: StalkRecord) {
        nameLabel.text = record.nick
        let dateFormatter = DateFormatter()
        if Calendar.current.isDateInToday(record.date) {
            dateFormatter.dateFormat = "HH:mm"
        } else {
            dateFormatter.dateFormat = "MM/dd HH:mm"
        }
        
        timeLabel.text = dateFormatter.string(from: record.date)
    }

}
