//
//  BannerAdCell.swift
//  Radio Srood
//
//  Created by Hardik Chotaliya on 01/01/24.
//  Copyright © 2024 Appteve. All rights reserved.
//

import UIKit

class BannerAdCell: UITableViewCell {

    @IBOutlet weak var vwMain: UIView!
    
    @IBOutlet weak var heightOfVw: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        vwMain.translatesAutoresizingMaskIntoConstraints = false

        vwMain.backgroundColor = .clear
        heightOfVw.constant = 65
        vwMain.isHidden = true
    
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
        
    override func prepareForReuse() {
        super.prepareForReuse()
        // Additional cleanup if needed
    }

}
