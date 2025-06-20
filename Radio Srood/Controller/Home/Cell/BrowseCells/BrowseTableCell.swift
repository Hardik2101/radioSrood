//
//  BrowseTableCell.swift
//  Radio Srood
//
//  Created by B on 08/11/24.
//  Copyright © 2024 Radio Srood Inc. All rights reserved.
//

import UIKit

class BrowseTableCell: UITableViewCell {
    @IBOutlet private weak var playlistCollectionView: UICollectionView!
    @IBOutlet private weak var playlistHeightConstraint: NSLayoutConstraint!
    
    var playlist: [Playlist] = []
    var newReleases: [NewRelease] = []
    var presentView: HomeViewController?
    var presentViewBrowse: BrowseTabVC?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        playlistCollectionView.delegate = self
        playlistCollectionView.dataSource = self
    }
    
    func reloadCollectionView() {
        playlistCollectionView.reloadData()
    }
    
}

//MARK: - collectionview delegates methods
extension BrowseTableCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return !playlist.isEmpty ? playlist.count : newReleases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.registerAndGet(BrowseCollectionCell.self, indexPath: indexPath) {
            if !playlist.isEmpty {
                cell.playlist = playlist[indexPath.row]
            } else {
                cell.newRelease = newReleases[indexPath.row]
            }
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let groupID: Int
        if !playlist.isEmpty {
            let selectedPlaylist = playlist[indexPath.row]
            groupID = selectedPlaylist.playlistid
        } else {
            let selectedNewReleases = newReleases[indexPath.row]
            groupID = selectedNewReleases.newReleasesTrackID
        }
        
        if let presentView = presentView {
            // Handle selection for presentView (HomeViewController)
            presentView.groupID = groupID
            presentView.homeHeader = !playlist.isEmpty ? .playlists : .hotTrackes
            
            if presentView.interstitial != nil {
                presentView.interstitial.present(fromRootViewController: presentView)
            } else {
                presentView.openMusicPlayerViewController()
            }
        } else if let presentViewBrowse = presentViewBrowse {
            // Handle selection for presentViewBrowse (BrowseTabVC)
            presentViewBrowse.groupID = groupID
            presentViewBrowse.browseheader = !playlist.isEmpty ? .playlist : .newMusic
            
            if presentViewBrowse.interstitial != nil {
                presentViewBrowse.interstitial.present(fromRootViewController: presentViewBrowse)
            } else {
                presentViewBrowse.openMusicPlayerViewController()
            }
        }
    }
}
