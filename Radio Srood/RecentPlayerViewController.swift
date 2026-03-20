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
    
    @IBOutlet var vwProgress: UIView!


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
    var isDownload = false
    var isRepeat = false
    var timeObserver: Any?
    // KVO observer for player item status (HLS failure detection)
    private var playerItemStatusObserver: NSKeyValueObservation?
    private var hasTriedFallbackForItem: Bool = false
    private var isPurchaseSuccess: Bool = false
    var circularProgressView: CircularProgressView!
    
    var isSyncedLyrics = false


    override func viewDidLoad() {
        super.viewDidLoad()

        // ✅ FIX 1: Configure & activate AVAudioSession for background playback
        //    Without this, remote commands and Now Playing never work in BG.
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }

        let yourBackImage = UIImage(named: "left-arrow")
        self.navigationController?.navigationBar.backIndicatorImage = yourBackImage
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = yourBackImage
        self.navigationController?.navigationBar.tintColor = .white
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        radioTableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: 0.1))
        radioTableView.tableFooterView = UIView()

        handleRecentInView()
        self.btnDownload.addTarget(self, action: #selector(downloadBtnPressed), for: .touchUpInside)
        tableBgHeightConstraints.constant = 190
        loadNativeAd()

        isSetupRemoteTransport = true

        NotificationCenter.default.addObserver(self,
            selector: #selector(RadioViewController.didBecomeActiveNotificationReceived),
            name: NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification"),
            object: nil)
        NotificationCenter.default.addObserver(self,
            selector: #selector(RadioViewController.playerInterruption(notification:)),
            name: NSNotification.Name(rawValue: "AVAudioSessionInterruptionNotification"),
            object: nil)
        NotificationCenter.default.addObserver(self,
            selector: #selector(handleIAPPurchase),
            name: .PurchaseSuccess,
            object: nil)

        radioTableView.register(UINib(nibName: "BannerAdCell", bundle: nil), forCellReuseIdentifier: "BannerAdCell")
        setupCircularProgressView()
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.4
        radioTableView.addGestureRecognizer(longPress)
        // ✅ FIX 2: Start receiving remote control events (required for lock-screen controls)
        UIApplication.shared.beginReceivingRemoteControlEvents()
        self.becomeFirstResponder()
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
        super.viewWillAppear(animated)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
    }
    
    private func setupCircularProgressView() {
        circularProgressView = CircularProgressView(frame: vwProgress.bounds)
        circularProgressView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        circularProgressView.isHidden = true
        vwProgress.addSubview(circularProgressView)
    }
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let point = gesture.location(in: radioTableView)
        guard let indexPath = radioTableView.indexPathForRow(at: point) else { return }
        // Only row 0 is the player — row 1 is options cell, rest are ads
        guard indexPath.row == 0, let recentItem = recentListData else { return }

        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()

        guard let songModel = SongModel(recentItem: recentItem) else { return }
        let track = songModel.convertToPodcastModel().convertToTrackModel()

        guard let optionsVC = storyboard?.instantiateViewController(withIdentifier: "OptionsViewController") as? OptionsViewController else { return }
        optionsVC.track = track
        optionsVC.delegate = self
        optionsVC.modalPresentationStyle = .overFullScreen
        present(optionsVC, animated: true)
    }

    @objc func didBecomeActiveNotificationReceived() {
        updateNowPlaying(isPause: true)
    }
    
    @objc func playerInterruption(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        if type == .began {
            player?.pause()
            updateNowPlaying(isPause: false)
        } else if type == .ended {
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                // ✅ FIX: Only resume if this VC's player is the one that was playing
                guard let p = player, !p.isPlaying else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    guard let self = self else { return }
                    p.play()
                    self.setupNowPlaying()
                    self.updateNowPlaying(isPause: true)
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
            if let recentArtCover = recentItem.value(forKey: "recentArtCover") as? String,
               let url = URL(string: recentArtCover) {

                // ✅ Use completion handler so setupNowPlaying runs AFTER image loads
                self.artCoverImage.af_setImage(
                    withURL: url,
                    placeholderImage: UIImage(named: "Lav_Radio_Logo.png"),
                    completion: { [weak self] _ in
                        // setupNowPlaying will fetch art from URL directly,
                        // but this ensures artCoverImage.image is also fresh
                        // for any code that still reads it.
                        self?.setupNowPlaying()
                    }
                )
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
            // Build HLS (primary) and MP3 (fallback) URLs and prefer HLS
            let urls = playbackURLs(from: recentItem)
            if isSetMusic {
                isSetMusic = false
                if let primary = urls.primary {
                    self.play(url: primary, isPlay: self.isPlay, fallbackURL: urls.fallback)
                } else if let fallback = urls.fallback {
                    self.play(url: fallback, isPlay: self.isPlay, fallbackURL: nil)
                } else {
                    print("Error: Invalid media URL in recentItem: \(recentItem)")
                }
            }
            if isSetupRemoteTransport {
                isSetupRemoteTransport = false
                self.setupRemoteTransportControls()
            }
            self.isAlreadyLiked()
            self.isAlreadyDownloaded()

        }
        AppPlayer.miniPlayerInfo = miniPlayerInfo
        //config****
    }

    @objc func lyricsBtnClicked() {
        guard let recentItem = recentListData else {
            print("No recent track data available")
            return
        }
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "LyricPlayViewController") as! LyricPlayViewController
        
        // Convert recentListData to SongModel
        guard let songModel = SongModel(recentItem: recentItem) else {
            print("Failed to create SongModel from recentListData: \(recentItem)")
            return
        }
        vc.currentSong = songModel
        
        // Set image URL
        if let artCover = recentItem.value(forKey: "recentArtCover") as? String, let url = URL(string: artCover) {
            vc.imageURl = url // Use updatedArtcoverURL if needed, e.g., updatedArtcoverURL(from: artCover) ?? url
        } else {
            vc.imageURl = URL(string: "")
        }
        
        DataHelper.getLyricsData(
            artist: songModel.artist,
            track: songModel.track
        ) { lyricItem in

            var lyricsToSend = ""

            if let lyricItem = lyricItem {

                print("✅ Artist: \(lyricItem.artistName)")
                print("✅ Track: \(lyricItem.trackName)")

                if !lyricItem.syncedLyrics.isEmpty {
                    // ✅ Prefer synced lyrics
                    lyricsToSend = lyricItem.syncedLyrics
                    self.isSyncedLyrics = true
                    print("✅ Using synced lyrics")

                } else if !lyricItem.plainLyrics.isEmpty {
                    // 🟡 Fallback to plain lyrics
                    lyricsToSend = lyricItem.plainLyrics
                    self.isSyncedLyrics = false
                    print("🟡 Using plain lyrics")

                } else {
                    print("⚠️ Lyrics exist but empty")
                }

            } else {
                print("⚠️ No lyrics found.")
            }

            DispatchQueue.main.async {
                vc.lyricnew = lyricsToSend
                vc.isSyncedLyrics = self.isSyncedLyrics
                self.navigationController?.present(vc, animated: true, completion: nil)
            }
        }

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
            var track: URL?
            var name: String?

            if let recentItem = recentListData {
                if let mediaPathInfo = recentItem.value(forKey: "mediaPathInfo") as? String,
                   let urlString = mediaPathInfo.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                   let url = URL(string: songPath + urlString) {

                    track = url
                    name = "\(url.lastPathComponent)"
                    UserDefaults.standard.set(
                        recentItem.value(forKey: "recentArtCover") as? String ?? "",
                        forKey: "\(url.deletingPathExtension().lastPathComponent)"
                    )
                }
            }

            guard let downloadURL = track, let fileName = name else { return }

            let destination: DownloadRequest.Destination = { _, _ in
                var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                documentsURL.appendPathComponent(fileName)
                return (documentsURL, [.removePreviousFile, .createIntermediateDirectories])
            }
            
            btnDownload.isHidden = true
            vwProgress.isHidden = false
            circularProgressView.setProgress(0)
            circularProgressView.isHidden = false

            AF.download(downloadURL, to: destination)
                .downloadProgress { progress in
                    DispatchQueue.main.async {
                        self.circularProgressView.setProgress(Float(CGFloat(Float(progress.fractionCompleted))))
                    }

                    if progress.fractionCompleted == 1.0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.circularProgressView.setProgress(1.0)
                            self.circularProgressView.lineWidth = 2
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                self.isDownload = true
                                self.configureDownload()
                                
                                let image = UIImage(systemName: "checkmark.circle.fill")?.withRenderingMode(.alwaysTemplate)
                                self.btnDownload.setImage(image, for: .normal)
                                self.btnDownload.tintColor = .systemGreen
                                self.btnDownload.layer.cornerRadius = 15
                                self.btnDownload.layer.borderColor = UIColor.systemGreen.cgColor
                                self.btnDownload.layer.borderWidth = 2
                                self.btnDownload.clipsToBounds = true
                                self.btnDownload.isUserInteractionEnabled = false
                                
                                self.vwProgress.isHidden = true
                                self.btnDownload.isHidden = false
                                self.circularProgressView.resetProgress()
                            }
                        }
                    }
                }
                .response { response in
                    if let destinationURL = response.fileURL {
                        print("Downloaded to: \(destinationURL)")
                    }
                }
        } else {
            // Show purchase screen
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
        self.tableBgHeightConstraints.constant = 190
        radioTableView.reloadData()
    }

    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: GADRequestError) {
        print("\(adLoader) failed with error: \(error.localizedDescription)")
    }

}

