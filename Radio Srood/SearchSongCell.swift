//
//  SearchSongCell.swift
//  Radio Srood
//
//  Created by Hardik on 30/06/25.
//  Copyright © 2025 Radio Srood Inc. All rights reserved.
//

import UIKit

class SearchSongCell: UITableViewCell {
    
    @IBOutlet var imgBg: UIImageView!
    
    @IBOutlet var imgArtist: UIImageView!
    
    @IBOutlet var lblArtistName: UILabel!
    
    @IBOutlet var lblSongName: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
}
