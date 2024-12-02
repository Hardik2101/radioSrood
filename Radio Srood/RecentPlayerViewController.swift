
import UIKit
//import SWRevealViewController
import Alamofire
import AlamofireImage
import GoogleMobileAds
import StoreKit
import MediaPlayer
import AVKit

class RecentPlayerViewController: UIViewController, GADBannerViewDelegate {

    @IBOutlet weak var radioTableView: UITableView!
    @IBOutlet weak var bgImageView: UIImageView!
    @IBOutlet weak var tableBgHeightConstraints: NSLayoutConstraint!
    @IBOutlet weak var artCoverImage: UIImageView!
    @IBOutlet weak var trackTitle: UILabel!
    @IBOutlet weak var artistName: UILabel!
    @IBOutlet weak var playPauseBtn: UIButton!
    @IBOutlet weak var btnBackward: UIButton!
    @IBOutlet weak var btnForward: UIButton!
    @IBOutlet weak var btnDownload: UIButton!
    @IBOutlet weak var btnRepeat: UIButton!
    @IBOutlet weak var lblStartTime: UILabel!
    @IBOutlet weak var lblEndTime: UILabel!
    @IBOutlet weak var playerSlider: UISlider!
    @IBOutlet weak var btnLike: UIButton!

    var recentListData: NSDictionary?
    var recentListArray: NSArray?
    var playRadioData: NSDictionary?
    var dataHelper: DataHelper!
    var nativeAd: GADUnifiedNativeAd?
    var adLoader: GADAdLoader!
    var isSetupRemoteTransport = false
    var radioUrl: String?
    var artImageURL: URL?
    var selectedIndex: Int?
    var isPlay: Bool = true
    var isSetMusic = true
   // var player: AVPlayer?
    var isLike = false
    var isRepeat = false
    var timeObserver: Any?
    private var isPurchaseSuccess: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        let yourBackImage = UIImage(named: "left-arrow")
        self.navigationController?.navigationBar.backIndicatorImage = yourBackImage
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = yourBackImage
        self.navigationController?.navigationBar.tintColor = .white
        self.navigationController?.navigationBar.backItem?.title = "RADIO SROOD"
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItem.Style.plain, target: nil, action: nil)
        radioTableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: 0.1))
        radioTableView.tableFooterView = UIView()
