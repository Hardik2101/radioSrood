import UIKit
import SWRevealViewController
import Alamofire
import AlamofireImage
import GoogleMobileAds
import StoreKit
import MediaPlayer
import AVKit

class MyMusicPlayerViewController: UIViewController, GADBannerViewDelegate {
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
    @IBOutlet var vwLyrics: UIView!
    @IBOutlet weak var heightView: NSLayoutConstraint!

    @IBOutlet var vwProgress: UIView!


    var track: [PodcastObject]?
    var tempTrack: [PodcastObject]?
    var firstTrackList: [PodcastObject]?
    var dataHelper: DataHelper!
    var nativeAd: GADUnifiedNativeAd?
    var adLoader: GADAdLoader!
    var isSetupRemoteTransport = false
    var radioUrl: String?
    var artImageURL: URL?
    var selectedIndex: Int = 0
    var isPlay: Bool = true
    var isSetMusic = true
    var isLike = false
    var isDownload = false // Added for download status
    var isRepeat = false
    var timeObserver: Any?
    private var lyricSynced: String = ""
    var imageURl: URL?
    var circularProgressView: CircularProgressView!
    private var isPurchaseSuccess: Bool = false // Added for IAP handling

    override func viewDidLoad() {
        super.viewDidLoad()
        
        radioTableView.delegate = self
        radioTableView.dataSource = self
        let yourBackImage = UIImage(named: "left-arrow")
        self.navigationController?.navigationBar.backIndicatorImage = yourBackImage
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = yourBackImage
        self.navigationController?.navigationBar.tintColor = .white
        self.navigationController?.navigationBar.backItem?.title = ""
        self.navigationController?.navigationBar.topItem?.title = ""
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        radioTableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: 0.1))
        radioTableView.tableFooterView = UIView()
        if let reveal = self.revealViewController() {
            self.view!.addGestureRecognizer(reveal.panGestureRecognizer())
        }
        handleRecentInView(index: self.selectedIndex)
        self.manageTableViewScroll()
        loadNativeAd()
        isSetupRemoteTransport = true
        NotificationCenter.default.addObserver(
            self, selector: #selector(didBecomeActiveNotificationReceived),
            name: NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification"), object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(playerInterruption(notification:)),
            name: NSNotification.Name(rawValue: "AVAudioSessionInterruptionNotification"), object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleIAPPurchase),
            name: .PurchaseSuccess, object: nil
        )
        radioTableView.register(UINib(nibName: "BannerAdCell", bundle: nil), forCellReuseIdentifier: "BannerAdCell")
        self.radioTableView.isScrollEnabled = false
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(lyricsBtnClicked))
        vwLyrics.isUserInteractionEnabled = true
        vwLyrics.addGestureRecognizer(tapGesture)
        setupCircularProgressView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        radioTableView.reloadData()
        TabbarVC.available?.miniPlayer.miniplayer(hide: true)
        NotificationCenter.default.post(name: .MiniPlayerVisibilityChanged, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        TabbarVC.available?.miniPlayer.miniplayer(hide: false)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    deinit {
        UIApplication.shared.endReceivingRemoteControlEvents()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [:]
        NotificationCenter.default.removeObserver(
            self, name: NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification"), object: nil
        )
        NotificationCenter.default.removeObserver(
            self, name: NSNotification.Name(rawValue: "AVAudioSessionInterruptionNotification"), object: nil
        )
        NotificationCenter.default.removeObserver(self)
        print("Remove screen")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
    
    func manageTableViewScroll() {
        DispatchQueue.main.async {
            self.radioTableView.reloadData()
            self.radioTableView.layoutIfNeeded()
            let contentHeight = self.radioTableView.contentSize.height
            self.tableBgHeightConstraints.constant = contentHeight
            let mainCount = 2
            let count = mainCount + ((self.tempTrack?.count ?? 0) - 1)
            print("TableView content height:::: \(count)")
            self.tableBgHeightConstraints.constant = CGFloat(count * 90)
            print("TableView content height: \(contentHeight)")
        }
    }
    
    func handleRecentInView(index: Int) {
        guard index >= 0, let tracks = track, index < tracks.count else {
            print("Invalid track index: \(index)")
            return
        }
        self.artCoverImage.layer.cornerRadius = 3
        self.artCoverImage.layer.masksToBounds = true
        let track = tracks[index]
        if let imageURL = track.imageURL {
            artCoverImage.af_setImage(withURL: imageURL, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            bgImageView.af_setImage(withURL: imageURL, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            self.imageURl = imageURL
        }
        self.trackTitle.text = track.trackName
        self.artistName.text = track.artistName
        isAlreadyDownloaded(track: track) // Check download status
        isAlreadyLiked(track: track)
        DataHelper.getLyricsData(artist: track.artistName ?? "", track: track.trackName ?? "") { lyricItem in
            if let lyricItem = lyricItem {
                print("✅ Artist: \(lyricItem.artistName)")
                print("✅ Track: \(lyricItem.trackName)")
                print("✅ Synced Lyrics Path: \(lyricItem.syncedLyrics)")
                self.lyricSynced = lyricItem.syncedLyrics
            } else {
                print("⚠️ No lyrics found.")
                self.lyricSynced = ""
            }
            DispatchQueue.main.async {
                if self.lyricSynced.isEmpty {
                    self.heightView.constant = 0
                    self.vwLyrics.isHidden = true
                } else {
                    self.heightView.constant = 20
                    self.vwLyrics.isHidden = false
                }
            }
        }
        if isSetMusic {
            isSetMusic = false
            self.play(url: track.file ?? URL(string: "")!, isPlay: self.isPlay)
        }
        
        AppPlayer.miniPlayerInfo = BasicDetail(
            songImage: track.imageURL?.absoluteString ?? "",
            songNameTitle: track.trackName ?? "",
            artistSubtitle: track.artistName ?? "",
            musicVC: self
        )
        if isSetupRemoteTransport {
            isSetupRemoteTransport = false
            self.setupRemoteTransportControls()
        }
    }

    @objc func backwardBtnPressed() {
        if let track = track, selectedIndex > 0 {
            selectedIndex -= 1
            isSetMusic = true
            isPlay = true
            handleRecentInView(index: selectedIndex)
            self.manageTableViewScroll()
            let indexToScroll = 2 + selectedIndex - (firstTrackList?.count ?? 0)
            if indexToScroll >= 0 && indexToScroll < radioTableView.numberOfRows(inSection: 0) {
                let indexPathToScroll = IndexPath(row: indexToScroll, section: 0)
                radioTableView.scrollToRow(at: indexPathToScroll, at: .top, animated: true)
            } else {
                print("Invalid index for scrolling: \(indexToScroll)")
            }
        } else {
            player?.pause()
            self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
        }
    }

    @objc func forwardBtnPressed() {
        if let track = track, selectedIndex < track.count - 1 {
            selectedIndex += 1
            isSetMusic = true
            isPlay = true
            handleRecentInView(index: selectedIndex)
            self.manageTableViewScroll()
            let indexToScroll = 2 + selectedIndex - (firstTrackList?.count ?? 0)
            if indexToScroll >= 0 && indexToScroll < radioTableView.numberOfRows(inSection: 0) {
                let indexPathToScroll = IndexPath(row: indexToScroll, section: 0)
                radioTableView.scrollToRow(at: indexPathToScroll, at: .top, animated: true)
            } else {
                print("Invalid index for scrolling: \(indexToScroll)")
            }
        } else {
            player?.pause()
            self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
        }
    }

    private func setupCircularProgressView() {
        circularProgressView = CircularProgressView(frame: vwProgress.bounds)
        circularProgressView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        circularProgressView.isHidden = true
        vwProgress.addSubview(circularProgressView)
    }

    func shareBtnClicked(url: URL?) {
        guard let url = url else {
            print("Error: No URL provided for sharing")
            return
        }
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        vc.modalPresentationStyle = .popover
        if let wPPC = vc.popoverPresentationController {
            wPPC.sourceView = self.view
        }
        self.present(vc, animated: true)
    }

    @IBAction func clickOn_btnBack(_ sender: Any) {
        self.popToBack()
        self.dismiss(animated: true)
    }

    @IBAction func likeBtnPressed(_ sender: Any) {
        if isLike {
                btnLike.setImage(UIImage(named: "ic_like"), for: .normal)
                isLike = false
                showToast(message: "Removed from favorites", font: .systemFont(ofSize: 12.0))
            } else {
                btnLike.setImage(UIImage(named: "ic_like_filled"), for: .normal)
                isLike = true
                showToast(message: "Added to favorites", font: .systemFont(ofSize: 12.0))
            }
            configureLike(index: selectedIndex)
    }
    
    @IBAction func clickOn_btnDownload(_ sender: UIButton) {
        let purchase = IAPHandler.shared.isGetPurchase() || isPurchaseSuccess
        guard let item = track?[safe: selectedIndex] else {
            print("Error: No track selected for download")
            return
        }
        guard let url = item.file else {
            print("Error: Invalid media URL for track: \(item.trackName ?? "Unknown")")
            return
        }
        
        if purchase {
            let name = url.lastPathComponent
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let destinationURL = documentsURL.appendingPathComponent(name)
            btnDownload.isHidden = true
            vwProgress.isHidden = false
            circularProgressView.setProgress(0)
            circularProgressView.isHidden = false
            AF.download(url, to: { _, _ in
                return (destinationURL, [.removePreviousFile, .createIntermediateDirectories])
            })
            .downloadProgress { [weak self] progress in
                DispatchQueue.main.async {
                    self?.circularProgressView.setProgress(Float(CGFloat(Float(progress.fractionCompleted))))
                }
                if progress.fractionCompleted == 1.0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self?.circularProgressView.setProgress(1.0)
                        self?.circularProgressView?.lineWidth = 8
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self?.vwProgress.isHidden = true
                            self?.btnDownload.isHidden = false
                            self?.isDownload = true
                            self?.circularProgressView.resetProgress()
                            let image = UIImage(systemName: "checkmark.circle.fill")?.withRenderingMode(.alwaysTemplate)
                            self?.btnDownload.setImage(image, for: .normal)
                            self?.btnDownload.tintColor = .systemGreen
                            self?.btnDownload.layer.cornerRadius = 15
                            self?.btnDownload.layer.borderColor = UIColor.systemGreen.cgColor
                            self?.btnDownload.layer.borderWidth = 2
                            self?.btnDownload.clipsToBounds = true
                            self?.btnDownload.isUserInteractionEnabled = false
                            self?.configureDownload(index: self?.selectedIndex ?? 0)
                        }
                    }
                }
            }
            .response { response in
                if let destinationURL = response.fileURL {
                    print("File downloaded to: \(destinationURL)")
                    UserDefaults.standard.set(item.imageURL?.absoluteString, forKey: "\(url.deletingPathExtension().lastPathComponent)")
                } else if let error = response.error {
                    print("Download error: \(error.localizedDescription)")
                }
            }
        } else {
            let vc = storyboard?.instantiateViewController(withIdentifier: "IAPVC") as! IAPVC
            vc.isshowbackButton = true
            let navVC = UINavigationController(rootViewController: vc)
            navVC.navigationBar.isHidden = true
            navVC.modalPresentationStyle = .fullScreen
            present(navVC, animated: true)
        }
    }

    @objc func lyricsBtnClicked() {
        guard let trackItem = track?[selectedIndex] else {
            print("No track selected for lyrics")
            return
        }
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "LyricPlayViewController") as! LyricPlayViewController
        vc.currentSong = trackItem.convertToSongModel()
        vc.imageURl = self.imageURl
        vc.lyricnew = self.lyricSynced
        self.present(vc, animated: true)
    }

    @objc private func handleIAPPurchase() {
        isPurchaseSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.isPurchaseSuccess = false
        }
    }
    
    // Check if track is already downloaded
    func isAlreadyDownloaded(track: PodcastObject) {
        let savedTracks = UserDefaultsManager.shared.localTracksData
        let isInDownloads = savedTracks.first { $0.isDownload && $0.trackid == track.convertToSongModel().trackid }
        isDownload = isInDownloads != nil
        if isDownload {
            let image = UIImage(systemName: "checkmark.circle.fill")?.withRenderingMode(.alwaysTemplate)
            btnDownload.setImage(image, for: .normal)
            btnDownload.tintColor = .systemGreen
            btnDownload.layer.cornerRadius = 15
            btnDownload.layer.borderColor = UIColor.systemGreen.cgColor
            btnDownload.layer.borderWidth = 2
            btnDownload.clipsToBounds = true
            btnDownload.isUserInteractionEnabled = false
        } else {
            btnDownload.setImage(UIImage(named: "ic_download"), for: .normal)
            btnDownload.layer.cornerRadius = 0
            btnDownload.layer.borderWidth = 0
            btnDownload.layer.borderColor = nil
            btnDownload.clipsToBounds = false
            btnDownload.isUserInteractionEnabled = true
        }
        print("Checked download status for track: \(track.trackName ?? "Unknown"), isDownload: \(isDownload)")
    }

    // Configure download status in UserDefaults
    func configureDownload(index: Int) {
        guard let item = track?[safe: index] else {
            print("Error: No track to configure download at index \(index)")
            return
        }
        var savedTracks = UserDefaultsManager.shared.localTracksData
        let songModel = item.convertToSongModel()
        if let trackIndex = savedTracks.firstIndex(where: { $0.trackid == songModel.trackid }) {
            savedTracks[trackIndex].isDownload = isDownload
        } else {
            var newItem = songModel
            newItem.isDownload = isDownload
            savedTracks.append(newItem)
        }
        UserDefaultsManager.shared.localTracksData = savedTracks
        print("Configured download for track: \(item.trackName ?? "Unknown"), isDownload: \(isDownload)")
    }
    
    func isAlreadyLiked(track: PodcastObject) {
        let savedTracks = UserDefaultsManager.shared.localTracksData
        let songModel = track.convertToSongModel()
        let isInFav = savedTracks.first { $0.isFav && $0.trackid == songModel.trackid }
        isLike = isInFav != nil
        btnLike.setImage(UIImage(named: isLike ? "ic_like_filled" : "ic_like"), for: .normal)
        print("Checked like status for track: \(track.trackName ?? "Unknown"), isLike: \(isLike)")
    }

    // Configure like status in UserDefaults
    func configureLike(index: Int) {
        guard let item = track?[safe: index] else {
            print("Error: No track to configure like at index \(index)")
            return
        }
        var savedTracks = UserDefaultsManager.shared.localTracksData
        let songModel = item.convertToSongModel()
        if let trackIndex = savedTracks.firstIndex(where: { $0.trackid == songModel.trackid }) {
            savedTracks[trackIndex].isFav = isLike
        } else {
            var newItem = songModel
            newItem.isFav = isLike
            savedTracks.append(newItem)
        }
        UserDefaultsManager.shared.localTracksData = savedTracks
        print("Configured like for track: \(item.trackName ?? "Unknown"), isLike: \(isLike)")
    }

}

