
import UIKit

class MusicCell: UICollectionViewCell {
    
    @IBOutlet private weak var mainView: UIView!
    @IBOutlet private weak var artworkImage: UIImageView!
    @IBOutlet private weak var trackTitle: UILabel!
    @IBOutlet private weak var artistName: UILabel!
    
    var podcastObject: PodcastObject? {
        didSet {
            if let podcastObject = podcastObject {
//                artworkImage.image = podcastObject.image
                trackTitle.text = podcastObject.trackName
                artistName.text = podcastObject.artistName
                if let url = podcastObject.imageURL {
                    artworkImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        mainView.layer.cornerRadius = 5
        artworkImage.layer.cornerRadius = 3
    }
    
    func setArtCover(having url: URL) {
        artworkImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
        podcastObject?.imageURL = url
    }
    
}
