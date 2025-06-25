//
//  MyPlaylistCollectionViewCell.swift
//  Radio Srood
//
//  Created by Tech on 24/05/2023.
//  Copyright © 2023 Appteve. All rights reserved.
//

import UIKit

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
        if let url = updatedArtcoverURL(from: track.artcover) {
            imgSong.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
        }
    }

    func configureTrackView(track: PlayListModel) {
        if let firstSong = track.songs.first,
           let url = updatedArtcoverURL(from: firstSong.artcover) {
            imgSong.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
        } else {
            imgSong.image = UIImage(named: "Lav_Radio_Logo.png")
        }
        lblSongName.text = track.name
    }

    private func updatedArtcoverURL(from originalURL: String) -> URL? {
        guard var components = URLComponents(string: originalURL) else { return nil }
        
        var queryItems = components.queryItems ?? []
        if let existingIndex = queryItems.firstIndex(where: { $0.name == "s" }) {
            queryItems[existingIndex].value = "200"
        } else {
            queryItems.append(URLQueryItem(name: "s", value: "200"))
        }
        components.queryItems = queryItems
        return components.url
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
        if let url = updatedArtcoverURL(from: track.artcover) {
            imgSong.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
        }
    }

    func configureTrackView(track: PlayListModel) {
        if let firstSong = track.songs.first,
           let url = updatedArtcoverURL(from: firstSong.artcover) {
            imgSong.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
        } else {
            imgSong.image = UIImage(named: "Lav_Radio_Logo.png")
        }
        lblSongName.text = track.name
    }

    private func updatedArtcoverURL(from originalURL: String) -> URL? {
        guard var components = URLComponents(string: originalURL) else { return nil }
        
        var queryItems = components.queryItems ?? []
        if let existingIndex = queryItems.firstIndex(where: { $0.name == "s" }) {
            queryItems[existingIndex].value = "200"
        } else {
            queryItems.append(URLQueryItem(name: "s", value: "200"))
        }
        components.queryItems = queryItems
        return components.url
    }
}
