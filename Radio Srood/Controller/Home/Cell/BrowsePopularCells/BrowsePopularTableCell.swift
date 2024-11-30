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
    var presentViewBrowse: BrowseTabVC?
    
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
        let lineSpace: CGFloat = 10
        let rowCount: CGFloat = 5.0
        
        let totalHeight = (getCellSize() * rowCount) + (lineSpace * (rowCount-1)) + topInset + bottomInset
        trackHeightConstraint.constant = totalHeight
    }
    
    private func getCellSize() -> CGFloat {
        let height: CGFloat = 60
        return height
    }
    
}

//MARK: - collectionview delegates methods
extension BrowsePopularTableCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return !trendingTracks.isEmpty ? trendingTracks.count : popularTracks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.registerAndGet(BrowsePopularCollCell.self, indexPath: indexPath) {
            if !trendingTracks.isEmpty {
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
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: UIScreen.main.bounds.width - 20, height: 60)
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