//        self.view!.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        handleRecentInView()
        self.btnDownload.addTarget(self, action: #selector(downloadBtnPressed), for: .touchUpInside)
        tableBgHeightConstraints.constant = 165
        loadNativeAd()
        isSetupRemoteTransport = true
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(RadioViewController.didBecomeActiveNotificationReceived),
                                               name:NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification"),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(RadioViewController.playerInterruption(notification:)),
                                               name:NSNotification.Name(rawValue: "AVAudioSessionInterruptionNotification"),
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleIAPPurchase), name: .PurchaseSuccess, object: nil)

        radioTableView.register(UINib(nibName: "BannerAdCell", bundle: nil), forCellReuseIdentifier: "BannerAdCell")

    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    deinit {
        UIApplication.shared.endReceivingRemoteControlEvents()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [:]
        NotificationCenter.default.removeObserver(self,
                                                  name:NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification"),
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name:NSNotification.Name(rawValue: "AVAudioSessionInterruptionNotification"),
                                                  object: nil)
        NotificationCenter.default.removeObserver(self)
        print("Remove screen")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        radioTableView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
    }
    
    @objc func didBecomeActiveNotificationReceived() {
        updateNowPlaying(isPause: true)
    }
    
    @objc func playerInterruption(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        if type == .began {
            player?.pause()
            updateNowPlaying(isPause: false)
        }
        else if type == .ended {
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
                    if UIApplication.shared.applicationState == .background {
                        print("App in Background")
                        player?.play()
                        self.setupNowPlaying()
                        self.updateNowPlaying(isPause: true)
                    } else {
                        player?.play()
                    }
                }
            }
        }
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

    func handleRecentInView() {
        self.artCoverImage.layer.cornerRadius = 3
        self.artCoverImage.layer.masksToBounds = true
        var miniPlayerInfo = BasicDetail()
        miniPlayerInfo.musicVC = self
        if let recentItem = recentListData {
            if let recentArtCover = recentItem.value(forKey: "recentArtCover") as? String, let url = URL(string: recentArtCover) {
                self.artCoverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                self.bgImageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "b1.png"))
                miniPlayerInfo.songImage = recentArtCover
            }
            if let recentTrack = recentItem.value(forKey: "recentTrack") as? String {
                self.trackTitle.text = recentTrack
                miniPlayerInfo.songNameTitle = self.trackTitle.text ?? ""
              
            }
            if let recentArtist = recentItem.value(forKey: "recentArtist") as? String {
                self.artistName.text = recentArtist
                miniPlayerInfo.artistSubtitle = recentArtist
            }
            if let mediaPathInfo = recentItem.value(forKey: "mediaPathInfo") as? String, let urlString = mediaPathInfo.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: songPath + urlString) {
                if isSetMusic {
                    isSetMusic = false
                    self.play(url: url, isPlay: self.isPlay)
                }
                if isSetupRemoteTransport {
                    isSetupRemoteTransport = false
                    self.setupRemoteTransportControls()
                }
            }
        }
        AppPlayer.miniPlayerInfo = miniPlayerInfo
        //config****
    }

    @objc func lyricsBtnClicked() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "LyricsViewController") as! LyricsViewController
        vc.recentLyricData = self.recentListData
        self.navigationController?.present(vc, animated: true, completion: nil)
    }

    @objc func moreInfoBtnClicked() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MoreInfoViewController") as! MoreInfoViewController
        vc.currentLyricData = self.recentListData
        self.navigationController?.present(vc, animated: true, completion: nil)
    }

    @objc func backwardBtnPressed() {
        if let recentListArray = recentListArray, let selectedIndex = selectedIndex {
            if selectedIndex > 0 {
                recentListData = recentListArray[selectedIndex-1] as? NSDictionary
                self.selectedIndex = selectedIndex - 1
                self.isPlay = true
                self.isSetMusic = true
                handleRecentInView()
            } else {
                player?.pause()
                self.playPauseBtn.setImage(UIImage(named: "ic_play"), for:.normal)
            }
        }
    }

    @objc func forwardBtnPressed() {
        if let recentListArray = recentListArray, let selectedIndex = selectedIndex {
            if selectedIndex < recentListArray.count-1 {
                recentListData = recentListArray[selectedIndex+1] as? NSDictionary
                self.selectedIndex = selectedIndex + 1
                self.isPlay = true
                self.isSetMusic = true
                handleRecentInView()
            } else {
                player?.pause()
                self.playPauseBtn.setImage(UIImage(named: "ic_play"), for:.normal)
            }
        }
    }
    
    @objc private func handleIAPPurchase() {
        isPurchaseSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: {
            self.isPurchaseSuccess = false
        })
    }


    @objc func downloadBtnPressed() {
        
        if IAPHandler.shared.isGetPurchase() || isPurchaseSuccess {
//            isPurchaseSuccess = false
            
            var track: URL?
            var name: String?
            if let recentItem = recentListData {
                if let mediaPathInfo = recentItem.value(forKey: "mediaPathInfo") as? String, let urlString = mediaPathInfo.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: songPath + urlString) {
                    track = url
                    name = "\(url.lastPathComponent)"
                    UserDefaults.standard.set(recentItem.value(forKey: "recentArtCover") as? String ?? "", forKey: "\(url.deletingPathExtension().lastPathComponent)")
                }
            }
            let destination: DownloadRequest.DownloadFileDestination = { _, _ in
                var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                // the name of the file here I kept is yourFileName with appended extension
                documentsURL.appendPathComponent(name!)
                return (documentsURL, [.removePreviousFile])
            }
            Alamofire.download(track!, to: destination)
                .downloadProgress { progress in
                    DispatchQueue.main.async {
                        self.navigationController?.setProgress(Float(progress.fractionCompleted), animated: true)
                    }
                    print("Download Progress: \(progress.fractionCompleted)")
                    if (progress.fractionCompleted == 1){
                        self.navigationController?.finishProgress()
                    }
                }
                .response { response in
                    if let destinationURL = response.destinationURL {
                        print(destinationURL)
                        //                    self?.shareBtnClicked(url: destinationURL)
                    }
                }
        } else {
            
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "IAPVC") as! IAPVC
            vc.isshowbackButton = true
            let navVC = UINavigationController(rootViewController: vc)
            navVC.navigationBar.isHidden = true
            navVC.modalPresentationStyle = .fullScreen
            self.present(navVC, animated: true)

        }
        
        
        
    }

    func shareBtnClicked(url: URL) {
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: [])
        vc.modalPresentationStyle = .popover
        if let wPPC = vc.popoverPresentationController {
            wPPC.sourceView = self.view
        }
        self.present(vc, animated: true, completion: nil)
    }
}

