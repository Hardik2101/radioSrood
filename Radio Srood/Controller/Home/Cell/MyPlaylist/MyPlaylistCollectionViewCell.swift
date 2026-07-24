//
//  MyPlaylistCollectionViewCell.swift
//  Radio Srood
//
//  Created by Tech on 24/05/2023.
//  Copyright © 2023 Appteve. All rights reserved.
//

import UIKit

class MyPlaylistCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imgSong: UIImageView!
    @IBOutlet weak var lblSongName: UILabel!
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        imgSong.layer.cornerRadius = 3
        imgSong.clipsToBounds = true
    }

    func configureView(track: SongModel) {
        lblSongName.text = track.track
        if let url = track.thumbnailArtCoverURL {
            imgSong.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
        }
    }

    func configureTrackView(track: PlayListModel) {
        lblSongName.text = track.name
        applyPlaylistCover(track: track, to: imgSong)
    }
}

class MyAllPlaylistCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imgSong: UIImageView!
    @IBOutlet weak var lblSongName: UILabel!
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        imgSong.layer.cornerRadius = 3
        imgSong.clipsToBounds = true
    }

    func configureView(track: SongModel) {
        lblSongName.text = track.track
        if let url = track.thumbnailArtCoverURL {
            imgSong.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
        }
    }

    func configureTrackView(track: PlayListModel) {
        lblSongName.text = track.name
        applyPlaylistCover(track: track, to: imgSong)
    }
}

private func applyPlaylistCover(track: PlayListModel, to imageView: UIImageView) {
    if !track.coverImagePath.isEmpty,
       FileManager.default.fileExists(atPath: track.coverImagePath),
       let image = UIImage(contentsOfFile: track.coverImagePath) {
        imageView.image = image
        return
    }

    if let firstSong = track.songs.first,
       let url = URL(string: firstSong.artcover_200), !firstSong.artcover_200.isEmpty {
        imageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
    } else if let firstSong = track.songs.first,
              !firstSong.artcover.isEmpty,
              let url = URL(string: firstSong.artcover) {
        imageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
    } else {
        imageView.image = UIImage(named: "Lav_Radio_Logo.png")
    }
}
