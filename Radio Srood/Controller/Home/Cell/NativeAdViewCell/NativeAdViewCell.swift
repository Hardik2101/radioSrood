
import UIKit
import GoogleMobileAds

class NativeAdViewCell: UITableViewCell {
    
    @IBOutlet weak var unifiedNativeAdView: GADUnifiedNativeAdView!
    @IBOutlet  weak var lblAd: UILabel!
    @IBOutlet  weak var bgView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        bgView.layer.cornerRadius = 5
        lblAd.layer.cornerRadius = 3
    }
    
}
