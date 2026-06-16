//
//  BrowseTableCell.swift
//  Radio Srood
//
//  Created by B on 08/11/24.
//  Copyright © 2024 Radio Srood Inc. All rights reserved.
//

import UIKit

class BrowseTableCell: UITableViewCell {
    @IBOutlet  weak var playlistCollectionView: UICollectionView!
    @IBOutlet private weak var playlistHeightConstraint: NSLayoutConstraint!

    weak var browseDelegate: BrowseTableCellDelegate?
    
    var playlist: [Playlist] = []
    var featuredBrowsePlaylists: [BrowseFeaturedPlaylist] = []
    var newReleases: [NewRelease] = []
    var artistProfileTracks: [Track] = []
    var similarArtists: [SimilarArtist] = []
    var presentView: HomeViewController?
    var presentViewBrowse: BrowseTabVC?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        playlistCollectionView.delegate = self
        playlistCollectionView.dataSource = self
        if let layout = playlistCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumLineSpacing = 6
            layout.minimumInteritemSpacing = 6
            layout.sectionInset = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
            layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        browseDelegate = nil
        playlist.removeAll()
        featuredBrowsePlaylists.removeAll()
        newReleases.removeAll()
        artistProfileTracks.removeAll()
        similarArtists.removeAll()
    }
    
    func reloadCollectionView() {
        playlistCollectionView.reloadData()
    }
    
}

protocol BrowseTableCellDelegate: AnyObject {
    func browseTableCell(_ cell: BrowseTableCell, didSelectTrackAt index: Int, tracks: [Track])
    func browseTableCell(_ cell: BrowseTableCell, didSelectSimilarArtistAt index: Int, artists: [SimilarArtist])
}

extension BrowseTableCellDelegate {
    func browseTableCell(_ cell: BrowseTableCell, didSelectTrackAt index: Int, tracks: [Track]) {}
    func browseTableCell(_ cell: BrowseTableCell, didSelectSimilarArtistAt index: Int, artists: [SimilarArtist]) {}
}

//MARK: - collectionview delegates methods
extension BrowseTableCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if !artistProfileTracks.isEmpty { return artistProfileTracks.count }
        if !similarArtists.isEmpty { return similarArtists.count }
        if !featuredBrowsePlaylists.isEmpty { return featuredBrowsePlaylists.count }
        return !playlist.isEmpty ? playlist.count : newReleases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.registerAndGet(BrowseCollectionCell.self, indexPath: indexPath) {
            if !artistProfileTracks.isEmpty {
                cell.newRelease = artistProfileTracks[indexPath.row].asNewRelease()
            } else if !similarArtists.isEmpty {
                cell.similarArtist = similarArtists[indexPath.row]
            } else if !featuredBrowsePlaylists.isEmpty {
                cell.featuredBrowsePlaylist = featuredBrowsePlaylists[indexPath.row]
            } else if !playlist.isEmpty {
                cell.playlist = playlist[indexPath.row]
            } else {
                cell.newRelease = newReleases[indexPath.row]
            }
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !artistProfileTracks.isEmpty {
            browseDelegate?.browseTableCell(self, didSelectTrackAt: indexPath.row, tracks: artistProfileTracks)
            return
        }

        if !similarArtists.isEmpty {
            browseDelegate?.browseTableCell(self, didSelectSimilarArtistAt: indexPath.row, artists: similarArtists)
            return
        }

        if !featuredBrowsePlaylists.isEmpty {
            let selectedPlaylist = featuredBrowsePlaylists[indexPath.row]
            presentViewBrowse?.openFeaturedPlaylist(selectedPlaylist)
            return
        }

        let groupID: Int
        if !playlist.isEmpty {
            let selectedPlaylist = playlist[indexPath.row]
            groupID = selectedPlaylist.playlistid
        } else {
            let selectedNewReleases = newReleases[indexPath.row]
            groupID = selectedNewReleases.newReleasesTrackID
        }
        
        if let presentView = presentView {
            presentView.groupID = groupID
            presentView.homeHeader = !playlist.isEmpty ? .playlists : .hotTrackes
            
            if presentView.interstitial != nil {
                presentView.interstitial.present(fromRootViewController: presentView)
            } else {
                presentView.openMusicPlayerViewController()
            }
        } else if let presentViewBrowse = presentViewBrowse {
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