extension RecentPlayerViewController {

    // Build primary (HLS) and fallback (MP3) URLs from recentListData dictionary
    private func playbackURLs(from recentItem: NSDictionary) -> (primary: URL?, fallback: URL?) {
        var primaryURL: URL? = nil
        var fallbackURL: URL? = nil

        // Try explicit hls_mediaPath first
        if let hlsRaw = recentItem.value(forKey: "hls_mediaPath") as? String {
            let hls = hlsRaw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !hls.isEmpty {
                if let url = URL(string: hls), url.scheme != nil {
                    primaryURL = url
                } else if let encoded = hls.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: hlsSongPath + encoded) {
                    primaryURL = url
                }
            }
        }

        // Build MP3 fallback from mediaPathInfo
        if let mediaPathInfo = recentItem.value(forKey: "mediaPathInfo") as? String {
            let media = mediaPathInfo.trimmingCharacters(in: .whitespacesAndNewlines)
            if !media.isEmpty {
                if let url = URL(string: media), url.scheme != nil {
                    fallbackURL = url
                } else if let encoded = media.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: songPath + encoded) {
                    fallbackURL = url
                }
                // If no explicit primary, attempt to construct an HLS path from the MP3 filename
                if primaryURL == nil, let fallback = fallbackURL {
                    let baseName = fallback.deletingPathExtension().lastPathComponent
                    if let hlsURL = URL(string: hlsSongPath + baseName + ".m3u8") {
                        primaryURL = hlsURL
                    }
                }
            }
        }

        return (primaryURL, fallbackURL)
    }

    // Main play function with optional fallback URL (HLS primary, MP3 fallback)
    func play(url: URL, isPlay: Bool = false, fallbackURL: URL? = nil) {
        print("Playing URL: \(url)")
        
        // CRITICAL FIX: Remove time observer BEFORE reassigning player
        // This prevents the crash: "An instance of AVPlayer cannot remove a time observer
        // that was added by a different instance of AVPlayer"
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        
        // Invalidate KVO observer
        playerItemStatusObserver?.invalidate()
        playerItemStatusObserver = nil
        
        // Now pause and clear notifications after observer is removed
        player?.pause()
        if let currentItem = player?.currentItem {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: currentItem)
        }
        
        hasTriedFallbackForItem = false
        let playerItem = AVPlayerItem(url: url)
        
        // Observe item status to detect failure and switch to fallback if provided
        if let fallback = fallbackURL {
            playerItemStatusObserver = playerItem.observe(\.status, options: [.new, .initial]) { [weak self] item, change in
                guard let self = self else { return }
                if item.status == .failed {
                    guard !self.hasTriedFallbackForItem else { return }
                    self.hasTriedFallbackForItem = true
                    print("Primary playback failed, attempting fallback: \(fallback)")
                    DispatchQueue.main.async {
                        let fallbackItem = AVPlayerItem(url: fallback)
                        // Replace current item with fallback
                        player?.replaceCurrentItem(with: fallbackItem)

                        // Remove observer for the original item only (if any)
                        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)

                        // Register end-of-playback for the new fallback item so we still get didPlayToEnd notifications
                        NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying(sender:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: fallbackItem)

                        // Observe fallback readyToPlay to update UI
                        self.playerItemStatusObserver?.invalidate()
                        self.playerItemStatusObserver = fallbackItem.observe(\.status, options: [.new, .initial]) { [weak self] it, _ in
                            guard let self = self else { return }
                            if it.status == .readyToPlay {
                                DispatchQueue.main.async {
                                    if CMTIME_IS_VALID(it.asset.duration) {
                                        let durationSeconds = CMTimeGetSeconds(it.asset.duration)
                                        self.playerSlider.maximumValue = Float(durationSeconds)
                                        self.populateLabelWithTime(self.lblEndTime, time: durationSeconds)
                                    }
                                }
                            }
                        }
                        player?.play()
                    }
                } else if item.status == .readyToPlay {
                    DispatchQueue.main.async {
                        if CMTIME_IS_VALID(item.asset.duration) {
                            let durationSeconds = CMTimeGetSeconds(item.asset.duration)
                            self.playerSlider.maximumValue = Float(durationSeconds)
                            self.populateLabelWithTime(self.lblEndTime, time: durationSeconds)
                        }
                    }
                }
            }
        } else {
            // If no fallback, still observe readyToPlay to set duration
            playerItemStatusObserver = playerItem.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
                guard let self = self else { return }
                if item.status == .readyToPlay {
                    DispatchQueue.main.async {
                        if CMTIME_IS_VALID(item.asset.duration) {
                            let durationSeconds = CMTimeGetSeconds(item.asset.duration)
                            self.playerSlider.maximumValue = Float(durationSeconds)
                            self.populateLabelWithTime(self.lblEndTime, time: durationSeconds)
                        }
                    }
                }
            }
        }
        
        player = PlayObserver(playerItem: playerItem)
        self.playerSlider.minimumValue = 0.0
        self.playerSlider.maximumValue = 0.0
        populateLabelWithTime(self.lblStartTime, time: 0.0)
        populateLabelWithTime(self.lblEndTime, time: 0.0)
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying(sender:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        
        // IMPROVED: Time observer with higher precision and bounds checking
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(value: 1, timescale: 2),   // every 0.5 s is enough for lock screen
            queue: .main
        ) { [weak self] progressTime in
            guard let self = self else { return }

            let currentSeconds = CMTimeGetSeconds(progressTime)
            guard !currentSeconds.isNaN else { return }

            if let duration = player?.currentItem?.duration,
               CMTIME_IS_VALID(duration), !duration.seconds.isNaN {
                let maxSeconds = duration.seconds
                let display    = min(currentSeconds, maxSeconds)

                self.playerSlider.maximumValue = Float(maxSeconds)
                self.playerSlider.value        = Float(display)
                self.populateLabelWithTime(self.lblStartTime, time: display)
                self.populateLabelWithTime(self.lblEndTime,   time: maxSeconds)
            } else {
                self.playerSlider.value = Float(currentSeconds)
                self.populateLabelWithTime(self.lblStartTime, time: currentSeconds)
            }

            // ✅ FIX 11: Keep lock-screen elapsed time in sync every tick
            self.updateNowPlaying(isPause: !(player?.isPlaying ?? false))
        }


    }

    @objc func playerDidFinishPlaying(sender: Notification) {
        // Set to exact duration instead of 0 when playback finishes
        if let duration = player?.currentItem?.duration, CMTIME_IS_VALID(duration) {
            let durationSeconds = CMTimeGetSeconds(duration)
            playerSlider.value = Float(durationSeconds)
            populateLabelWithTime(self.lblStartTime, time: durationSeconds)
        } else {
            playerSlider.setValue(0, animated: true)
            populateLabelWithTime(self.lblStartTime, time: 0.0)
        }
        
        player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        
        if isRepeat {
            player?.play()
        } else {
            // Remove only the observer associated with the ended item (sender.object) instead of all items
            NotificationCenter.default.removeObserver(self,
                                                      name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                      object: sender.object)

            // Always remove time observer before switching to the next track to avoid "different instance" issues
            if let timeObserver = timeObserver {
                player?.removeTimeObserver(timeObserver)
                self.timeObserver = nil
            }

            if let recentListArray = recentListArray, let selectedIndex = selectedIndex {
                if selectedIndex < recentListArray.count-1 {
                    // (time observer already removed)
                }
            }
            self.forwardBtnPressed()
        }
    }

    // IMPROVED: Better time formatting to handle edge cases
    func populateLabelWithTime(_ label: UILabel, time: Double) {
        // Ensure non-negative time
        let validTime = max(0, time)
        
        // Round to nearest second to avoid display issues like 3:01 for 3:00
        let roundedTime = Int(validTime.rounded())
        
        let minutes = roundedTime / 60
        let seconds = roundedTime % 60
        
        label.text = String(format: "%02d:%02d", minutes, seconds)
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
        isLike = !isLike
        
        DispatchQueue.main.async {
            self.btnLike.setImage(
                UIImage(named: self.isLike ? "ic_like_filled" : "ic_like"),
                for: .normal
            )
        }
        
        configureLike()
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
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()

        // Always refresh elapsed time
        if let current = player?.currentTime(),
           CMTIME_IS_VALID(current), !current.seconds.isNaN {
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = current.seconds
        }

        // Fill in duration if it wasn't ready during setupNowPlaying
        if (info[MPMediaItemPropertyPlaybackDuration] as? Double ?? 0) == 0,
           let duration = player?.currentItem?.duration,
           CMTIME_IS_VALID(duration), !duration.seconds.isNaN {
            info[MPMediaItemPropertyPlaybackDuration] = duration.seconds
        }

        info[MPNowPlayingInfoPropertyPlaybackRate] = isPause ? 0.0 : 1.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }


    func setupNowPlaying() {
        // Capture the art URL NOW, before any async work, so we always
        // use the URL that belongs to the track that just started playing.
        let artURLString = recentListData?.value(forKey: "recentArtCover") as? String

        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle]               = trackTitle.text ?? ""
        nowPlayingInfo[MPMediaItemPropertyArtist]              = artistName.text ?? ""
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream]   = false
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate]   = player?.isPlaying == true ? 1.0 : 0.0

        // Push basic info immediately (no artwork yet) so title/artist appear right away
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

        // ✅ FIX: Fetch artwork directly from URL, not from UIImageView.image
        //         This guarantees we get the NEW song's art even if the
        //         UIImageView hasn't finished loading yet.
        fetchArtworkImage(from: artURLString) { [weak self] image in
            guard let self = self else { return }

            DispatchQueue.main.async {
                // Rebuild nowPlayingInfo fresh — the player may have updated
                // elapsed time since we first pushed, so re-read current values.
                var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()

                if let duration = player?.currentItem?.duration,
                   CMTIME_IS_VALID(duration), !duration.seconds.isNaN {
                    info[MPMediaItemPropertyPlaybackDuration] = duration.seconds
                }
                if let current = player?.currentTime(),
                   CMTIME_IS_VALID(current), !current.seconds.isNaN {
                    info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = current.seconds
                }
                info[MPNowPlayingInfoPropertyPlaybackRate] = player?.isPlaying == true ? 1.0 : 0.0

                if let image = image {
                    let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    info[MPMediaItemPropertyArtwork] = artwork
                }

                MPNowPlayingInfoCenter.default().nowPlayingInfo = info
            }
        }
    }

    private func fetchArtworkImage(from urlString: String?, completion: @escaping (UIImage?) -> Void) {
        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        // Use AlamofireImage's shared downloader (already in your project)
        // so it benefits from caching — if it's already cached this is instant
        UIImageView().af_setImage(withURL: url) // warm the cache (no-op if cached)
        
        AF.request(url).responseData { response in
            switch response.result {
            case .success(let data):
                let image = UIImage(data: data)
                completion(image)
            case .failure:
                completion(nil)
            }
        }
    }



    func setupRemoteTransportControls() {
        let cc = MPRemoteCommandCenter.shared()

        // ✅ FIX: Use removeTarget(nil) to clear all previously added targets
        //         (MPRemoteCommand has no removeAllTargets — nil removes everything)
        cc.playCommand.removeTarget(nil)
        cc.pauseCommand.removeTarget(nil)
        cc.togglePlayPauseCommand.removeTarget(nil)
        cc.nextTrackCommand.removeTarget(nil)
        cc.previousTrackCommand.removeTarget(nil)
        cc.changePlaybackPositionCommand.removeTarget(nil)

        cc.playCommand.isEnabled                 = true
        cc.pauseCommand.isEnabled                = true
        cc.togglePlayPauseCommand.isEnabled      = true
        cc.nextTrackCommand.isEnabled            = true
        cc.previousTrackCommand.isEnabled        = true
        cc.changePlaybackPositionCommand.isEnabled = true

        cc.playCommand.addTarget { [weak self] _ in
            guard let self = self, let p = player, !p.isPlaying else { return .commandFailed }
            p.play()
            DispatchQueue.main.async { self.playPauseBtn.setImage(UIImage(named: "ic_pause"), for: .normal) }
            self.updateNowPlaying(isPause: false)
            return .success
        }

        cc.pauseCommand.addTarget { [weak self] _ in
            guard let self = self, let p = player, p.isPlaying else { return .commandFailed }
            p.pause()
            DispatchQueue.main.async { self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal) }
            self.updateNowPlaying(isPause: true)
            return .success
        }

        cc.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            DispatchQueue.main.async { self.pausePressed() }
            return .success
        }

        cc.nextTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            DispatchQueue.main.async {
                self.pausePlayer()
                self.forwardBtnPressed()
            }
            return .success
        }

        cc.previousTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            DispatchQueue.main.async {
                self.pausePlayer()
                self.backwardBtnPressed()
            }
            return .success
        }

        cc.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let e = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            let target = CMTime(seconds: e.positionTime, preferredTimescale: 1)
            player?.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
            self.updateNowPlaying(isPause: !(player?.isPlaying ?? false))
            return .success
        }
    }


    func pausePlayer() {
        // Remove time observer before pausing
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        
        player?.pause()
        self.playerSlider.setValue(0, animated: true)
        self.populateLabelWithTime(self.lblStartTime, time: 0.0)
        player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
    }

}

