//
//  AppleTableViewCell.swift
//  GlobalOneV2
//
//  Created by appteve on 24/04/2017.
//  Copyright © 2017 Appteve. All rights reserved.
//

import UIKit

class AppleTableViewCell: UITableViewCell {
    
    @IBOutlet weak var trackName: UILabel!
    @IBOutlet weak var trackImage: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
