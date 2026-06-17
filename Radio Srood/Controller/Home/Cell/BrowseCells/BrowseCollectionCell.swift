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

    private var imageHeightConstraint: NSLayoutConstraint?
    private var usesCircularImage = false
    private let defaultImageHeight: CGFloat = 180
    
    var playlist: Playlist? {
        didSet {
            usesCircularImage = false
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
            usesCircularImage = false
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
            usesCircularImage = false
            if let featuredBrowsePlaylist = featuredBrowsePlaylist {
                if let url = URL(string: featuredBrowsePlaylist.coverURL) {
                    itemImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                }
                lblTitle.text = featuredBrowsePlaylist.title
                lblSubtitle.text = "\(featuredBrowsePlaylist.tracksCount) Tracks"
                lblSubtitle.isHidden = false
            }
        }
    }

    var similarArtist: SimilarArtist? {
        didSet {
            usesCircularImage = similarArtist != nil
            if let similarArtist = similarArtist {
                itemImage.contentMode = .scaleAspectFill
                if let url = URL(string: similarArtist.artistPhoto) {
                    itemImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                } else {
                    itemImage.image = UIImage(named: "Lav_Radio_Logo.png")
                }
                lblTitle.text = similarArtist.artist
                let dari = similarArtist.artistDari?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if !dari.isEmpty, dari.caseInsensitiveCompare(similarArtist.artist) != .orderedSame {
                    lblSubtitle.text = dari
                    lblSubtitle.isHidden = false
                } else {
                    lblSubtitle.text = nil
                    lblSubtitle.isHidden = true
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageHeightConstraint = itemImage.constraints.first { $0.firstAttribute == .height }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        usesCircularImage = false
        itemImage.contentMode = .scaleAspectFit
        imageHeightConstraint?.constant = defaultImageHeight
        playlist = nil
        newRelease = nil
        featuredBrowsePlaylist = nil
        similarArtist = nil
        itemImage.image = nil
        lblTitle.text = nil
        lblSubtitle.text = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        itemImage.clipsToBounds = true

        if usesCircularImage {
            let diameter = itemImage.bounds.width
            imageHeightConstraint?.constant = diameter
            itemImage.layer.cornerRadius = diameter / 2
        } else {
            imageHeightConstraint?.constant = defaultImageHeight
            itemImage.layer.cornerRadius = 4
        }
    }
}
