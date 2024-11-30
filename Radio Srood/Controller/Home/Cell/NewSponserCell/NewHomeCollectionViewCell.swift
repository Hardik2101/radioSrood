//
//  NewHomeCollectionViewCell.swift
//  Radio Srood
//
//  Created by Hardik Chotaliya on 24/07/24.
//  Copyright © 2024 Appteve. All rights reserved.
//

import UIKit

class NewHomeCollectionViewCell: UICollectionViewCell {


    @IBOutlet weak var imgView: UIImageView!
    
    @IBOutlet weak var lblArtistName: UILabel!
    
    @IBOutlet weak var lblSongName: UILabel!
    
    var featuredTop: FeaturedTop? {
        didSet {
            if let featuredTopSong = featuredTop {
                if let url = URL(string: featuredTopSong.featuredImage ?? "") {
                    imgView.af_setImage(withURL: url, placeholderImage: UIImage(named: "RS_Logo_BLS_640x300.png"))
                }
                lblSongName.text = featuredTopSong.featuredTitle
                lblArtistName.text = featuredTopSong.featuredSubtitle
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        imgView.layer.cornerRadius = 6.0
        
    }

}