extension RecentPlayerViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecentPlayerOptionCell", for: indexPath) as! RecentPlayerOptionCell
            cell.selectionStyle = .none
            cell.btnLyrics.addTarget(self, action: #selector(lyricsBtnClicked), for: .touchUpInside)
            return cell
            
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BannerAdCell", for: indexPath) as! BannerAdCell
//            cell.heightOfVw.constant = 65
            for subview in cell.vwMain.subviews {
                subview.removeFromSuperview()
            }


            if IAPHandler.shared.isGetPurchase() || isPurchaseSuccess {
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
//                bannerView.frame = CGRect(x: 0, y: 0, width: vwAds.frame.width, height: vwAds.frame.height)
            // Remove any existing subviews from vwAds

            // Add the banner view to the cell's content view
            cell.vwMain.addSubview(bannerView)

            // Set the banner view frame
            bannerView.frame = cell.vwMain.bounds

            return cell

        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BannerAdCell", for: indexPath) as! BannerAdCell
            for subview in cell.vwMain.subviews {
                subview.removeFromSuperview()
            }

            if IAPHandler.shared.isGetPurchase() || isPurchaseSuccess {
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
            bannerView.adUnitID = GOOGLE_ADMOB_ForMiniPlayer
            bannerView.rootViewController = self
            bannerView.delegate = self
            bannerView.load(GADRequest())
            // Set the banner view frame
//                bannerView.frame = CGRect(x: 0, y: 0, width: vwAds.frame.width, height: vwAds.frame.height)
            // Remove any existing subviews from vwAds

            // Add the banner view to the cell's content view
            cell.vwMain.addSubview(bannerView)

            // Set the banner view frame
            bannerView.frame = cell.vwMain.bounds

            return cell
        }
    }
    
}

extension RecentPlayerViewController: GADAdLoaderDelegate, GADUnifiedNativeAdLoaderDelegate {

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
        self.tableBgHeightConstraints.constant = 165
        radioTableView.reloadData()
    }

    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: GADRequestError) {
        print("\(adLoader) failed with error: \(error.localizedDescription)")
    }

}

extension RecentPlayerViewController {

