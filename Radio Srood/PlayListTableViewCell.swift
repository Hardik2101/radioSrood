//
//  PlayListTableViewCell.swift
//  Radio Srood
//
//  Created by Tech on 22/05/2023.
//  Copyright © 2023 Appteve. All rights reserved.
//

import UIKit

class PlayListTableViewCell: UITableViewCell {

    @IBOutlet weak var lblNoItems: UILabel!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var imgSong: UIImageView!
 
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureView(list : PlayListModel){
        self.lblTitle.text = list.name
        self.lblNoItems.text = "\(list.songs.count) items"
        self.imgSong.image = UIImage(named: "ic_song")
    }

}