extension MyMusicPlayerViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let mainCount = 2
        let trackCount = (tempTrack?.count ?? 0) > 1 ? (tempTrack!.count - 1) : 0
        return mainCount + trackCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BannerAdCell", for: indexPath) as! BannerAdCell
            for subview in cell.vwMain.subviews {
                subview.removeFromSuperview()
            }
            if IAPHandler.shared.isGetPurchase() {
                cell.vwMain.isHidden = true
                cell.heightOfVw.constant = 0
            } else {
                cell.vwMain.isHidden = false
                cell.heightOfVw.constant = 65
                let bannerView = GADBannerView(adSize: kGADAdSizeBanner)
                bannerView.adUnitID = GOOGLE_ADMOB_ForMusicPlayer
                bannerView.rootViewController = self
                bannerView.delegate = self
                bannerView.load(GADRequest())
                cell.vwMain.addSubview(bannerView)
                bannerView.frame = cell.vwMain.bounds
            }
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecentPlayerOptionCell", for: indexPath) as! RecentPlayerOptionCell
            cell.selectionStyle = .none
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "MusicListCell", for: indexPath) as! MusicListCell
            cell.selectionStyle = .none
            cell.artCoverImage.layer.cornerRadius = 3
            cell.artCoverImage.layer.masksToBounds = true
            if let item = tempTrack?[(indexPath.row + 1) - 2] {
                if let url = item.imageURL {
                    cell.artCoverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                    cell.imgBg.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                }
                cell.trackTitle.text = item.trackName
                cell.artistName.text = item.artistName
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0, 1:
            break
        default:
            guard let cell = tableView.cellForRow(at: indexPath) else {
                print("No cell found at \(indexPath)")
                return
            }
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            feedbackGenerator.prepare()
            feedbackGenerator.impactOccurred()
            cell.layer.shadowOpacity = 0.3
            cell.layer.shadowOffset = CGSize(width: 0, height: 2)
            cell.layer.shadowRadius = 4
            cell.isUserInteractionEnabled = false
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                cell.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
            }) { _ in
                UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                    cell.transform = .identity
                    cell.layer.shadowOpacity = 0
                    cell.isUserInteractionEnabled = true
                }) { _ in
                    self.pausePlayer()
                    let selectedTrackIndex = (self.firstTrackList?.count ?? 0) + indexPath.row - 1
                    if let track = self.track, selectedTrackIndex < track.count {
                        self.selectedIndex = selectedTrackIndex
                        self.isPlay = true
                        self.isSetMusic = true
                        self.handleRecentInView(index: self.selectedIndex)
                        self.manageTableViewScroll()
                        let totalRowsInSection = tableView.numberOfRows(inSection: 0)
                        if selectedTrackIndex < totalRowsInSection {
                            let indexPathToScroll = IndexPath(row: selectedTrackIndex, section: 0)
                            tableView.scrollToRow(at: indexPathToScroll, at: .top, animated: true)
                        } else {
                            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                        }
                    } else {
                        print("Invalid selected index: \(selectedTrackIndex)")
                    }
                }
            }
        }
    }
}

