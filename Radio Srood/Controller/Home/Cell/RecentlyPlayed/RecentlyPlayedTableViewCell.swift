//
//  RecentlyPlayedTableViewCell.swift
//  Radio Srood
//
//  Created by Tech on 24/05/2023.
//  Copyright © 2023 Appteve. All rights reserved.
//

import UIKit

class RecentlyPlayedTableViewCell: UITableViewCell {
    @IBOutlet weak var imgPlayedSong: UIImageView!
    @IBOutlet weak var lblPlayedSongName: UILabel!
    @IBOutlet weak var lblPlayedSongtitle: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func draw(_ rect: CGRect) {
        imgPlayedSong.layer.cornerRadius = 3
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureView(track : SongModel){
        lblPlayedSongtitle.text = track.artist
        lblPlayedSongName.text = track.track
        if let url = URL(string: track.artcover) {
            imgPlayedSong.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
        }
    }

}
