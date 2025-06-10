//
//  BrowsePopularTableCell.swift
//  Radio Srood
//
//  Created by B on 13/11/24.
//  Copyright © 2024 Radio Srood Inc. All rights reserved.
//

import UIKit

class BrowsePopularTableCell: UITableViewCell {

    @IBOutlet private weak var trackCollectionView: UICollectionView!
    @IBOutlet private weak var trackHeightConstraint: NSLayoutConstraint!
    
    var trendingTracks: [TrendingTrack] = []
    var popularTracks: [PopularTrack] = []
    var todayTopPic: [RadioSuroodTodayPickItem] = []

    var presentViewBrowse: BrowseTabVC?
    var presentViewBrowse1: HomeViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        trackCollectionView.delegate = self
        trackCollectionView.dataSource = self
    }
    
    func reloadCollectionView() {
        setCellHeight()
        trackCollectionView.reloadData()
    }
    
    private func setCellHeight() {
        let topInset: CGFloat = 10
        let bottomInset: CGFloat = 10
        let lineSpacing: CGFloat = 10
        let numberOfRows: CGFloat = 5

        let cellHeight = getCellSize()
        let totalSpacing = lineSpacing * (numberOfRows - 1)
        let totalHeight = (cellHeight * numberOfRows) + totalSpacing + topInset + bottomInset

        trackHeightConstraint.constant = totalHeight
    }

    private func getCellSize() -> CGFloat {
        return 80
    }
}

// MARK: - UICollectionView Delegates & DataSource

extension BrowsePopularTableCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if !todayTopPic.isEmpty {
            return todayTopPic.count
        } else if !trendingTracks.isEmpty {
            return trendingTracks.count
        } else {
            return popularTracks.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.registerAndGet(BrowsePopularCollCell.self, indexPath: indexPath) {
            if !todayTopPic.isEmpty {
                cell.todayToppic = todayTopPic[indexPath.row]
            } else if !trendingTracks.isEmpty {
                cell.trendingTrack = trendingTracks[indexPath.row]
            } else {
                cell.popularTrack = popularTracks[indexPath.row]
            }
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let presentView = presentViewBrowse {
            presentView.groupID = popularTracks[indexPath.row].popularTrackID
            presentView.browseheader = .popularMusic
            if presentView.interstitial != nil {
                presentView.interstitial.present(fromRootViewController: presentView)
            } else {
                presentView.openMusicPlayerViewController()
            }
        } else if let presentView1 = presentViewBrowse1 {
            presentView1.groupID = todayTopPic[indexPath.row].TTPID
            presentView1.homeHeader = .todayTopPic
            if presentView1.interstitial != nil {
                presentView1.interstitial.present(fromRootViewController: presentView1)
            } else {
                presentView1.openMusicPlayerViewController()
            }
        }
            
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: UIScreen.main.bounds.width - 20, height: getCellSize())
    }
}

//    private func setCellHeight() {
//        let topInset: CGFloat = 10
//        let bottomInset: CGFloat = 10
//        let lineSpace: CGFloat = 8
//        let columnCount = ceil(CGFloat((!trendingTracks.isEmpty ? trendingTracks.count : popularTracks.count)/2))
//        trackHeightConstraint.constant = (getCellSize() * columnCount) + (lineSpace * (columnCount-1)) + topInset + bottomInset
//    }
//    // Optional: Add spacing for the items if needed, but set minimumLineSpacing to 0 for full-page swipe effect
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
//        return UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0) // No left or right inset for smooth page swipe
//    }
//}