extension MyMusicPlayerViewController: GADAdLoaderDelegate, GADUnifiedNativeAdLoaderDelegate {
    func loadNativeAd() {
        guard !IAPHandler.shared.isGetPurchase() else {
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
        guard !IAPHandler.shared.isGetPurchase() else {
            return
        }
        self.nativeAd = nativeAd
        self.manageTableViewScroll()
    }

    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: GADRequestError) {
        print("\(adLoader) failed with error: \(error.localizedDescription)")
    }
}

extension MyMusicPlayerViewController {
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
//        self.btnLike.setImage(UIImage(named: "ic_like"), for: .normal)
//        self.isLike = false
        self.setupNowPlaying()
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying(sender:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 1), queue: DispatchQueue.global(), using: { [weak self] (progressTime) in
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
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
            if let track = track, selectedIndex < track.count - 1 {
                if let timeObserver = timeObserver, let player = player {
                    player.removeTimeObserver(timeObserver)
                }
                self.forwardBtnPressed()
            }
        }
    }

    func populateLabelWithTime(_ label: UILabel, time: Double) {
        let minutes = Int(time / 60)
        let seconds = Int(time) - minutes * 60
        label.text = String(format: "%02d", minutes) + ":" + String(format: "%02d", seconds)
    }

    @IBAction func pausePressed() {
        if (player?.isPlaying ?? true) {
            DispatchQueue.main.async {
                self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
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

    func isLastTrack() -> Bool {
        guard let track = track else {
            return false
        }
        return selectedIndex == track.count - 1
    }

    @IBAction func backwardBtnEvent(_ sender: Any) {
        self.pausePlayer()
        self.backwardBtnPressed()
    }

    @IBAction func forwardBtnEvent(_ sender: Any) {
        if isLastTrack() {
            return
        }
        self.pausePlayer()
        self.forwardBtnPressed()
    }

    @IBAction func progressSliderValueChanged() {
        let seconds: Int64 = Int64(playerSlider.value)
        let targetTime: CMTime = CMTimeMake(value: seconds, timescale: 1)
        player?.seek(to: targetTime)
    }
    
    func updateNowPlaying(isPause: Bool) {
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
                DispatchQueue.global(qos: .background).async {
                    guard let mediaArtwork = self.createMediaArtwork(from: image) else {
                        print("Error creating media artwork")
                        return
                    }
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = mediaArtwork
                    DispatchQueue.main.async {
                        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                    }
                }
            } else {
                print("Error: artCoverImage.image is nil")
            }
        }
    }
    
    func createMediaArtwork(from image: UIImage) -> MPMediaItemArtwork? {
        guard #available(iOS 10.0, *), let cgImage = image.cgImage else {
            print("Error: Failed to create CGImage from UIImage or iOS version < 10.0")
            return nil
        }
        return MPMediaItemArtwork(boundsSize: image.size) { _ in
            return UIImage(cgImage: cgImage)
        }
    }

    func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            if let player = player {
                if !player.isPlaying {
                    player.play()
                    self.playPauseBtn.setImage(UIImage(named: "ic_pause"), for: .normal)
                    return .success
                }
            }
            return .commandFailed
        }
        commandCenter.pauseCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            if let player = player {
                if player.isPlaying {
                    player.pause()
                    self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
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
        if let player = player, let timeObserver = timeObserver {
            player.pause()
            player.removeTimeObserver(timeObserver)
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
            self.timeObserver = nil
        }
        self.playerSlider.setValue(0, animated: true)
        self.populateLabelWithTime(self.lblStartTime, time: 0.0)
        player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
        updateNowPlaying(isPause: true)
    }
}

