//
//  BrowseCollectionCell.swift
//  Radio Srood
//
//  Created by B on 08/11/24.
//  Copyright © 2024 Radio Srood Inc. All rights reserved.
//

import UIKit

class BrowseCollectionCell: UICollectionViewCell {
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

    var featuredBrowsePlaylist: BrowseFeaturedPlaylist? {
        didSet {
            if let featuredBrowsePlaylist = featuredBrowsePlaylist {
                if let url = URL(string: featuredBrowsePlaylist.coverURL) {
                    itemImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                }
                lblTitle.text = featuredBrowsePlaylist.title
                lblSubtitle.text = "\(featuredBrowsePlaylist.likesCount) Likes"
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        playlist = nil
        newRelease = nil
        featuredBrowsePlaylist = nil
        itemImage.image = nil
        lblTitle.text = nil
        lblSubtitle.text = nil
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        itemImage.layer.cornerRadius = 16
        itemImage.clipsToBounds = true
    }
}
