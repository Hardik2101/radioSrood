
/// Add Tabbar View 2

import UIKit
import Alamofire
import AlamofireImage
import GoogleMobileAds
import StoreKit
import MediaPlayer
import AVKit
//import SWRevealViewController

protocol StopPlayerDelegate: AnyObject {
    func stopPlayerInDidDisappear()
}

class RadioWithRecentViewController: UI_VC, GADBannerViewDelegate {

    @IBOutlet weak var radioTableView: UITableView!
    @IBOutlet weak var bgImageView: UIImageView!

    var radioData: NSDictionary?
    var playRadioData: NSDictionary?
    var dataHelper: DataHelper!
    var nativeAd: GADUnifiedNativeAd?
    var adLoader: GADAdLoader!
    var isSetupRemoteTransport = false
    var radioUrl: String?
    var artImageURL: URL?
    var trackTitle: String?
    var artistName: String?
    var interstitial: GADInterstitial!
    weak var stopPlayerDelegate: StopPlayerDelegate?
    var wasPlayingBeforeAds = false
    var currentLyricData: NSDictionary?
    var selectedIndex: Int?
    var isPrevent = false

    private var isPurchaseSuccess: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 14.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
        } else if #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()
        } else {
            // Fallback for earlier iOS versions (if needed)
            // Handle the case where SKStoreReviewController is not available
            // or other fallback behavior.
        }
        
        let yourBackImage = UIImage(named: "left-arrow")
        self.navigationController?.navigationBar.backIndicatorImage = yourBackImage
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = yourBackImage
        self.navigationController?.navigationBar.tintColor = .white
        self.navigationController?.navigationBar.backItem?.title = ""
        self.navigationController?.navigationBar.topItem?.title = ""
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItem.Style.plain, target: nil, action: nil)
        radioTableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: 0.1))
        radioTableView.tableFooterView = UIView()

//        menuBtn.action = #selector(SWRevealViewController.revealToggle(_:))
        radioTableView.register(UINib(nibName: "BannerAdCell", bundle: nil), forCellReuseIdentifier: "BannerAdCell")
        
//        NotificationCenter.default.addObserver(
//            self, selector: #selector(RadioWithRecentViewController.loadRadioData),
//            name: .reloadRadio, object: nil
//        )
//        Timer.scheduledTimer(timeInterval: 0.8, target: self, selector: #selector(execute), userInfo: nil, repeats: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleIAPPurchase), name: .PurchaseSuccess, object: nil)

        radioTableView.register(UINib(nibName: "BannerAdCell", bundle: nil), forCellReuseIdentifier: "BannerAdCell")

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadNativeAd()
        loadInterstitial()
        loadRadioData()
        loadCurrentLyricData()

        radioTableView.reloadData()
        
        if wasPlayingBeforeAds {
            NotificationCenter.default.post(name: .reloadRadio, object: nil, userInfo: nil)
            wasPlayingBeforeAds = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        if isPrevent {
            isPrevent = false
            self.radioTableView.reloadData()
        }
        if let interstitial = interstitial {
            if !interstitial.isReady {
                loadInterstitial()
            }
        }
    }
