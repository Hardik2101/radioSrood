
import UIKit

class MusicCell: UICollectionViewCell {
    
    @IBOutlet private weak var mainView: UIView!
    @IBOutlet private weak var artworkImage: UIImageView!
    @IBOutlet private weak var trackTitle: UILabel!
    @IBOutlet private weak var artistName: UILabel!

    private static let titleFontSize: CGFloat = 24
    private static let subtitleFontSize: CGFloat = 20
    private static let compactTitleFontSize: CGFloat = 16
    private static let compactSubtitleFontSize: CGFloat = 13

    var usesCompactTypography = false {
        didSet { applyTypography() }
    }
    
    var podcastObject: PodcastObject? {
        didSet {
            if let podcastObject = podcastObject {
//                artworkImage.image = podcastObject.image
                trackTitle.text = podcastObject.trackName
                artistName.text = podcastObject.artistName
                if let url = podcastObject.thumbnailArtCoverURL {
                    artworkImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        applyTypography()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        usesCompactTypography = false
        trackTitle.text = nil
        artistName.text = nil
        artworkImage.image = nil
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

    private func applyTypography() {
        let titleSize = usesCompactTypography ? Self.compactTitleFontSize : Self.titleFontSize
        let subtitleSize = usesCompactTypography ? Self.compactSubtitleFontSize : Self.subtitleFontSize
        trackTitle.font = UIFont(name: "KohinoorTelugu-Regular", size: titleSize)
            ?? .systemFont(ofSize: titleSize, weight: .regular)
        artistName.font = UIFont(name: "KohinoorTelugu-Regular", size: subtitleSize)
            ?? .systemFont(ofSize: subtitleSize, weight: .regular)
    }
    
}
