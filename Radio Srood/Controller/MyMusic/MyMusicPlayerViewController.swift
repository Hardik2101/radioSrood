import UIKit
import SWRevealViewController
import Alamofire
import AlamofireImage
import GoogleMobileAds
import StoreKit
import MediaPlayer
import AVKit
import SpotlightLyrics
import AVPlayerViewControllerSubtitles


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
    @IBOutlet weak var lblLyricsText: UILabel!

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
    var isDownload = false
    var isRepeat = false
    var isShuffle: Bool = false
    var timeObserver: Any?
    private var currentPlayer: AVPlayer?  // FIX: track current player for safe observer removal
    private var playerItemStatusObserver: NSKeyValueObservation?
    private var hasTriedFallbackForItem: Bool = false

    private var lyricSynced: String = ""
    var imageURl: URL?
    var circularProgressView: CircularProgressView!
    private var isPurchaseSuccess: Bool = false
    private var isBookMarked: Bool = false

    var isShowOptionList: Bool = false
    private var parsedLyrics: [LyricLine] = []
    private var lastIndex: Int? = nil

    var shuffleQueue: [Int] = []
    var isSyncedLyrics = false

    // MARK: - Lifecycle
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
            self.view.addGestureRecognizer(reveal.panGestureRecognizer())
        }
        self.lblLyricsText.text = ""
        handleRecentInView(index: self.selectedIndex)
        self.manageTableViewScroll()
        loadNativeAd()
        isSetupRemoteTransport = true

        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActiveNotificationReceived), name: NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerInterruption(notification:)), name: NSNotification.Name(rawValue: "AVAudioSessionInterruptionNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleIAPPurchase), name: .PurchaseSuccess, object: nil)

        radioTableView.register(UINib(nibName: "BannerAdCell", bundle: nil), forCellReuseIdentifier: "BannerAdCell")
        self.radioTableView.isScrollEnabled = false

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(lyricsBtnClicked))
        vwLyrics.isUserInteractionEnabled = true
        vwLyrics.addGestureRecognizer(tapGesture)
        setupCircularProgressView()

        // FIX: Setup remote transport controls once in viewDidLoad
        setupRemoteTransportControls()
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
        // FIX: Remove all remote command targets on deinit to avoid ghost handlers
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)
        NotificationCenter.default.removeObserver(self)
        stopAndClearPlayer()
        print("MyMusicPlayerViewController deinit")
    }

    // MARK: - Single clean teardown method
    private func stopAndClearPlayer() {
        playerItemStatusObserver = nil
        if let obs = timeObserver, let p = currentPlayer {
            p.removeTimeObserver(obs)
        }
        timeObserver = nil
        if let p = player {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: p.currentItem)
            p.pause()
        }
        currentPlayer = nil
        hasTriedFallbackForItem = false
    }

    // MARK: - Lyrics
    func showLyric(toTime time: TimeInterval) {
        guard !parsedLyrics.isEmpty else { return }
        guard let index = parsedLyrics.firstIndex(where: { $0.time >= time }) else { return }
        guard lastIndex == nil || index - 1 != lastIndex else { return }
        if index > 0 {
            let line = parsedLyrics[index - 1]
            lastIndex = index - 1
            DispatchQueue.main.async {
                self.lblLyricsText.text = self.vwLyrics.isHidden ? "" : line.text
            }
        }
    }

    private func parseLyricSynced() {
        parsedLyrics.removeAll()
        let lines = lyricSynced.components(separatedBy: .newlines)
        let regex = try? NSRegularExpression(pattern: #"\[(\d{2}):(\d{2})\.(\d{2})\](.*)"#)
        for line in lines {
            guard let match = regex?.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                  match.numberOfRanges == 5,
                  let minRange = Range(match.range(at: 1), in: line),
                  let secRange = Range(match.range(at: 2), in: line),
                  let msecRange = Range(match.range(at: 3), in: line),
                  let textRange = Range(match.range(at: 4), in: line)
            else { continue }
            let minutes = Double(line[minRange]) ?? 0
            let seconds = Double(line[secRange]) ?? 0
            let millis = Double(line[msecRange]) ?? 0
            let time = minutes * 60 + seconds + millis / 100
            let text = String(line[textRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            parsedLyrics.append(LyricLine(time: time, text: text))
        }
    }

    private func showLyrics() {
        heightView.constant = 20
        vwLyrics.isHidden = false
    }

    private func hideLyrics() {
        heightView.constant = 0
        vwLyrics.isHidden = true
        lblLyricsText.text = ""
    }

    // MARK: - Notifications
    @objc func didBecomeActiveNotificationReceived() {
        updateNowPlaying(isPause: !(player?.isPlaying ?? false))
    }

    @objc func playerInterruption(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        if type == .began {
            player?.pause()
            updateNowPlaying(isPause: true)
        } else if type == .ended {
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    guard let self = self else { return }
                    player?.play()
                    self.setupNowPlaying()
                    self.updateNowPlaying(isPause: false)
                }
            }
        }
    }

    @objc private func handleIAPPurchase() {
        isPurchaseSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { self.isPurchaseSuccess = false }
        manageTableViewScroll()
    }

    // MARK: - UI Helpers
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
            let mainCount = 2
            let count = mainCount + ((self.tempTrack?.count ?? 0) - 1)
            self.tableBgHeightConstraints.constant = CGFloat(count * 90)
        }
    }

    func sanitizeStreamURL(_ urlString: String?) -> URL? {
        guard let urlString = urlString else { return nil }
        var decoded = urlString.removingPercentEncoding ?? urlString
        if let range = decoded.range(of: "https://", options: .backwards) {
            decoded = String(decoded[range.lowerBound...])
        }
        return URL(string: decoded)
    }

    func resetShuffleQueue() {
        guard let track = track else { return }
        shuffleQueue = Array(0..<track.count).shuffled()
    }

    // MARK: - Track Loading
    func handleRecentInView(index: Int) {
        var idx = index
        if isShuffle {
            if shuffleQueue.isEmpty { resetShuffleQueue() }
            idx = shuffleQueue.removeFirst()
            selectedIndex = idx
        }
        guard idx >= 0, let tracks = track, idx < tracks.count else {
            print("Invalid track index: \(idx)")
            return
        }
        self.artCoverImage.layer.cornerRadius = 3
        self.artCoverImage.layer.masksToBounds = true
        let trackItem = tracks[idx]
        if let imageURL = trackItem.imageURL {
            artCoverImage.af_setImage(withURL: imageURL, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            bgImageView.af_setImage(withURL: imageURL, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            self.imageURl = imageURL
        }
        self.trackTitle.text = trackItem.trackName
        self.artistName.text = trackItem.artistName

        btnDownload.isHidden = !isShowOptionList
        btnLike.isHidden = !isShowOptionList

        isAlreadyDownloaded(track: trackItem)
        isAlreadyLiked(track: trackItem)
        isAlreadyBookmarked(track: trackItem)
        lastIndex = nil

        DataHelper.getLyricsData(artist: trackItem.artistName ?? "", track: trackItem.trackName ?? "") { [weak self] lyricItem in
            guard let self = self else { return }
            guard let lyricItem = lyricItem else {
                DispatchQueue.main.async { self.hideLyrics() }
                return
            }
            let synced = lyricItem.syncedLyrics.trimmingCharacters(in: .whitespacesAndNewlines)
            let plain = lyricItem.plainLyrics.trimmingCharacters(in: .whitespacesAndNewlines)
            DispatchQueue.main.async {
                if !synced.isEmpty {
                    self.lyricSynced = synced
                    self.parseLyricSynced()
                    self.showLyrics()
                    self.lblLyricsText.text = ""
                    self.isSyncedLyrics = true
                } else if !plain.isEmpty {
                    self.lyricSynced = plain
                    self.hideLyrics()
                    self.isSyncedLyrics = false
                } else {
                    self.hideLyrics()
                }
            }
        }

        if isSetMusic {
            isSetMusic = false
            let urls = playbackURLs(for: trackItem)
            if let primary = urls.primary {
                self.play(url: primary, isPlay: self.isPlay, fallbackURL: urls.fallback)
            } else if let fallback = urls.fallback {
                self.play(url: fallback, isPlay: self.isPlay, fallbackURL: nil)
            } else {
                print("Error: Invalid media URL for podcast at index \(index)")
                pausePlayer()
            }
        }

        AppPlayer.miniPlayerInfo = BasicDetail(
            songImage: trackItem.imageURL?.absoluteString ?? "",
            songNameTitle: trackItem.trackName ?? "",
            artistSubtitle: trackItem.artistName ?? "",
            musicVC: self
        )
        // FIX: isSetupRemoteTransport guard removed — setupRemoteTransportControls is called once in viewDidLoad
    }

    // MARK: - Navigation
    @objc func backwardBtnPressed() {
        guard let track = track else {
            pausePlayer()
            playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
            return
        }
        if isShuffle {
            if shuffleQueue.isEmpty { resetShuffleQueue() }
            selectedIndex = shuffleQueue.removeFirst()
        } else if selectedIndex > 0 {
            selectedIndex -= 1
        } else {
            pausePlayer()
            playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
            return
        }
        isSetMusic = true
        isPlay = true
        handleRecentInView(index: selectedIndex)
        manageTableViewScroll()
        scrollToCurrentTrack()
    }

    @objc func forwardBtnPressed() {
        guard let track = track else {
            pausePlayer()
            playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
            return
        }
        if isShuffle {
            if shuffleQueue.isEmpty { resetShuffleQueue() }
            selectedIndex = shuffleQueue.removeFirst()
        } else if selectedIndex < track.count - 1 {
            selectedIndex += 1
        } else {
            pausePlayer()
            playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
            return
        }
        isSetMusic = true
        isPlay = true
        handleRecentInView(index: selectedIndex)
        manageTableViewScroll()
        scrollToCurrentTrack()
    }

    private func scrollToCurrentTrack() {
        let indexToScroll = 2 + selectedIndex - (firstTrackList?.count ?? 0)
        let totalRows = radioTableView.numberOfRows(inSection: 0)
        if indexToScroll >= 0 && indexToScroll < totalRows {
            radioTableView.scrollToRow(at: IndexPath(row: indexToScroll, section: 0), at: .middle, animated: true)
        } else {
            radioTableView.scrollToRow(at: IndexPath(row: 1, section: 0), at: .top, animated: true)
        }
    }

    private func setupCircularProgressView() {
        circularProgressView = CircularProgressView(frame: vwProgress.bounds)
        circularProgressView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        circularProgressView.isHidden = true
        vwProgress.addSubview(circularProgressView)
    }

    func shareBtnClicked(url: URL?) {
        guard let url = url else { return }
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        vc.modalPresentationStyle = .popover
        if let wPPC = vc.popoverPresentationController { wPPC.sourceView = self.view }
        self.present(vc, animated: true)
    }

    @IBAction func clickOn_btnBack(_ sender: Any) {
        self.popToBack()
        self.dismiss(animated: true)
    }

    @IBAction func likeBtnPressed(_ sender: Any) {
        isLike = !isLike
        btnLike.setImage(UIImage(named: isLike ? "ic_like_filled" : "ic_like"), for: .normal)
        showToast(message: isLike ? "Added to favorites" : "Removed from favorites", font: .systemFont(ofSize: 12.0))
        configureLike(index: selectedIndex)
    }

    @IBAction func clickOn_btnDownload(_ sender: UIButton) {
        let purchase = IAPHandler.shared.isGetPurchase() || isPurchaseSuccess
        guard let item = track?[safe: selectedIndex], let url = item.file else { return }
        if purchase {
            let name = url.lastPathComponent
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let destinationURL = documentsURL.appendingPathComponent(name)
            btnDownload.isHidden = true
            vwProgress.isHidden = false
            circularProgressView.setProgress(0)
            circularProgressView.isHidden = false
            AF.download(url, to: { _, _ in (destinationURL, [.removePreviousFile, .createIntermediateDirectories]) })
                .downloadProgress { [weak self] progress in
                    guard let self = self else { return }
                    DispatchQueue.main.async { self.circularProgressView.setProgress(Float(progress.fractionCompleted)) }
                    if progress.fractionCompleted == 1.0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.circularProgressView.setProgress(1.0)
                            self.circularProgressView.lineWidth = 8
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                self.vwProgress.isHidden = true
                                self.btnDownload.isHidden = false
                                self.isDownload = true
                                self.circularProgressView.resetProgress()
                                let image = UIImage(systemName: "checkmark.circle.fill")?.withRenderingMode(.alwaysTemplate)
                                self.btnDownload.setImage(image, for: .normal)
                                self.btnDownload.tintColor = .systemGreen
                                self.btnDownload.layer.cornerRadius = 15
                                self.btnDownload.layer.borderColor = UIColor.systemGreen.cgColor
                                self.btnDownload.layer.borderWidth = 2
                                self.btnDownload.clipsToBounds = true
                                self.btnDownload.isUserInteractionEnabled = false
                                self.configureDownload(index: self.selectedIndex)
                            }
                        }
                    }
                }
                .response { response in
                    if let dest = response.fileURL {
                        print("Downloaded to: \(dest)")
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
        guard let trackItem = track?[safe: selectedIndex] else { return }
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "LyricPlayViewController") as! LyricPlayViewController
        vc.currentSong = trackItem.convertToSongModel()
        vc.imageURl = self.imageURl
        vc.lyricnew = self.lyricSynced
        vc.isSyncedLyrics = self.isSyncedLyrics
        self.present(vc, animated: true)
    }

    @objc func moreInfoBtnClicked() {
        guard let trackItem = track?[safe: selectedIndex] else { return }
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PlayListViewController") as! PlayListViewController
        vc.songToSave = trackItem.convertToSongModel()
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }

    @objc func optionMenuBtnClicked() {
        guard let trackItem = track?[safe: selectedIndex] else { return }
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PlayerOptionViewController") as! PlayerOptionViewController
        vc.currentSong = trackItem.convertToSongModel()
        vc.lyricsNew = self.lyricSynced
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }

    @objc func addToCollection() {
        guard let trackItem = track?[safe: selectedIndex] else { return }
        isBookMarked.toggle()
        var savedTracks = UserDefaultsManager.shared.localTracksData
        let songModel = trackItem.convertToSongModel()
        if let i = savedTracks.firstIndex(where: { $0.trackid == songModel.trackid }) {
            savedTracks[i].isBookMarked = isBookMarked
        } else {
            var newItem = songModel
            newItem.isBookMarked = isBookMarked
            savedTracks.append(newItem)
        }
        UserDefaultsManager.shared.localTracksData = savedTracks
        showToast(message: isBookMarked ? "Successfully added to My Collection" : "Removed from My Collection", font: .systemFont(ofSize: 12.0))
        DispatchQueue.main.async {
            self.radioTableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
        }
    }

    // MARK: - Like / Download / Bookmark
    func isAlreadyDownloaded(track: PodcastObject) {
        let songModel = track.convertToSongModel()
        isDownload = UserDefaultsManager.shared.localTracksData.contains { $0.isDownload && $0.trackid == songModel.trackid }
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

    func configureDownload(index: Int) {
        guard let item = track?[safe: index] else { return }
        var savedTracks = UserDefaultsManager.shared.localTracksData
        let songModel = item.convertToSongModel()
        if let i = savedTracks.firstIndex(where: { $0.trackid == songModel.trackid }) {
            savedTracks[i].isDownload = isDownload
        } else {
            var newItem = songModel
            newItem.isDownload = isDownload
            savedTracks.append(newItem)
        }
        UserDefaultsManager.shared.localTracksData = savedTracks
    }

    func isAlreadyLiked(track: PodcastObject) {
        let songModel = track.convertToSongModel()
        isLike = UserDefaultsManager.shared.localTracksData.contains { $0.isFav && $0.trackid == songModel.trackid }
        DispatchQueue.main.async {
            self.btnLike.setImage(UIImage(named: self.isLike ? "ic_like_filled" : "ic_like"), for: .normal)
        }
    }

    func configureLike(index: Int) {
        guard let item = track?[safe: index] else { return }
        var savedTracks = UserDefaultsManager.shared.localTracksData
        let songModel = item.convertToSongModel()
        if let i = savedTracks.firstIndex(where: { $0.trackid == songModel.trackid }) {
            savedTracks[i].isFav = isLike
        } else {
            var newItem = songModel
            newItem.isFav = isLike
            savedTracks.append(newItem)
        }
        UserDefaultsManager.shared.localTracksData = savedTracks
    }

    func isAlreadyBookmarked(track: PodcastObject) {
        let songModel = track.convertToSongModel()
        isBookMarked = UserDefaultsManager.shared.localTracksData.contains { $0.isBookMarked && $0.trackid == songModel.trackid }
    }
}

// MARK: - UITableView
extension MyMusicPlayerViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { return 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let mainCount = 2
        let trackCount = (tempTrack?.count ?? 0) > 1 ? (tempTrack!.count - 1) : 0
        return mainCount + trackCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BannerAdCell", for: indexPath) as! BannerAdCell
            for subview in cell.vwMain.subviews { subview.removeFromSuperview() }
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
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "RecentPlayerOptionCell", for: indexPath) as? RecentPlayerOptionCell else {
                return UITableViewCell()
            }
            cell.btnLyrics.addTarget(self, action: #selector(lyricsBtnClicked), for: .touchUpInside)
            cell.btnMoreInfo.addTarget(self, action: #selector(moreInfoBtnClicked), for: .touchUpInside)
            cell.btnOption.addTarget(self, action: #selector(optionMenuBtnClicked), for: .touchUpInside)
            cell.btnAddtoCollection.addTarget(self, action: #selector(addToCollection), for: .touchUpInside)
            let item = track?[safe: selectedIndex]
            let savedTracks = UserDefaultsManager.shared.localTracksData
            let isBookmarked = savedTracks.contains { $0.isBookMarked && $0.trackid == item?.convertToSongModel().trackid }
            cell.btnAddtoCollection.setImage(UIImage(named: isBookmarked ? "ic_bookmark_fill" : "ic_bookmark"), for: .normal)
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
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
            cell.backgroundColor = .clear
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row > 1 else { return }
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        cell.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
            cell.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
        }) { _ in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                cell.transform = .identity
                cell.isUserInteractionEnabled = true
            }) { _ in
                self.pausePlayer()
                let selectedTrackIndex = (self.firstTrackList?.count ?? 0) + indexPath.row - 1
                guard let track = self.track, selectedTrackIndex < track.count else {
                    print("Invalid selected index: \(selectedTrackIndex)")
                    return
                }
                self.selectedIndex = selectedTrackIndex
                self.isPlay = true
                self.isSetMusic = true
                self.handleRecentInView(index: self.selectedIndex)
                self.manageTableViewScroll()
                self.scrollToCurrentTrack()
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Ads
extension MyMusicPlayerViewController: GADAdLoaderDelegate, GADUnifiedNativeAdLoaderDelegate {
    func loadNativeAd() {
        guard !IAPHandler.shared.isGetPurchase() else { return }
        adLoader = GADAdLoader(adUnitID: GOOGLE_ADMOB_NATIVE, rootViewController: self, adTypes: [.unifiedNative], options: nil)
        adLoader.delegate = self
        adLoader.load(GADRequest())
    }

    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADUnifiedNativeAd) {
        guard !IAPHandler.shared.isGetPurchase() else { return }
        self.nativeAd = nativeAd
        self.manageTableViewScroll()
    }

    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: GADRequestError) {
        print("\(adLoader) failed with error: \(error.localizedDescription)")
    }
}

// MARK: - Playback Core
extension MyMusicPlayerViewController {

    private func playbackURLs(for podcast: PodcastObject?) -> (primary: URL?, fallback: URL?) {
        guard let podcast = podcast, let file = podcast.file else { return (nil, nil) }
        if file.isFileURL { return (nil, file) }
        if file.pathExtension.lowercased() == "m3u8" { return (file, nil) }
        let baseName = (file.lastPathComponent as NSString).deletingPathExtension
        let primaryURL = URL(string: hlsSongPath + baseName + ".m3u8")
        let fallbackURL = sanitizeStreamURL(file.absoluteString) ?? file
        return (primaryURL, fallbackURL)
    }

    // MARK: - Play
    func play(url: URL, isPlay: Bool = false, fallbackURL: URL? = nil) {
        print("▶️ Playing URL: \(url)")
        stopAndClearPlayer()

        let playerItem = AVPlayerItem(url: url)

        if let fallback = fallbackURL {
            playerItemStatusObserver = playerItem.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
                guard let self = self else { return }
                if item.status == .failed && !self.hasTriedFallbackForItem {
                    self.hasTriedFallbackForItem = true
                    print("⚠️ Primary failed, switching to fallback: \(fallback)")
                    DispatchQueue.main.async {
                        let fallbackItem = AVPlayerItem(url: fallback)
                        player?.replaceCurrentItem(with: fallbackItem)
                        self.playerItemStatusObserver = fallbackItem.observe(\.status, options: [.new, .initial]) { [weak self] it, _ in
                            guard let self = self else { return }
                            if it.status == .readyToPlay {
                                DispatchQueue.main.async {
                                    let dur = player?.currentItem?.asset.duration.seconds ?? 0
                                    self.playerSlider.maximumValue = Float(dur)
                                    self.populateLabelWithTime(self.lblEndTime, time: dur)
                                    // FIX: refresh NowPlaying with real duration after fallback
                                    self.setupNowPlaying()
                                }
                            }
                        }
                        player?.play()
                    }
                } else if item.status == .readyToPlay {
                    DispatchQueue.main.async {
                        let dur = item.asset.duration.seconds
                        self.playerSlider.maximumValue = Float(dur)
                        self.populateLabelWithTime(self.lblEndTime, time: dur)
                        self.setupNowPlaying()
                    }
                }
            }
        } else {
            playerItemStatusObserver = playerItem.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
                guard let self = self else { return }
                if item.status == .readyToPlay {
                    DispatchQueue.main.async {
                        let dur = item.asset.duration.seconds
                        self.playerSlider.maximumValue = Float(dur)
                        self.populateLabelWithTime(self.lblEndTime, time: dur)
                        // FIX: update NowPlaying once duration is known
                        self.setupNowPlaying()
                    }
                }
            }
        }

        player = PlayObserver(playerItem: playerItem)
        currentPlayer = player  // FIX: store ref for safe observer removal

        self.playerSlider.minimumValue = 0.0
        self.playerSlider.maximumValue = 0.0
        self.playerSlider.value = 0.0
        populateLabelWithTime(self.lblStartTime, time: 0.0)
        populateLabelWithTime(self.lblEndTime, time: 0.0)
        player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)

        // FIX: register end-of-item observer on the playerItem directly (not player?.currentItem which may be nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.playerDidFinishPlaying(sender:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        if isPlay {
            self.playPauseBtn.setImage(UIImage(named: "ic_pause"), for: .normal)
            self.updateNowPlaying(isPause: false)
            // Lyric sync periodic observer
            player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: .main) { [weak self] time in
                guard let self = self, player?.currentItem?.status == .readyToPlay else { return }
                self.showLyric(toTime: CMTimeGetSeconds(time))
            }
            player?.play()
        } else {
            self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
            self.updateNowPlaying(isPause: true)
            player?.pause()
        }

        self.setupNowPlaying()

        // FIX: time observer on main queue — avoids nested DispatchQueue.main.async
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(value: 1, timescale: 1),
            queue: .main
        ) { [weak self] progressTime in
            guard let self = self else { return }
            self.playerSlider.value = Float(progressTime.seconds)
            self.populateLabelWithTime(self.lblStartTime, time: progressTime.seconds)
            // FIX: keep lock screen elapsed time in sync
            self.updateNowPlayingElapsedTime(progressTime.seconds)
        }
    }

    // MARK: - Player Did Finish — FIXED
    @objc func playerDidFinishPlaying(sender: Notification) {
        print("🏁 Song finished, isRepeat: \(isRepeat), selectedIndex: \(selectedIndex)")

        // FIX: remove observer for this exact item to prevent double fires
        if let item = sender.object as? AVPlayerItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: item)
        }

        // FIX: remove time observer now that playback has ended
        if let obs = timeObserver, let p = currentPlayer {
            p.removeTimeObserver(obs)
            timeObserver = nil
            currentPlayer = nil
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.playerSlider.setValue(0, animated: true)
            self.populateLabelWithTime(self.lblStartTime, time: 0.0)
        }

        if isRepeat {
            player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
            player?.play()
        } else {
            // FIX: small delay so AVPlayer state fully settles before loading next track
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self, let track = self.track, self.selectedIndex < track.count - 1 else {
                    self?.pausePlayer()
                    return
                }
                self.forwardBtnPressed()
            }
        }
    }

    // MARK: - Now Playing — FIXED
    func setupNowPlaying() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            var nowPlayingInfo = [String: Any]()
            nowPlayingInfo[MPMediaItemPropertyArtist] = self.artistName.text ?? ""
            nowPlayingInfo[MPMediaItemPropertyTitle] = self.trackTitle.text ?? ""
            nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = false
            // FIX: Always include playback rate and elapsed time
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player?.isPlaying == true ? 1.0 : 0.0
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.currentTime().seconds ?? 0.0
            // FIX: Include duration so lock screen scrub bar appears
            let duration = player?.currentItem?.asset.duration.seconds ?? 0.0
            if duration > 0 && !duration.isNaN && !duration.isInfinite {
                nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
            }
            if let image = self.artCoverImage.image {
                DispatchQueue.global(qos: .background).async {
                    let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                    DispatchQueue.main.async {
                        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                    }
                }
            } else {
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            }
        }
    }

    // FIX: lightweight elapsed-time update — called every second from time observer
    private func updateNowPlayingElapsedTime(_ elapsed: Double) {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed
        info[MPNowPlayingInfoPropertyPlaybackRate] = player?.isPlaying == true ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func updateNowPlaying(isPause: Bool) {
        guard var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPause ? 0.0 : 1.0
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.currentTime().seconds ?? 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    // MARK: - Remote Transport Controls — FIXED
    func setupRemoteTransportControls() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()

        // FIX: Remove stale targets before re-adding
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)

        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.isEnabled = true

        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self, let p = player, !p.isPlaying else { return .commandFailed }
            p.play()
            DispatchQueue.main.async { self.playPauseBtn.setImage(UIImage(named: "ic_pause"), for: .normal) }
            self.updateNowPlaying(isPause: false)
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self, let p = player, p.isPlaying else { return .commandFailed }
            p.pause()
            DispatchQueue.main.async { self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal) }
            self.updateNowPlaying(isPause: true)
            return .success
        }

        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            DispatchQueue.main.async { self.pausePressed() }
            return .success
        }

        // FIX: nextTrackCommand — safe weak reference, dispatches to main thread
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            DispatchQueue.main.async {
                guard !self.isLastTrack() else { return }
                self.pausePlayer()
                self.forwardBtnPressed()
            }
            return .success
        }

        // FIX: previousTrackCommand — safe weak reference, dispatches to main thread
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            DispatchQueue.main.async {
                self.pausePlayer()
                self.backwardBtnPressed()
            }
            return .success
        }

        // FIX: lock screen / Control Center scrubbing
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let e = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            let target = CMTime(seconds: e.positionTime, preferredTimescale: 1)
            player?.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
            self.updateNowPlayingElapsedTime(e.positionTime)
            return .success
        }
    }

    // MARK: - Playback Controls
    func populateLabelWithTime(_ label: UILabel, time: Double) {
        guard !time.isNaN && !time.isInfinite else {
            label.text = "--:--"
            return
        }
        let minutes = Int(time / 60)
        let seconds = Int(time) % 60
        label.text = String(format: "%02d:%02d", minutes, seconds)
    }

    @IBAction func pausePressed() {
        if player?.isPlaying ?? false {
            player?.pause()
            playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
            updateNowPlaying(isPause: true)
        } else {
            player?.play()
            playPauseBtn.setImage(UIImage(named: "ic_pause"), for: .normal)
            updateNowPlaying(isPause: false)
        }
    }

    @IBAction func repeatBtnPressed(_ sender: Any) {
        isRepeat = !isRepeat
        let image = UIImage(named: "ic_repeat")?.withRenderingMode(.alwaysTemplate)
        self.btnRepeat.setImage(image, for: .normal)
        self.btnRepeat.tintColor = isRepeat ? .red : .white
    }

    func isLastTrack() -> Bool {
        if isShuffle { return shuffleQueue.isEmpty }
        guard let track = track else { return false }
        return selectedIndex == track.count - 1
    }

    @IBAction func backwardBtnEvent(_ sender: Any) {
        self.pausePlayer()
        self.backwardBtnPressed()
    }

    @IBAction func forwardBtnEvent(_ sender: Any) {
        guard !isLastTrack() else { return }
        self.pausePlayer()
        self.forwardBtnPressed()
    }

    @IBAction func progressSliderValueChanged() {
        let seconds: Int64 = Int64(playerSlider.value)
        let targetTime = CMTimeMake(value: seconds, timescale: 1)
        player?.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
        updateNowPlayingElapsedTime(Double(seconds))
    }

    func pausePlayer() {
        stopAndClearPlayer()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.playerSlider.setValue(0, animated: true)
            self.populateLabelWithTime(self.lblStartTime, time: 0.0)
            self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
        }
        player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        updateNowPlaying(isPause: true)
    }
}
