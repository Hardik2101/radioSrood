//
//  BrowseShowAllVC.swift
//  Radio Srood
//
//  Created by B on 11/11/24.
//  Copyright © 2024 Radio Srood Inc. All rights reserved.
//

import UIKit

class BrowseShowAllVC: UIViewController {
    @IBOutlet weak var tblShowAll: UITableView! {
        didSet {
            self.tblShowAll.delegate = self
            self.tblShowAll.dataSource = self
        }
    }
    
    var parentVC: BrowseTabVC!
    
    var playlist: [Playlist] = []
    var newReleases: [NewRelease] = []
    var popularTracks: [PopularTrack] = []
    var radioModels: [RadioModelData] = []
    var recenltPlayed: [SongModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareView()
    }
    
    private func prepareView() {
        tblShowAll.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: Common.screenSize.width, height: 0.1))
        tblShowAll.tableFooterView = nil
        if #available(iOS 15.0, *) {
            tblShowAll.sectionHeaderTopPadding = 0
        }
        
        self.navigationItem.hidesBackButton = true
        let backImage =  UIImage(named: "left-arrow")
        let customBackButton = UIBarButtonItem(image: backImage, style: .plain, target: self, action: #selector(popToBack))
        customBackButton.tintColor = .white
        self.navigationItem.leftBarButtonItem = customBackButton
    }
}


extension BrowseShowAllVC {
    func playlistCell(with tableView: UITableView, item: Playlist) -> UITableViewCell {
        if let cell = tableView.registerAndGet(cell: BrowseShowAllTableCell.self) {
            cell.selectionStyle = .none
            cell.playlist = item
            cell.newRelease = nil
            cell.popularTrack = nil
            cell.radioData = nil
            cell.recenltPlayed = nil
            return cell
        }
        return UITableViewCell()
    }
    
    func newReleaseCell(with tableView: UITableView, item: NewRelease) -> UITableViewCell {
        if let cell = tableView.registerAndGet(cell: BrowseShowAllTableCell.self) {
            cell.selectionStyle = .none
            cell.playlist = nil
            cell.newRelease = item
            cell.popularTrack = nil
            cell.radioData = nil
            cell.recenltPlayed = nil
            return cell
        }
        return UITableViewCell()
    }
    
    func popularTrackCell(with tableView: UITableView, item: PopularTrack) -> UITableViewCell {
        if let cell = tableView.registerAndGet(cell: BrowseShowAllTableCell.self) {
            cell.selectionStyle = .none
            cell.playlist = nil
            cell.newRelease = nil
            cell.popularTrack = item
            cell.radioData = nil
            cell.recenltPlayed = nil
            return cell
        }
        return UITableViewCell()
    }
    
    func radioModelCell(with tableView: UITableView, item: RadioModelData) -> UITableViewCell {
        if let cell = tableView.registerAndGet(cell: BrowseShowAllTableCell.self) {
            cell.selectionStyle = .none
            cell.playlist = nil
            cell.newRelease = nil
            cell.popularTrack = nil
            cell.radioData = item
            cell.recenltPlayed = nil
            return cell
        }
        return UITableViewCell()
    }
    
    func recentlyPlayedCell(with tableView: UITableView, item: SongModel) -> UITableViewCell {
        if let cell = tableView.registerAndGet(cell: BrowseShowAllTableCell.self) {
            cell.selectionStyle = .none
            cell.playlist = nil
            cell.newRelease = nil
            cell.popularTrack = nil
            cell.radioData = nil
            cell.recenltPlayed = item
            return cell
        }
        return UITableViewCell()
    }
}

////////////////MARK: - tableview delegates methods
extension BrowseShowAllVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        [playlist.count, newReleases.count, popularTracks.count, radioModels.count, recenltPlayed.count].max()!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch true {
        case !playlist.isEmpty: return playlistCell(with: tableView, item: playlist[indexPath.row])
        case !newReleases.isEmpty: return newReleaseCell(with: tableView, item: newReleases[indexPath.row])
        case !popularTracks.isEmpty: return popularTrackCell(with: tableView, item: popularTracks[indexPath.row])
        case !radioModels.isEmpty: return radioModelCell(with: tableView, item: radioModels[indexPath.row])
        case !recenltPlayed.isEmpty: return recentlyPlayedCell(with: tableView, item: recenltPlayed[indexPath.row])
        default:
            let cell = UITableViewCell()
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let groidupID: Int
        let trackType: Browseheader
        switch true {
        case !playlist.isEmpty:
            groidupID = playlist[indexPath.row].playlistid
            trackType = .playlist
        case !newReleases.isEmpty:
            groidupID = newReleases[indexPath.row].newReleasesTrackID
            trackType = .newMusic
        case !popularTracks.isEmpty:
            groidupID = popularTracks[indexPath.row].popularTrackID
            trackType = .popularMusic
        case !radioModels.isEmpty:
            parentVC.onClickRadio(at: indexPath.row)
            return
        case !recenltPlayed.isEmpty:
            parentVC.browseheader =  .recentlyPlay
            if parentVC.interstitial != nil {
                parentVC.recenltPlayedindex = indexPath.row
                parentVC.interstitial.present(fromRootViewController: parentVC)
            } else {
                parentVC.openMyMusicPlayerViewController(index: indexPath.row)
            }
            return
        default: 
            return
        }
        
        if let presentViewBrowse = parentVC {
            // Handle selection for presentViewBrowse (BrowseTabVC)
            presentViewBrowse.groupID = groidupID
            presentViewBrowse.browseheader = trackType
            
            if presentViewBrowse.interstitial != nil {
                presentViewBrowse.interstitial.present(fromRootViewController: presentViewBrowse)
            } else {
                presentViewBrowse.openMusicPlayerViewController()
            }
        }
    }
}
