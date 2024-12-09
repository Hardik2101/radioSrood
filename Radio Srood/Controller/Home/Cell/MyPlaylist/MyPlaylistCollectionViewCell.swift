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
    }
    
    func configureView(track : SongModel){
        lblSongName.text = track.track
        if let url = URL(string: track.artcover) {
            imgSong.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
        }
    }
    
    func configureTrackView(track : PlayListModel){
        if track.songs.count > 0 {
            if let url = URL(string: track.songs.first!.artcover) {
                imgSong.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            }
        }
        else{
            imgSong.image = UIImage(named: "Lav_Radio_Logo.png")
        }
        lblSongName.text = track.name
    }

}

class MyAllPlaylistCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imgSong: UIImageView!
    @IBOutlet weak var lblSongName: UILabel!
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        imgSong.layer.cornerRadius = 3
    }
    
    func configureView(track : SongModel){
        lblSongName.text = track.track
        if let url = URL(string: track.artcover) {
            imgSong.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
        }
    }
    
    func configureTrackView(track : PlayListModel){
        if track.songs.count > 0 {
            if let url = URL(string: track.songs.first!.artcover) {
                imgSong.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            }
        }
        else{
            imgSong.image = UIImage(named: "Lav_Radio_Logo.png")
        }
        lblSongName.text = track.name
    }

}