//    @objc func execute() {
//        loadRecentListData()
//    }
    
    deinit {
        print("Remove screen")
    }
    
    
    @objc func loadRadioData() {
        dataHelper = DataHelper()
        if let data = UserDefaults.standard.value(forKey: "NowPlayData") as? NSDictionary {
            playRadioData = data
            isSetupRemoteTransport = true
            radioTableView.reloadData()
        } else {
            dataHelper.getRadioData { [weak self] (data) in
                guard let self = self else { return }
                if let _ = data.value(forKey: "radio_url") as? String {
                    self.playRadioData = data
                    self.isSetupRemoteTransport = true
                    self.loadRecentListData()
                }
            }
        }
    }

    func loadCurrentLyricData() {
        dataHelper = DataHelper()
        dataHelper.getCurrentLyricData { [weak self] resp in
            guard let self = self else { return }
            self.currentLyricData = resp
            self.radioTableView.reloadData()
        }
    }

    func loadRecentListData() {
        dataHelper = DataHelper()
        dataHelper.getRecentListData(completion: { [weak self] resp in
            guard let self = self else { return }
            self.radioData = resp
            self.radioTableView.reloadData()
        })
    }
    
    private func setHeaderData(headerTitle: String) -> UIView {
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: 30))
        let lblTitle = UILabel(frame: CGRect(x: 15, y: 5, width: screenSize.width - 30, height: 20))
        lblTitle.text = headerTitle
        lblTitle.textColor = .white.withAlphaComponent(1.1)
        lblTitle.font = UIFont(name: "Avenir Next Ultra Light", size: 19)
        containerView.addSubview(lblTitle)
        return containerView
    }

    @objc func lyricsBtnClicked() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "LyricsViewController") as! LyricsViewController
        vc.currentLyricData = self.currentLyricData
        self.navigationController?.present(vc, animated: true, completion: nil)
    }

    @objc func shareBtnClicked() {
        var trackName = "Radio Srood"
        var artistName = "Radio Srood"
        if let radioData = radioData {
            if let currentSong = radioData.value(forKey: "currentTrack") as? NSDictionary {
                if let currentTrack = currentSong.value(forKey: "currentTrack") as? String {
                    trackName = currentTrack
                }
                if let currentArtist = currentSong.value(forKey: "currentArtist") as? String {
                    artistName = currentArtist
                }
            }
        }
        let shareText = String (format: "%@ - %@ on Radio Srood app! Download the app @ https://radiosrood.com/app", artistName, trackName)
        var imageArtShare: UIImage!

        if (bgImageView.image == nil) {
            imageArtShare = UIImage(named:"no_image.jpg")
        } else {
            imageArtShare = bgImageView.image
        }
        let vc = UIActivityViewController(activityItems: [shareText, imageArtShare], applicationActivities: [])
        vc.modalPresentationStyle = .popover
        if let wPPC = vc.popoverPresentationController {
            wPPC.sourceView = self.view
        }
        self.present(vc, animated: true, completion: nil)
    }

    @objc func moreInfoBtnClicked() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MoreInfoViewController") as! MoreInfoViewController
        vc.currentLyricData = self.currentLyricData
        self.navigationController?.present(vc, animated: true, completion: nil)
    }
    @objc private func handleIAPPurchase() {
        isPurchaseSuccess = true
        radioTableView.reloadData()
    }

    func recentPlayerViewControllerPush() {
        if let selectedIndex = selectedIndex {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "RecentPlayerViewController") as! RecentPlayerViewController
            if let currentSong = radioData?.value(forKey: "currentTrack") as? NSDictionary, let recentHistory = currentSong.value(forKey: "recentHistory") as? NSArray, let recentItem = recentHistory[selectedIndex] as? NSDictionary {
                self.isPrevent = true
                vc.selectedIndex = selectedIndex
                vc.recentListData = recentItem
                vc.recentListArray = recentHistory
            }
            self.selectedIndex = nil
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

}