    func play(url: URL, isPlay: Bool = false) {
        let playerItem = AVPlayerItem(url: url)
        player = PlayObserver(playerItem: playerItem)
        self.playerSlider.minimumValue = 0.0
        self.playerSlider.maximumValue = Float(player?.currentItem?.asset.duration.seconds ?? 0.0)
        populateLabelWithTime(self.lblStartTime, time: 0.0)
        populateLabelWithTime(self.lblEndTime, time: player?.currentItem?.asset.duration.seconds ?? 0.0)
        player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        self.playerSlider.value = 0.0
        playerSlider.setValue(0, animated: true)
        if !isPlay {
            self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
            self.updateNowPlaying(isPause: true)
            player?.pause()
        } else {
            self.playPauseBtn.setImage(UIImage(named: "ic_pause"), for: .normal)
            self.updateNowPlaying(isPause: false)
            player?.play()
        }
        self.btnLike.setImage(UIImage(named: "ic_like"), for: .normal)
        self.isLike = false
        self.setupNowPlaying()
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying(sender:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        //time observer to update slider.
        timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 1), // used to monitor the current play time and update slider
                                       queue: DispatchQueue.global(), using: { [weak self] (progressTime) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.playerSlider.value = Float(progressTime.seconds)
                self.populateLabelWithTime(self.lblStartTime, time: progressTime.seconds)
            }
        })
    }

    @objc func playerDidFinishPlaying(sender: Notification) {
        playerSlider.setValue(0, animated: true)
        populateLabelWithTime(self.lblStartTime, time: 0.0)
        player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        if isRepeat {
            player?.play()
        } else {
            NotificationCenter.default.removeObserver(self,
                                                      name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                      object: nil)
            if let recentListArray = recentListArray, let selectedIndex = selectedIndex {
                if selectedIndex < recentListArray.count-1 {
                    if let timeObserver = timeObserver {
                        player?.removeTimeObserver(timeObserver)
                    }
                }
            }
            self.forwardBtnPressed()
        }
    }

    func populateLabelWithTime(_ label : UILabel, time: Double) {
        let minutes = Int(time / 60)
        let seconds = Int(time) - minutes * 60
        label.text = String(format: "%02d", minutes) + ":" + String(format: "%02d", seconds)
    }

    @IBAction func pausePressed() {
        if (player?.isPlaying ?? true) {
            DispatchQueue.main.async {
                self.playPauseBtn.setImage(UIImage(named: "ic_play"), for:.normal)
            }
            player?.pause()
            updateNowPlaying(isPause: true)
        } else {
            DispatchQueue.main.async {
                self.playPauseBtn.setImage(UIImage(named: "ic_pause"), for: .normal)
            }
            player?.play()
            updateNowPlaying(isPause: false)
        }
    }

    @IBAction func likeBtnPressed(_ sender: Any) {
        if isLike {
            btnLike.setImage(UIImage(named: "ic_like"), for: .normal)
            isLike = false
        } else {
            btnLike.setImage(UIImage(named: "ic_like_filled"), for: .normal)
            isLike = true
        }
    }

    @IBAction func repeatBtnPressed(_ sender: Any) {
        let image = UIImage(named: "ic_repeat")?.withRenderingMode(.alwaysTemplate)
        self.btnRepeat.setImage(image, for: .normal)
        if isRepeat {
            isRepeat = false
            self.btnRepeat.tintColor = .white
        } else {
            isRepeat = true
            self.btnRepeat.tintColor = .red
        }
    }

    @IBAction func backwardBtnEvent(_ sender: Any) {
        self.pausePlayer()
        self.backwardBtnPressed()
    }

    @IBAction func forwardBtnEvent(_ sender: Any) {
        self.pausePlayer()
        self.forwardBtnPressed()
    }
    
    @IBAction func progressSliderValueChanged() {
        let seconds: Int64 = Int64(playerSlider.value)
        let targetTime: CMTime = CMTimeMake(value: seconds, timescale: 1)
        player?.seek(to: targetTime)
    }

    func updateNowPlaying(isPause: Bool) {
        // Define Now Playing Info
        if var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo {
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPause ? 0 : 1
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }

    func setupNowPlaying() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            var nowPlayingInfo = [String: Any]()
            nowPlayingInfo[MPMediaItemPropertyArtist] = self.artistName.text
            nowPlayingInfo[MPMediaItemPropertyTitle] = self.trackTitle.text
            nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = false
            
            if let image = self.artCoverImage.image {
                if #available(iOS 10.0, *) {
                    // Asynchronous loading of image
                    DispatchQueue.global(qos: .background).async {
                        let mediaArtwork = MPMediaItemArtwork(boundsSize: image.size) { (size: CGSize) -> UIImage in
                            return image
                        }
                        nowPlayingInfo[MPMediaItemPropertyArtwork] = mediaArtwork

                        DispatchQueue.main.async {
                            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                        }
                    }
                } else {
                    // Fallback on earlier versions
                }
            } else {
                // Handle case where image is nil
                print("Error: artCoverImage.image is nil")
            }
        }
    }

    func setupRemoteTransportControls() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            if let player = player {
                if !player.isPlaying {
                    player.play()
                    self.playPauseBtn.setImage(UIImage(named: "ic_pause"), for:.normal)
                    return .success
                }
            }
            return .commandFailed
        }

        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            if let player = player {
                if player.isPlaying {
                    player.pause()
                    self.playPauseBtn.setImage(UIImage(named: "ic_play"), for:.normal)
                    return .success
                }
            }
            return .commandFailed
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            if player != nil {
                self.pausePlayer()
                self.forwardBtnPressed()
                return .success
            }
            return .commandFailed
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            if player != nil {
                self.pausePlayer()
                self.backwardBtnPressed()
                return .success
            }
            return .commandFailed
        }

    }

    func pausePlayer() {
        player?.pause()
        self.playerSlider.setValue(0, animated: true)
        self.populateLabelWithTime(self.lblStartTime, time: 0.0)
        player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
    }

}
