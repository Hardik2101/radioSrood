
import UIKit

class MyPlaylistCell: UITableViewCell {
    
    @IBOutlet private weak var myPlaylistCollectionView: UICollectionView!
    @IBOutlet private weak var myPlaylistHeightConstraint: NSLayoutConstraint!
    
    var playList = [PlayListModel]()
    var presentView: HomeViewController?
    var presentViewBrowse: BrowseTabVC?

    override func awakeFromNib() {
        super.awakeFromNib()
        myPlaylistCollectionView.delegate = self
        myPlaylistCollectionView.dataSource = self
    }
    
    func reloadCollectionView() {
        myPlaylistCollectionView.reloadData()
    }
    
    @objc func longPressed(sender: UILongPressGestureRecognizer) {
        if let presentView = presentView {
            presentView.handleMyPlayListItemEvent(sender.view?.tag ?? 0)
        }
    }
    
}

//MARK: - collectionview delegates methods
extension MyPlaylistCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return playList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.registerAndGet(MyPlaylistCollectionViewCell.self, indexPath: indexPath) {
            cell.configureTrackView(track: self.playList[indexPath.row])
            cell.tag = indexPath.row
            let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
            cell.addGestureRecognizer(longPressRecognizer)
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let presentView = presentView {
            presentView.homeHeader = .myPlaylist
            if presentView.interstitial != nil {
                presentView.myPlayListindex = indexPath.row
                presentView.interstitial.present(fromRootViewController: presentView)
            } else {
                presentView.openMyPlayList(index: indexPath.row)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 112, height: 148)
    }
    
}