// MARK: - Like/Download Management
extension RecentPlayerViewController {

    func isAlreadyLiked() {
        guard let recentItem = recentListData else { return }

        let savedTracks = UserDefaultsManager.shared.localTracksData
        let trackID = recentItem["recentTrackID"] as? Int ?? 0

        let isInFav = savedTracks.contains { $0.trackid == trackID && $0.isFav }
        isLike = isInFav

        DispatchQueue.main.async {
            let imageName = self.isLike ? "ic_like_filled" : "ic_like"
            self.btnLike.setImage(UIImage(named: imageName), for: .normal)
        }
    }

    func isAlreadyDownloaded() {
        guard let recentItem = recentListData else { return }

        let savedTracks = UserDefaultsManager.shared.localTracksData
        let trackID = recentItem["recentTrackID"] as? Int ?? 0

        let isDownloaded = savedTracks.contains { $0.trackid == trackID && $0.isDownload }
        isDownload = isDownloaded

        DispatchQueue.main.async {
            if self.isDownload {
                let image = UIImage(systemName: "checkmark.circle.fill")?.withRenderingMode(.alwaysTemplate)
                self.btnDownload.setImage(image, for: .normal)
                self.btnDownload.tintColor = .systemGreen
                self.btnDownload.layer.cornerRadius = 15
                self.btnDownload.layer.borderColor = UIColor.systemGreen.cgColor
                self.btnDownload.layer.borderWidth = 2
                self.btnDownload.clipsToBounds = true
                self.btnDownload.isUserInteractionEnabled = false
            } else {
                self.btnDownload.setImage(UIImage(named: "ic_download"), for: .normal)
                self.btnDownload.layer.cornerRadius = 0
                self.btnDownload.layer.borderWidth = 0
                self.btnDownload.layer.borderColor = nil
                self.btnDownload.clipsToBounds = false
                self.btnDownload.isUserInteractionEnabled = true
            }
        }
    }

