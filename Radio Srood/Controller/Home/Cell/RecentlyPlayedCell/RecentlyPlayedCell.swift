
import UIKit

class RecentlyPlayedCell: UITableViewCell {
    
    @IBOutlet private weak var recentlyPlayedCollectionView: UICollectionView!
    @IBOutlet private weak var rcentlyPlayedHeightConstraint: NSLayoutConstraint!
    
    var trackData: [PodcastObject] = []
    var presentView: HomeViewController?
    var presentViewBrowse: BrowseTabVC?

    override func awakeFromNib() {
        super.awakeFromNib()
        recentlyPlayedCollectionView.delegate = self
        recentlyPlayedCollectionView.dataSource = self
    }
    
    func reloadCollectionView() {
        rcentlyPlayedHeightConstraint.constant = 230
        recentlyPlayedCollectionView.reloadData()
    }
}

//MARK: - collectionview delegates methods
extension RecentlyPlayedCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return trackData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.registerAndGet(MusicCell.self, indexPath: indexPath) {
            cell.podcastObject = trackData[indexPath.row]
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let presentView = presentView {
            presentView.homeHeader = .recentlyPlayed
            if presentView.interstitial != nil {
                presentView.recenltPlayedindex = indexPath.row
                presentView.interstitial.present(fromRootViewController: presentView)
            } else {
                presentView.openMyMusicPlayerViewController(index: indexPath.row)
            }
        }
        else if let presentView = presentViewBrowse {
            presentView.browseheader = .recentlyPlay
            if presentView.interstitial != nil {
                presentView.recenltPlayedindex = indexPath.row
                presentView.interstitial.present(fromRootViewController: presentView)
            } else {
                presentView.openMyMusicPlayerViewController(index: indexPath.row)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        if presentViewBrowse != nil {
            return CGSize(width: 160, height: 220)
//        }
//        return CGSize(width: 150, height: 148)
    }
}
