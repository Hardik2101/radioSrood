
import UIKit
import AlamofireImage

class NewReleasesCollectionCell: UICollectionViewCell {
    
    @IBOutlet private weak var artworkImage: UIImageView!
    @IBOutlet private weak var lblSongName: UILabel!
    @IBOutlet private weak var lblArtistName: UILabel!
    
    var newRelease: NewRelease? {
        didSet {
            if let newRelease = newRelease {
                if let url = URL(string: newRelease.newReleasesCover ?? "") {
                    artworkImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                }
                lblSongName.text = newRelease.newReleasesTrack
                lblArtistName.text = newRelease.newReleasesArtist
            }
        }
    }
    
    var recentlyAdded: RecentlyAdded? {
        didSet {
            if let recentlyAdded = recentlyAdded {
                if let url = URL(string: recentlyAdded.RACover ?? "") {
                    artworkImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                }
                lblSongName.text = recentlyAdded.RATrack
                lblArtistName.text = recentlyAdded.RAArtist
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        artworkImage.layer.cornerRadius = 5
    }
    
}