extension RadioWithRecentViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        if radioData != nil {
            return 5
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if radioData != nil {
            switch section {
            case 4:
                if let currentSong = radioData?.value(forKey: "currentTrack") as? NSDictionary, let recentHistory = currentSong.value(forKey: "recentHistory") as? NSArray {
                    return recentHistory.count
                } else {
                    return 0
                }
            default:
                return 1
            }
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if radioData == nil {
            return UITableViewCell()
        }
        
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "RadioCell", for: indexPath) as! RadioCell
            stopPlayerDelegate = cell
            cell.selectionStyle = .none
            cell.presentView = self
            cell.artCoverImage.layer.cornerRadius = 5
            cell.artCoverImage.layer.masksToBounds = true
            if let radioUrl = radioUrl {
                cell.radioUrl = radioUrl
//                cell.artCoverImage.af_setImage(withURL: artImageURL, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
//                cell.trackTitle.text = trackTitle
//                cell.artistName.text = artistName
                cell.makeScreen(true)
            } else {
                if let currentSong = radioData?.value(forKey: "currentTrack") as? NSDictionary {
                    if let url = cell.setUI(currentSong: currentSong) {
                        self.bgImageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "b1.png"))
                    }
                }
                if isSetupRemoteTransport {
                    isSetupRemoteTransport = false
                    cell.setupRemoteTransportControls()
                    if let playRadioData = playRadioData {
                        let value1 = playRadioData.value(forKey: "radio_url") as? String
                        let value2 = playRadioData.value(forKey: "tv_stream") as? String
                        cell.radioUrl = value1 ?? value2 ?? ""
                        if !radio.isPlaying {
                            cell.makeScreen()
                        }
                    }
                }
            }
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BannerAdCell", for: indexPath) as! BannerAdCell
            for subview in cell.vwMain.subviews {
                subview.removeFromSuperview()
            }
            
            if IAPHandler.shared.isGetPurchase() || isPurchaseSuccess  {
                cell.vwMain.isHidden = true
                cell.heightOfVw.constant = 0
            } else {
                cell.vwMain.isHidden = false
                cell.heightOfVw.constant = 65
            }
            
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            
            // Load banner ad into the cell's view hierarchy
            let bannerView = GADBannerView(adSize: kGADAdSizeBanner)
            bannerView.adUnitID = GOOGLE_ADMOB_ForMusicPlayer
            bannerView.rootViewController = self
            bannerView.delegate = self
            bannerView.load(GADRequest())
            // Set the banner view frame
            bannerView.frame = CGRect(x: 0, y: 0, width: cell.vwMain.frame.width, height: cell.vwMain.frame.height)
            // Remove any existing subviews from vwAds
            
            // Add the banner view to the cell's content view
            cell.vwMain.addSubview(bannerView)
            
            // Set the banner view frame
            bannerView.frame = cell.vwMain.bounds
            
            return cell
            
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OptionCell", for: indexPath) as! OptionCell
            cell.selectionStyle = .none
            cell.btnLyrics.addTarget(self, action: #selector(lyricsBtnClicked), for: .touchUpInside)
            cell.btnShare.addTarget(self, action: #selector(shareBtnClicked), for: .touchUpInside)
            cell.btnMoreInfo.addTarget(self, action: #selector(moreInfoBtnClicked), for: .touchUpInside)
            return cell
            
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "UpNextCell", for: indexPath) as! UpNextCell
            cell.selectionStyle = .none
            if let currentLyricData = self.currentLyricData {
                if let currentTrackInfo = currentLyricData.value(forKey: "currentTrackInfo") as? NSDictionary {
                    if let comingNextInfo = currentTrackInfo.value(forKey: "comingNextInfo") as? String {
                        cell.title.text = comingNextInfo
                    }
                }
            }
            return cell
            
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecentListCell", for: indexPath) as! RecentListCell
            cell.selectionStyle = .none
            cell.artCoverImage.layer.cornerRadius = 3
            cell.artCoverImage.layer.masksToBounds = true
            if let currentSong = radioData?.value(forKey: "currentTrack") as? NSDictionary, let recentHistory = currentSong.value(forKey: "recentHistory") as? NSArray, let recentItem = recentHistory[indexPath.row] as? NSDictionary {
                if let recentArtCover = recentItem.value(forKey: "recentArtCover") as? String, let url = URL(string: recentArtCover) {
                    cell.artCoverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                }
                if let recentTrack = recentItem.value(forKey: "recentTrack") as? String {
                    cell.trackTitle.text = recentTrack
                }
                if let recentArtist = recentItem.value(forKey: "recentArtist") as? String {
                    cell.artistName.text = recentArtist
                }
            }
            return cell
            
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BannerAdCell", for: indexPath) as! BannerAdCell
            for subview in cell.vwMain.subviews {
                subview.removeFromSuperview()
            }
            
            if IAPHandler.shared.isGetPurchase() || isPurchaseSuccess  {
                cell.vwMain.isHidden = true
                cell.heightOfVw.constant = 0
            } else {
                cell.vwMain.isHidden = false
                cell.heightOfVw.constant = 65
            }
            
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            
            // Load banner ad into the cell's view hierarchy
            let bannerView = GADBannerView(adSize: kGADAdSizeBanner)
            bannerView.adUnitID = GOOGLE_ADMOB_ForMusicPlayer
            bannerView.rootViewController = self
            bannerView.delegate = self
            bannerView.load(GADRequest())
            // Set the banner view frame
            bannerView.frame = CGRect(x: 0, y: 0, width: cell.vwMain.frame.width, height: cell.vwMain.frame.height)
            // Remove any existing subviews from vwAds
            
            // Add the banner view to the cell's content view
            cell.vwMain.addSubview(bannerView)
            
            // Set the banner view frame
            bannerView.frame = cell.vwMain.bounds
            return cell
//                let cell = tableView.dequeueReusableCell(withIdentifier: "AdViewCell", for: indexPath) as! AdViewCell
//                cell.selectionStyle = .none
//                (cell.unifiedNativeAdView.callToActionView as! UIButton).layer.cornerRadius = 5
//                (cell.unifiedNativeAdView.callToActionView as! UIButton).layer.masksToBounds = true
//                if let nativeAd = nativeAd {
//                    cell.unifiedNativeAdView.nativeAd = nativeAd
//                    (cell.unifiedNativeAdView.headlineView as! UILabel).text = nativeAd.headline
//                    (cell.unifiedNativeAdView.bodyView as! UILabel).text = nativeAd.body
//                    (cell.unifiedNativeAdView.imageView as! UIImageView).image = nativeAd.images?.first?.image
//                    (cell.unifiedNativeAdView.callToActionView as! UIButton).isUserInteractionEnabled = false
//                    cell.unifiedNativeAdView.mediaView?.contentMode = .scaleAspectFill
//                    (cell.unifiedNativeAdView.callToActionView as! UIButton).setTitle(nativeAd.callToAction?.uppercased(), for: .normal)
//                }
//                return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if radioData != nil {
            switch indexPath.section {
            case 2:
//                radioUrl = "http://stream.radiosrood.com"
//                if let currentSong = radioData?.value(forKey: "currentTrack") as? NSDictionary, let recentHistory = currentSong.value(forKey: "recentHistory") as? NSArray, let recentItem = recentHistory[indexPath.row] as? NSDictionary {
//                    if let recentArtCover = recentItem.value(forKey: "recentArtCover") as? String, let url = URL(string: recentArtCover) {
//                        artImageURL = url
//                    }
//                    if let recentTrack = recentItem.value(forKey: "recentTrack") as? String {
//                        trackTitle = recentTrack
//                    }
//                    if let recentArtist = recentItem.value(forKey: "recentArtist") as? String {
//                        artistName = recentArtist
//                    }
//                }
//                radioTableView.reloadData()
                break
            case 4:
                selectedIndex = indexPath.row
                if interstitial != nil {
                    interstitial.present(fromRootViewController: self)
                } else {
                    recentPlayerViewControllerPush()
                }
            default:
                break
            }
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if radioData != nil {
            switch section {
            case 3:
                return setHeaderData(headerTitle: "Up Next")
            case 4:
                return setHeaderData(headerTitle: "Recently Played")
            default:
                return nil
            }
        } else {
            return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if radioData != nil {
            switch section {
            case 3:
                return 30
            case 4:
                return 30
            default:
                return 0
            }
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
      return CGFloat.leastNonzeroMagnitude
    }

}


extension RadioWithRecentViewController: GADAdLoaderDelegate, GADUnifiedNativeAdLoaderDelegate {
    func loadNativeAd() {
        guard !IAPHandler.shared.isGetPurchase() else {
            // Skip loading the ad if the purchase is made
            return
        }

        adLoader = GADAdLoader(adUnitID: GOOGLE_ADMOB_NATIVE,
            rootViewController: self,
            adTypes: [.unifiedNative],
            options: nil)
        adLoader.delegate = self
        adLoader.load(GADRequest())
    }

    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADUnifiedNativeAd) {
        self.nativeAd = nativeAd
        radioTableView.reloadData()
    }

    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: GADRequestError) {
        print("\(adLoader) failed with error: \(error.localizedDescription)")
    }
}

