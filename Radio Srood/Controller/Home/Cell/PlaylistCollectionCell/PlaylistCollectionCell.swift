
import UIKit

class PlaylistCollectionCell: UICollectionViewCell {
    
    @IBOutlet private weak var playlsitImage: UIImageView!
    @IBOutlet private weak var lblPlaylistName: UILabel!
    
    var playlist: Playlist? {
        didSet {
            if let playlist = playlist {
                if let url = URL(string: playlist.playlistCover) {
                    playlsitImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                }
                lblPlaylistName.text = playlist.playlistName
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func draw(_ rect: CGRect) {
        playlsitImage.layer.cornerRadius = 5
    }
    
}
