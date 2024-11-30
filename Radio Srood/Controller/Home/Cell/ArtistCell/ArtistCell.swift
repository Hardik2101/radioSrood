
import UIKit

class ArtistCell: UITableViewCell {
    
    @IBOutlet private weak var artistCollectionView: UICollectionView!
    
    var featuredArtist: [FeaturedArtist] = []
    var presentView: HomeViewController?
    var presentViewBrowse: BrowseTabVC?

    override func awakeFromNib() {
        super.awakeFromNib()
        artistCollectionView.delegate = self
        artistCollectionView.dataSource = self
    }
    
    func reloadCollectionView() {
        artistCollectionView.reloadData()
    }
    
}

//MARK: - collectionview delegates methods
extension ArtistCell: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return featuredArtist.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.registerAndGet(ArtistCollectionCell.self, indexPath: indexPath) {
            cell.featuredArtist = featuredArtist[indexPath.row]
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let presentView = presentView {
            presentView.groupID = featuredArtist[indexPath.row].featuredTrackID
            presentView.homeHeader = .featuredArtist
            if presentView.interstitial != nil {
                presentView.interstitial.present(fromRootViewController: presentView)
            } else {
                presentView.openMusicPlayerViewController()
            }
        }
    }
    
}
