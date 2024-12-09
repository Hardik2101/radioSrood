//
//  BrowseShowAllTableCell.swift
//  Radio Srood
//
//  Created by B on 11/11/24.
//  Copyright © 2024 Radio Srood Inc. All rights reserved.
//

import UIKit

class BrowseShowAllTableCell: UITableViewCell {
    @IBOutlet private weak var itemImage: UIImageView!
    @IBOutlet private weak var lblTitle: UILabel!
    @IBOutlet private weak var lblSubtitle: UILabel!
    
    var playlist: Playlist? {
        didSet {
            if let playlist = playlist {
                if let url = URL(string: playlist.playlistCover) {
                    itemImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                }
                lblTitle.text = playlist.playlistName ?? playlist.playlist
                lblSubtitle.text = playlist.playlistName ?? playlist.playlist
            }
        }
    }
    
    var newRelease: NewRelease? {
        didSet {
            if let newRelease = newRelease {
                if let url = URL(string: newRelease.newReleasesCover) {
                    itemImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                }
                lblTitle.text = newRelease.newReleasesTrack
                lblSubtitle.text = newRelease.newReleasesArtist
            }
        }
    }
    
    var popularTrack: PopularTrack? {
        didSet {
            if let popularTrack = popularTrack {
                if let url = URL(string: popularTrack.popularCover) {
                    itemImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                    //bgImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                }
                //lblCount.text = "\(popularTrack.shomara)"
                lblTitle.text = popularTrack.popularTrack
                lblSubtitle.text = popularTrack.popularArtist
            }
        }
    }
    
    var radioData: RadioModelData? {
        didSet {
            if let newRelease = radioData {
                if let url = URL(string: newRelease.radioImage) {
                    itemImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                }
                lblTitle.text = newRelease.radioTitle
                lblSubtitle.text = ""
            }
        }
    }

    var recenltPlayed: SongModel? {
        didSet {
            if let recent = recenltPlayed {
                if let url = URL(string: recent.artcover) {
                    itemImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                }
                //artworkImage.image = podcastObject.image
                lblTitle.text = recent.track
                lblSubtitle.text = recent.artist
            }
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        itemImage.layer.cornerRadius = 5
    }
}
