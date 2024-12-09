//
//  BrowsePopularCollCell.swift
//  Radio Srood
//
//  Created by B on 13/11/24.
//  Copyright © 2024 Radio Srood Inc. All rights reserved.
//

import UIKit

class BrowsePopularCollCell: UICollectionViewCell {
    @IBOutlet private weak var mainView: UIView!
    @IBOutlet private weak var bgImage: UIImageView!
    @IBOutlet private weak var trackImage: UIImageView!
    @IBOutlet private weak var lblCount: UILabel!
    @IBOutlet private weak var lblSongName: UILabel!
    @IBOutlet private weak var lblArtistName: UILabel!
    
    var trendingTrack: TrendingTrack? {
        didSet {
            if let trendingTrack = trendingTrack {
                if let url = URL(string: trendingTrack.trendingCover) {
                    trackImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                    bgImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                }
                lblCount.text = "\(trendingTrack.shomara)"
                lblSongName.text = trendingTrack.trendingTrack
                lblArtistName.text = trendingTrack.trendingArtist
            }
        }
    }
    
    var popularTrack: PopularTrack? {
        didSet {
            if let popularTrack = popularTrack {
                if let url = URL(string: popularTrack.popularCover) {
                    trackImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                    bgImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                }
                lblCount.text = "\(popularTrack.shomara)"
                lblSongName.text = popularTrack.popularTrack
                lblArtistName.text = popularTrack.popularArtist
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        mainView.layer.cornerRadius = 5
        bgImage.layer.cornerRadius = 5
        trackImage.layer.cornerRadius = 5
    }
}
