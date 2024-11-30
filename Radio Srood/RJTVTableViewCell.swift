//
//  RJTVTableViewCell.swift
//  Radio Srood
//
//  Created by Hardik Chotaliya on 17/11/24.
//  Copyright © 2024 Radio Srood Inc. All rights reserved.
//

import UIKit

class RJTVTableViewCell: UITableViewCell {
    
    @IBOutlet weak var vwMain: UIView!
    
    @IBOutlet weak var lblWatchNow: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        vwMain.backgroundColor = .gray
        vwMain.layer.cornerRadius = 8
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
}
