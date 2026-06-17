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
    private var titleWidthConstraint: NSLayoutConstraint?
    private var subtitleWidthConstraint: NSLayoutConstraint?
    private weak var contentStackView: UIStackView?
    private var usesCircularImage = false
    private let defaultImageHeight: CGFloat = 180
    private static let titleFontSize: CGFloat = 16
    private static let subtitleFontSize: CGFloat = 13
    private static let artistTitleFontSize: CGFloat = 15
    private static let artistSubtitleFontSize: CGFloat = 11
    
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
            applyTypography(forArtist: false)
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
            applyTypography(forArtist: false)
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
            applyTypography(forArtist: false)
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
            applyTypography(forArtist: similarArtist != nil)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageHeightConstraint = itemImage.constraints.first { $0.firstAttribute == .height }
        contentStackView = contentView.subviews.first { $0 is UIStackView } as? UIStackView
        applyTypography()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        usesCircularImage = false
        itemImage.contentMode = .scaleAspectFit
        imageHeightConstraint?.constant = defaultImageHeight
        applyTypography()
        applyArtistLayout(isArtist: false)
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
            let diameter = contentView.bounds.width > 0 ? contentView.bounds.width : itemImage.bounds.width
            for constraint in itemImage.constraints where constraint.firstAttribute == .width {
                constraint.constant = diameter
            }
            imageHeightConstraint?.constant = diameter
            itemImage.layer.cornerRadius = diameter / 2

            if let stackView = contentStackView {
                for constraint in stackView.constraints where constraint.firstAttribute == .width {
                    constraint.constant = diameter
                }
            }
        } else {
            imageHeightConstraint?.constant = defaultImageHeight
            itemImage.layer.cornerRadius = 4
        }

        applyArtistLayout(isArtist: usesCircularImage)
    }

    private func applyArtistLayout(isArtist: Bool) {
        contentStackView?.alignment = isArtist ? .center : .leading
        lblTitle.textAlignment = isArtist ? .center : .natural
        lblSubtitle.textAlignment = isArtist ? .center : .natural

        titleWidthConstraint?.isActive = false
        subtitleWidthConstraint?.isActive = false
        titleWidthConstraint = nil
        subtitleWidthConstraint = nil

        guard isArtist, let stackView = contentStackView else { return }

        let titleWidth = lblTitle.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        let subtitleWidth = lblSubtitle.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        titleWidth.isActive = true
        subtitleWidth.isActive = true
        titleWidthConstraint = titleWidth
        subtitleWidthConstraint = subtitleWidth
    }

    private func applyTypography(forArtist: Bool = false) {
        let titleSize = forArtist ? Self.artistTitleFontSize : Self.titleFontSize
        let subtitleSize = forArtist ? Self.artistSubtitleFontSize : Self.subtitleFontSize
        lblTitle.font = UIFont(name: "KohinoorTelugu-Medium", size: titleSize)
            ?? .systemFont(ofSize: titleSize, weight: .medium)
        lblSubtitle.font = UIFont(name: "KohinoorTelugu-Medium", size: subtitleSize)
            ?? .systemFont(ofSize: subtitleSize)
        applyArtistLayout(isArtist: forArtist)
    }
}