extension RadioWithRecentViewController: GADInterstitialDelegate {

    private func loadInterstitial() {
        guard !IAPHandler.shared.isGetPurchase() else {
            return
        }

        interstitial = GADInterstitial(adUnitID: GOOGLE_ADMOB_INTER)
        interstitial!.delegate = self
        interstitial!.load(GADRequest())
    }

    func interstitialDidFailToReceiveAdWithError (
        interstitial: GADInterstitial,
        error: GADRequestError) {
        print("interstitialDidFailToReceiveAdWithError: %@" + error.localizedDescription)
    }

    func interstitialDidDismissScreen (_ interstitial: GADInterstitial) {
        print("interstitialDidDismissScreen")
        if selectedIndex != nil {
            recentPlayerViewControllerPush()
        }
    }

    public func update() {
        guard !IAPHandler.shared.isGetPurchase() else {
            return
        }

        if SHOW_BANNER_ADMOB {banners()}
    }

    func banners(){
        guard !IAPHandler.shared.isGetPurchase() else {
            return
        }

        if (interstitial!.isReady) {
            wasPlayingBeforeAds = radio.isPlaying
            stopPlayerDelegate?.stopPlayerInDidDisappear()
            interstitial!.present(fromRootViewController: self)
        } else {
            loadInterstitial()
        }
    }
}