    func configureLike() {
        guard let recentItem = recentListData else { return }

        var savedTracks = UserDefaultsManager.shared.localTracksData
        let trackID = recentItem["recentTrackID"] as? Int ?? 0

        if let index = savedTracks.firstIndex(where: { $0.trackid == trackID }) {
            savedTracks[index].isFav = isLike
        } else if let newItem = SongModel(recentItem: recentItem) {
            newItem.isFav = isLike
            savedTracks.append(newItem)
        }

        UserDefaultsManager.shared.localTracksData = savedTracks
    }

    func configureDownload() {
        guard let recentItem = recentListData else { return }

        var savedTracks = UserDefaultsManager.shared.localTracksData
        let trackID = recentItem["recentTrackID"] as? Int ?? 0

        if let index = savedTracks.firstIndex(where: { $0.trackid == trackID }) {
            savedTracks[index].isDownload = true
            savedTracks[index].track = recentItem["recentTrack"] as? String ?? savedTracks[index].track
            savedTracks[index].artist = recentItem["recentArtist"] as? String ?? savedTracks[index].artist
            savedTracks[index].artcover = recentItem["recentArtCover"] as? String ?? savedTracks[index].artcover
        } else if let newItem = SongModel(recentItem: recentItem) {
            newItem.isDownload = true
            savedTracks.append(newItem)
        }

        UserDefaultsManager.shared.localTracksData = savedTracks
    }

}
extension RecentPlayerViewController: OptionsViewControllerDelegate {
    func didUpdateTrackMetadata() {
        DispatchQueue.main.async {
            self.isAlreadyLiked()
            self.isAlreadyDownloaded()
        }
    }
}
