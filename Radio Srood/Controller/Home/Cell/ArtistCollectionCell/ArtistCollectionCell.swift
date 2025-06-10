
import UIKit

class ArtistCollectionCell: UICollectionViewCell {
  
    @IBOutlet private weak var lblType: UILabel!
    @IBOutlet private weak var artistBgImage: UIImageView!
    @IBOutlet private weak var transparentView: UIView!
    
    var featuredArtist: FeaturedArtist? {
        didSet {
            if let featuredArtist = featuredArtist {
                if let url = URL(string: featuredArtist.featuredCover) {
                    artistBgImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                }
                lblType.text = featuredArtist.featuredArtist
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        artistBgImage.layer.cornerRadius = 120/2
        transparentView.layer.cornerRadius = 120/2
    }
    
}
