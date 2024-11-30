import UIKit

class PlaylistCell: UITableViewCell {
    
    @IBOutlet private weak var playlistCollectionView: UICollectionView!
    @IBOutlet private weak var playlistHeightConstraint: NSLayoutConstraint!
    
    var playlist: [Playlist] = []
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
extension PlaylistCell: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return playlist.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.registerAndGet(PlaylistCollectionCell.self, indexPath: indexPath) {
            cell.playlist = playlist[indexPath.row]
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedPlaylist = playlist[indexPath.row]
        
        if let presentView = presentView {
            // Handle selection for presentView (HomeViewController)
            presentView.groupID = selectedPlaylist.playlistid
            presentView.homeHeader = .playlists
            
            if presentView.interstitial != nil {
                presentView.interstitial.present(fromRootViewController: presentView)
            } else {
                presentView.openMusicPlayerViewController()
            }
        } else if let presentViewBrowse = presentViewBrowse {
            // Handle selection for presentViewBrowse (BrowseTabVC)
            presentViewBrowse.groupID = selectedPlaylist.playlistid
            presentViewBrowse.browseheader = .playlist
            
            if presentViewBrowse.interstitial != nil {
                presentViewBrowse.interstitial.present(fromRootViewController: presentViewBrowse)
            } else {
                presentViewBrowse.openMusicPlayerViewController()
            }
        }
    }
}
