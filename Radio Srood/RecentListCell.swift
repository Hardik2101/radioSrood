
import UIKit
import MediaPlayer
import AVKit
import GoogleMobileAds

class AdViewCell: UITableViewCell {
    @IBOutlet weak var unifiedNativeAdView: GADUnifiedNativeAdView!
    @IBOutlet weak var lblAd: UILabel!
    @IBOutlet weak var bgView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        bgView.layer.cornerRadius = 5
        lblAd.layer.cornerRadius = 3
        // Initialization code
    }
}

class RecentListCell: UITableViewCell {

    @IBOutlet weak var vwContent: UIView!
    @IBOutlet weak var artCoverImage: UIImageView!
    @IBOutlet weak var trackTitle: UILabel!
    @IBOutlet weak var artistName: UILabel!

    @IBOutlet weak var imgBg: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        artCoverImage.image = nil
        
        if let bg = imgBg {
            bg.layer.cornerRadius = 5
        }

    }

    override func prepareForReuse() {
        super.prepareForReuse()
        artCoverImage.image = nil
        
    }

}

class UpNextCell: UITableViewCell {
    @IBOutlet weak var artCoverImage: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subTitle: UILabel!
    
    @IBOutlet weak var bgImage: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        if let bg = bgImage {
            bg.layer.cornerRadius = 5
        }
    }

}

class OptionCell: UITableViewCell {

    @IBOutlet weak var btnLyrics: UIButton!
    @IBOutlet weak var btnShare: UIButton!
    @IBOutlet weak var btnMoreInfo: UIButton!
    @IBOutlet weak var airPlayView: UIView!
    @IBOutlet weak var airPlayBloke: UIView!

    var airPlay = UIView()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpAirPlayButton()
        airPlayBloke.addSubview(airPlay)
        // Initialization code
    }

    func setUpAirPlayButton() {
        airPlay.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        let buttonView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        if #available(iOS 11.0, *) {
            let routePickerView = AVRoutePickerView(frame: buttonView.bounds)
            routePickerView.tintColor = UIColor.white
            routePickerView.activeTintColor = .white
            buttonView.addSubview(routePickerView)
            airPlay.addSubview(buttonView)
        } else {
            let airplayButton = MPVolumeView(frame: buttonView.bounds)
            airplayButton.showsVolumeSlider = false
            buttonView.addSubview(airplayButton)
            airPlay.addSubview(buttonView)
        }
    }

}

class MusicListCell: UITableViewCell {

    @IBOutlet weak var artCoverImage: UIImageView!
    @IBOutlet weak var trackTitle: UILabel!
    @IBOutlet weak var artistName: UILabel!

    @IBOutlet weak var imgBg: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        artCoverImage.image = nil
        if let bg = imgBg {
            bg.layer.cornerRadius = 5
        }
        // Initialization code
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        artCoverImage.image = nil
    }

}
