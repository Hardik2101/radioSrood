
import UIKit

class TrackCell: UITableViewCell {
    
    @IBOutlet private weak var trackCollectionView: UICollectionView!
    @IBOutlet private weak var trackHeightConstraint: NSLayoutConstraint!

    var trendingTracks: [TrendingTrack] = []
    var popularTracks: [PopularTrack] = []
    var presentView: HomeViewController?

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
        let lineSpace: CGFloat = 8
        let rowCount: CGFloat = ceil(CGFloat((!trendingTracks.isEmpty ? trendingTracks.count : popularTracks.count)/2))
        let totalHeight = (getCellSize() * rowCount) + (lineSpace * (rowCount-1)) + topInset + bottomInset
        trackHeightConstraint.constant = totalHeight
    }
    
    private func getCellSize() -> CGFloat {
        let height: CGFloat = 60
        return height
    }
    
}

//MARK: - collectionview delegates methods
extension TrackCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return !trendingTracks.isEmpty ? trendingTracks.count : popularTracks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.registerAndGet(TrackCollectionCell.self, indexPath: indexPath) {
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
        if let presentView = presentView {
            if !trendingTracks.isEmpty {
                presentView.groupID = trendingTracks[indexPath.row].trendingTrackID
                presentView.homeHeader = .trending
            } else {
                presentView.groupID = popularTracks[indexPath.row].popularTrackID
                presentView.homeHeader = .popularTracks
            }
            if presentView.interstitial != nil {
                presentView.interstitial.present(fromRootViewController: presentView)
            } else {
                presentView.openMusicPlayerViewController()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSpace = (collectionViewLayout as? UICollectionViewFlowLayout)?.minimumInteritemSpacing ?? 0
        let leftInset = (collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset.left ?? 0
        let rightInset = (collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset.right ?? 0
        let space = cellSpace
        let totalInset = leftInset + rightInset + space
        let width = (Common.screenSize.width  - totalInset) / 2
        let height: CGFloat = 50
        return CGSize(width: width, height: getCellSize())
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
