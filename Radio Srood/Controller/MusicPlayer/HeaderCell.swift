//
//  HeaderCell.swift
//  Radio Srood
//
//  Created by Hardik Chotaliya on 02/06/24.
//  Copyright © 2024 Appteve. All rights reserved.
//

import UIKit

class HeaderCell: UITableViewCell {
    @IBOutlet weak var headerLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        headerLabel.textColor = .white.withAlphaComponent(1.1)
        headerLabel.font = UIFont(name: "Avenir Next Ultra Light", size: 19)

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
