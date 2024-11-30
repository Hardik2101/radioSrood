
import UIKit

class CurrentRadioCell: UITableViewCell {
    
    @IBOutlet private weak var artworkImage: UIImageView!
    @IBOutlet private weak var lblSongName: UILabel!
    @IBOutlet private weak var lblArtistName: UILabel!
    
    var currentTrackInfo: CurrentTrackInfo? {
        didSet {
            if let currentTrackInfo = currentTrackInfo {
                if let url = URL(string: currentTrackInfo.currentArtCoverInfo) {
                    artworkImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                }
                lblSongName.text = currentTrackInfo.currentTrackInfo
                lblArtistName.text = currentTrackInfo.currentArtistInfo
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
}
