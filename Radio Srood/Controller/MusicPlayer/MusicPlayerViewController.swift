import UIKit
import SWRevealViewController
import Alamofire
import AlamofireImage
import GoogleMobileAds
import StoreKit
import MediaPlayer
import AVKit
import AVPlayerViewControllerSubtitles
import SpotlightLyrics

protocol MusicPlayerViewControllerDelegate: AnyObject {
    func dismissMusicPlayer()
}

struct LyricLine {
    let time: TimeInterval
    let text: String
}

class MusicPlayerViewController: UIViewController, GADBannerViewDelegate, AdsAPIViewDelegate {

    // MARK: - IBOutlets
    @IBOutlet weak var lblLyrics: UILabel!
    @IBOutlet weak var viewLyrics: UIView!
    @IBOutlet weak var heightView: NSLayoutConstraint!
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
    @IBOutlet weak var vwDownloadProgress: UIProgressView!
    @IBOutlet var vwProgress: UIView!

    var circularProgressView: CircularProgressView!

    // MARK: - Public State
    var isPlayingQueueTrack: Bool = false
    var currentQueueIndex: Int? = nil
    var dataHelper: DataHelper!
    var nativeAd: GADUnifiedNativeAd?
    var adLoader: GADAdLoader!
    var isPlay: Bool = false
    var track: [Track]?
    var tempTrack: [Track]?
    var firstTrackList: [Track]?
    var selectedIndex: Int = 0
    var homeHeader: HomeHeader = .hotTrackes
    var groupID: Int?
    var isSetMusic = false
    var isLike = false
    var isDownload = false
    var isRepeat = false
    var bannerAdViews: [GADBannerView] = []
    var imageURl: URL?
    var isMyMusic = false
    var playerListTapCount = 0
    var forwardButtonTapCount = 0
    var isPlayerListTap = false
    var songCounter = 0
    var pendingTrackAfterAd: (index: Int, fromQueue: Bool)?
    var isWaitingForAd = false
    var isSyncedLyrics = false
    var currentQueueTrack: Track? = nil

    // MARK: - Private State
    private var timeObserver: Any?
    private var lyricTimeObserver: Any?
    private var lastIndex: Int? = nil
    private var parser: LyricsParser? = nil
    private var isPurchaseSuccess: Bool = false
    private var currentPlayer: AVPlayer?
    private var playerItemStatusObserver: NSKeyValueObservation?
    private var hasTriedFallbackForItem: Bool = false
    private var parsedLyrics: [LyricLine] = []
    private var lyricSynced: String = ""

    // FIX: Store command tokens so deinit removes ONLY this instance's handlers.
    // Using removeTarget(nil) removes ALL handlers globally — including the NEW
    // VC's handlers — which is why lock screen stopped working on category change.
    private var playCommandToken: Any?
    private var pauseCommandToken: Any?
    private var nextCommandToken: Any?
    private var prevCommandToken: Any?
    private var toggleCommandToken: Any?
    private var scrubCommandToken: Any?

    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()

        let yourBackImage = UIImage(named: "left-arrow")
        navigationController?.navigationBar.backIndicatorImage = yourBackImage
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = yourBackImage
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.topItem?.title = ""
        navigationController?.navigationBar.backItem?.title = ""
        navigationItem.backBarButtonItem = UIBarButtonItem(
            title: "", style: .plain, target: nil, action: nil)

        radioTableView.tableHeaderView = UIView(
            frame: CGRect(x: 0, y: 0, width: screenSize.width, height: 0.1))
        radioTableView.tableFooterView = UIView()

        loadNativeAd()

        // STEP 1: Audio session FIRST
        activateAudioSession()

        // STEP 2: Remote controls — ONCE only, tokens stored in ivars
        setupRemoteTransportControls()

        // STEP 3: Load content
        prepareView()

        vwDownloadProgress.isHidden = true
        vwDownloadProgress.setProgress(0.0, animated: false)

        NotificationCenter.default.addObserver(self,
            selector: #selector(didBecomeActiveNotificationReceived),
            name: NSNotification.Name("UIApplicationDidBecomeActiveNotification"), object: nil)
        NotificationCenter.default.addObserver(self,
            selector: #selector(playerInterruption(notification:)),
            name: NSNotification.Name("AVAudioSessionInterruptionNotification"), object: nil)
        NotificationCenter.default.addObserver(self,
            selector: #selector(audioChanged), name: .musicDidPlay, object: nil)
        NotificationCenter.default.addObserver(self,
            selector: #selector(audioChanged), name: .musicDidPause, object: nil)
        NotificationCenter.default.addObserver(self,
            selector: #selector(handleIAPPurchase), name: .PurchaseSuccess, object: nil)
        NotificationCenter.default.addObserver(self,
            selector: #selector(handleIAPPurchase1), name: .aaaaaaaaaa, object: nil)

        radioTableView.register(
            UINib(nibName: "BannerAdCell", bundle: nil), forCellReuseIdentifier: "BannerAdCell")
        radioTableView.register(
            UINib(nibName: "HeaderCell", bundle: nil), forCellReuseIdentifier: "HeaderCell")
        radioTableView.translatesAutoresizingMaskIntoConstraints = false
        radioTableView.isScrollEnabled = false
        radioTableView.rowHeight = UITableView.automaticDimension
        radioTableView.estimatedRowHeight = 90
        setupCircularProgressView()

        let longPress = UILongPressGestureRecognizer(
            target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.4
        radioTableView.addGestureRecognizer(longPress)
    }

    // MARK: - Audio Session
    private func activateAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            UIApplication.shared.beginReceivingRemoteControlEvents()
            print("✅ AVAudioSession activated")
        } catch {
            print("❌ AVAudioSession error: \(error)")
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let point = gesture.location(in: radioTableView)
        guard let indexPath = radioTableView.indexPathForRow(at: point) else { return }

        let queueCount = PlaybackQueueManager.shared.getQueue().count
        let queueRows  = queueCount > 0 ? queueCount + 1 : 0
        var selectedTrack: Track?

        if indexPath.row >= 2 && indexPath.row < 2 + queueRows && indexPath.row != 2 {
            selectedTrack = PlaybackQueueManager.shared.getQueue()[safe: indexPath.row - 3]
        } else if indexPath.row >= 2 + queueRows {
            let trackIndex = (indexPath.row - queueRows) - 3 + 1
            selectedTrack = tempTrack?[safe: trackIndex]
        }
        if let t = selectedTrack { presentOptionsViewController(for: t) }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        radioTableView.reloadData()
        manageTableViewScroll()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            self.navigationController?.navigationBar.shadowImage = UIImage()
            self.navigationController?.navigationBar.isTranslucent = true
        }
        TabbarVC.available?.miniPlayer.miniplayer(hide: true)
        navigationItem.hidesBackButton = true
        navigationController?.setNavigationBarHidden(true, animated: animated)
        activateAudioSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        self.popToBack()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        TabbarVC.available?.miniPlayer.miniplayer(hide: false)
        self.dismiss(animated: true)
        if let vc = TabbarVC.available?.selectedViewController as? MusicPlayerViewControllerDelegate {
            vc.dismissMusicPlayer()
        }
    }

    // MARK: - deinit
    // FIX: Remove ONLY this instance's tokens. NEVER removeTarget(nil).
    // removeTarget(nil) is a global wipe — it destroys the new VC's handlers too,
    // which is exactly why lock screen / CC stopped responding after category change.
    deinit {
        UIApplication.shared.endReceivingRemoteControlEvents()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [:]

        let cmd = MPRemoteCommandCenter.shared()
        if let t = playCommandToken   { cmd.playCommand.removeTarget(t) }
        if let t = pauseCommandToken  { cmd.pauseCommand.removeTarget(t) }
        if let t = nextCommandToken   { cmd.nextTrackCommand.removeTarget(t) }
        if let t = prevCommandToken   { cmd.previousTrackCommand.removeTarget(t) }
        if let t = toggleCommandToken { cmd.togglePlayPauseCommand.removeTarget(t) }
        if let t = scrubCommandToken  { cmd.changePlaybackPositionCommand.removeTarget(t) }

        NotificationCenter.default.removeObserver(self)
        removeTimeObserverIfNeeded()
        print("MusicPlayerViewController deinit")
    }

    // MARK: - Remove Time Observers
    // FIX: Capture currentPlayer into ONE local constant before any nilling.
    // Old code used currentPlayer in two sequential if-let blocks — after the first
    // block ran, currentPlayer became nil so lyricTimeObserver was NEVER removed,
    // leaving a dangling periodic observer that interfered with NowPlaying updates.
    private func removeTimeObserverIfNeeded() {
        guard let p = currentPlayer else {
            timeObserver = nil
            lyricTimeObserver = nil
            return
        }
        if let obs = timeObserver      { p.removeTimeObserver(obs); timeObserver = nil }
        if let obs = lyricTimeObserver { p.removeTimeObserver(obs); lyricTimeObserver = nil }
        currentPlayer = nil
    }

    private func setupCircularProgressView() {
        circularProgressView = CircularProgressView(frame: vwProgress.bounds)
        circularProgressView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        circularProgressView.isHidden = true
        vwProgress.addSubview(circularProgressView)
    }

    func manageTableViewScroll() {
        DispatchQueue.main.async {
            self.radioTableView.reloadData()
            self.radioTableView.layoutIfNeeded()
            let trackCount = self.tempTrack?.count ?? 0
            let queueCount = PlaybackQueueManager.shared.getQueue().count
            let queueRows  = queueCount > 0 ? queueCount + 1 : 0
            var h: CGFloat = 0
            h += IAPHandler.shared.isGetPurchase() ? 0 : 65
            h += 90
            h += queueRows > 0 ? CGFloat(queueRows * 90) : 0
            h += trackCount > 0 ? 40 : 0
            h += CGFloat(trackCount * 90) + 90
            self.tableBgHeightConstraints.constant = h
        }
    }

    // MARK: - prepareView
    // FIX: Reset flags on every category open so the first track always plays.
    func prepareView() {
        isSetMusic = true
        isPlay     = true
        switch homeHeader {
        case .featured:       loadFeaturedDataItems()
        case .hotTrackes:     loadNewReleaseData()
        case .currentRadio:   break
        case .trending:       loadTrendingPlaylistData()
        case .popularTracks:  loadPopularPlaylistData()
        case .playlists:      loadPlaylistData()
        case .featuredArtist: loadFeaturedArtistData()
        case .myPlaylist:     break
        case .recentlyPlayed: break
        case .todayTopPic:    loadTodayTopPicData()
        case .recentlyAdded:  loadRecentlyAddedDetailedData()
        }
    }

    @objc func didBecomeActiveNotificationReceived() {
        activateAudioSession()
        updateNowPlaying(isPause: !(player?.isPlaying ?? false))
    }

    @objc func playerInterruption(notification: NSNotification) {
        guard let ui = notification.userInfo,
              let tv = ui[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: tv) else { return }
        if type == .began {
            player?.pause()
            updateNowPlaying(isPause: true)
        } else if type == .ended {
            guard let ov = ui[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            if AVAudioSession.InterruptionOptions(rawValue: ov).contains(.shouldResume) {
                // ✅ FIX: Only resume if this VC's player is the one that was playing
                // If player is nil or already playing, skip — another player owns audio
                guard let p = player, !p.isPlaying else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    guard let self = self else { return }
                    self.activateAudioSession()
                    p.play()
                    self.setupNowPlaying()
                    self.updateNowPlaying(isPause: false)
                }
            }
        }
    }

    // MARK: - Data Loading
    private func loadNewReleaseData() {
        dataHelper = DataHelper()
        dataHelper.getNewReleaseData { [weak self] resp in
            guard let self = self, let resp = resp else { return }
            self.track     = resp.newRelease.first(where: { $0.id == self.groupID })?.tracks
            self.tempTrack = self.track
            self.isSetMusic = true; self.isPlay = true
            self.handleRecentInView(index: self.selectedIndex)
            self.manageTableViewScroll()
        }
    }

    private func loadTodayTopPicData() {
        dataHelper = DataHelper()
        dataHelper.getTodayTopPicDetailed { [weak self] resp in
            guard let self = self, let resp = resp else { return }
            self.track     = resp.todayTopPick.first(where: { $0.playlistID == self.groupID })?.tracks
            self.tempTrack = self.track
            self.isSetMusic = true; self.isPlay = true
            self.handleRecentInView(index: self.selectedIndex)
            self.manageTableViewScroll()
        }
    }

    func loadRecentlyAddedDetailedData() {
        dataHelper = DataHelper()
        dataHelper.getRecentlyAddedDataDetailed { [weak self] resp in
            guard let self = self, let resp = resp else { return }
            self.track     = resp.recentlyAddedPlayListDetailed
                .first(where: { $0.playlistID == self.groupID })?.tracks
            self.tempTrack = self.track
            self.isSetMusic = true; self.isPlay = true
            self.handleRecentInView(index: self.selectedIndex)
            self.manageTableViewScroll()
        }
    }

    private func loadFeaturedDataItems() {
        dataHelper = DataHelper()
        dataHelper.getFeaturedArtistSponserdDetailsData { [weak self] resp in
            guard let self = self, let resp = resp else { return }
            self.track     = resp.featuredData.first(where: { $0.fDid == self.groupID })?.featuredItem
            self.tempTrack = self.track
            self.isSetMusic = true; self.isPlay = true
            self.handleRecentInView(index: self.selectedIndex)
            self.manageTableViewScroll()
        }
    }

    private func loadTrendingPlaylistData() {
        dataHelper = DataHelper()
        dataHelper.getTrendingPlaylistData { [weak self] resp in
            guard let self = self, let resp = resp else { return }
            self.track     = resp.trendingTracks.first(where: { $0.id == self.groupID })?.tracks
            self.tempTrack = self.track
            self.isSetMusic = true; self.isPlay = true
            self.handleRecentInView(index: self.selectedIndex)
            self.manageTableViewScroll()
        }
    }

    private func loadPopularPlaylistData() {
        dataHelper = DataHelper()
        dataHelper.getPopularPlaylistData { [weak self] resp in
            guard let self = self, let resp = resp else { return }
            self.track     = resp.popularTracks.first(where: { $0.id == self.groupID })?.tracks
            self.tempTrack = self.track
            self.isSetMusic = true; self.isPlay = true
            self.handleRecentInView(index: self.selectedIndex)
            self.manageTableViewScroll()
        }
    }

    private func loadPlaylistData() {
        dataHelper = DataHelper()
        dataHelper.getPlaylistData { [weak self] resp in
            guard let self = self, let resp = resp else { return }
            self.track     = resp.trendingPlaylist.first(where: { $0.id == self.groupID })?.tracks
            self.tempTrack = self.track
            self.isSetMusic = true; self.isPlay = true
            self.handleRecentInView(index: self.selectedIndex)
            self.manageTableViewScroll()
        }
    }

    private func loadFeaturedArtistData() {
        dataHelper = DataHelper()
        dataHelper.getFeaturedArtistData { [weak self] resp in
            guard let self = self, let resp = resp else { return }
            self.track     = resp.rSroodFeaturedArtistData.first(where: { $0.id == self.groupID })?.tracks
            self.tempTrack = self.track
            self.isSetMusic = true; self.isPlay = true
            self.handleRecentInView(index: self.selectedIndex)
            self.manageTableViewScroll()
        }
    }

    // MARK: - Lyrics
    private func parseLyricSynced() {
        parsedLyrics.removeAll()
        let lines = lyricSynced.components(separatedBy: .newlines)
        let regex = try? NSRegularExpression(pattern: #"\[(\d{2}):(\d{2})\.(\d{2})\](.*)"#)
        for line in lines {
            guard let m = regex?.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                  m.numberOfRanges == 5,
                  let r1 = Range(m.range(at: 1), in: line),
                  let r2 = Range(m.range(at: 2), in: line),
                  let r3 = Range(m.range(at: 3), in: line),
                  let r4 = Range(m.range(at: 4), in: line)
            else { continue }
            let t = (Double(line[r1]) ?? 0) * 60 + (Double(line[r2]) ?? 0) + (Double(line[r3]) ?? 0) / 100
            parsedLyrics.append(LyricLine(time: t,
                text: String(line[r4]).trimmingCharacters(in: .whitespacesAndNewlines)))
        }
    }

    // MARK: - handleRecentInView
    func handleRecentInView(index: Int, isQueueTrack: Bool = false) {
        artCoverImage.layer.cornerRadius  = 3
        artCoverImage.layer.masksToBounds = true

        let item = isQueueTrack ? currentQueueTrack : track?[safe: index]
        guard let item = item else {
            print("Error: No track at index \(index), queue=\(isQueueTrack)")
            return
        }

        if let url = URL(string: item.artcover ?? "") {
            artCoverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            bgImageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "b1.png"))
            imageURl = url
        }
        trackTitle.text = item.track
        artistName.text = item.artist
        isAlreadyLiked(track: item)
        isAlreadyDownloaded(track: item)
        isQueueTrack ? configureRecentlyPlayed() : configureRecentlyPlayed(index: index)
        lastIndex = nil

        // ✅ FIX: Clear lyrics immediately before async fetch
        lblLyrics.text = ""
        lyricSynced = ""
        parsedLyrics.removeAll()
        isSyncedLyrics = false
        hideLyrics()

        DataHelper.getLyricsData(artist: item.artist ?? "", track: item.track ?? "") {
            [weak self] lyricItem in
            guard let self = self else { return }
            guard let lyricItem = lyricItem else {
                DispatchQueue.main.async { self.hideLyrics() }
                return
            }
            let synced = lyricItem.syncedLyrics.trimmingCharacters(in: .whitespacesAndNewlines)
            let plain  = lyricItem.plainLyrics.trimmingCharacters(in: .whitespacesAndNewlines)
            DispatchQueue.main.async {
                if !synced.isEmpty {
                    self.lyricSynced = synced
                    self.parseLyricSynced()
                    self.showLyrics()
                    self.lblLyrics.text = ""
                    self.isSyncedLyrics = true
                } else if !plain.isEmpty {
                    self.lyricSynced = plain
                    self.parser = nil
                    self.hideLyrics()
                    self.isSyncedLyrics = false
                } else {
                    self.hideLyrics()
                }
            }
        }

        let urls = playbackURLs(for: item)
        if let primary = urls.primary {
            if isSetMusic {
                isSetMusic = false
                play(url: primary, isPlay: self.isPlay, fallbackURL: urls.fallback)
            }
        } else if let fallback = urls.fallback {
            if isSetMusic {
                isSetMusic = false
                play(url: fallback, isPlay: self.isPlay, fallbackURL: nil)
            }
        } else {
            print("Error: No URL for \(item.track ?? "?")")
            pausePlayer()
        }

        AppPlayer.miniPlayerInfo = BasicDetail(
            songImage: item.artcover ?? "",
            songNameTitle: item.track ?? "",
            artistSubtitle: item.artist ?? "",
            musicVC: self)
    }

    private func playbackURLs(for track: Track) -> (primary: URL?, fallback: URL?) {
        var primary: URL?
        var fallback: URL?
        if let hls = track.hlsMediaPath?.trimmingCharacters(in: .whitespacesAndNewlines), !hls.isEmpty {
            primary = URL(string: hls).flatMap { $0.scheme != nil ? $0 : nil }
                ?? hls.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                    .flatMap { URL(string: hlsSongPath + $0) }
        }
        if let media = track.mediaPath?.trimmingCharacters(in: .whitespacesAndNewlines), !media.isEmpty {
            fallback = URL(string: media).flatMap { $0.scheme != nil ? $0 : nil }
                ?? media.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                    .flatMap { URL(string: songPath + $0) }
        }
        return (primary, fallback)
    }

    private func showLyrics() { heightView.constant = 40; viewLyrics.isHidden = false }
    private func hideLyrics()  {
        heightView.constant = 0; viewLyrics.isHidden = true; parser = nil; lblLyrics.text = ""
    }

    func showLyric(toTime time: TimeInterval) {
        guard !parsedLyrics.isEmpty,
              let idx = parsedLyrics.firstIndex(where: { $0.time >= time }),
              idx > 0,
              lastIndex != idx - 1 else { return }
        lblLyrics.text = parsedLyrics[idx - 1].text
        lastIndex = idx - 1
    }

    @objc func lyricsBtnClicked() {
        let item: Track? = isPlayingQueueTrack ? currentQueueTrack : track?[safe: selectedIndex]
        guard let trackItem = item else { return }
        let vc = storyboard?.instantiateViewController(
            withIdentifier: "LyricPlayViewController") as! LyricPlayViewController
        vc.currentSong    = trackItem.convertToSongModel()
        vc.imageURl       = imageURl
        vc.lyricnew       = lyricSynced
        vc.isSyncedLyrics = isSyncedLyrics
        present(vc, animated: true)
    }

    @objc func optionMenuBtnClicked() {
        let item: Track? = isPlayingQueueTrack ? currentQueueTrack : track?[safe: selectedIndex]
        guard let trackItem = item else { return }
        let vc = storyboard?.instantiateViewController(
            withIdentifier: "PlayerOptionViewController") as! PlayerOptionViewController
        vc.currentSong = trackItem.convertToSongModel()
        vc.track       = trackItem
        vc.lyricsNew   = lyricSynced
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }

    @objc func moreInfoBtnClicked() {
        let item: Track? = isPlayingQueueTrack ? currentQueueTrack : track?[safe: selectedIndex]
        guard let trackItem = item else { return }
        let vc = storyboard?.instantiateViewController(
            withIdentifier: "PlayListViewController") as! PlayListViewController
        vc.songToSave = trackItem.convertToSongModel()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }

    @objc func addToCollection() {
        isMyMusic = !isMyMusic
        let item: Track? = isPlayingQueueTrack ? currentQueueTrack : track?[safe: selectedIndex]
        guard let trackItem = item?.convertToSongModel() else { return }
        var saved = UserDefaultsManager.shared.localTracksData
        if let i = saved.firstIndex(where: { $0.trackid == trackItem.trackid }) {
            saved[i].isBookMarked = !saved[i].isBookMarked
            showToast(message: saved[i].isBookMarked
                ? "Successfully add in My Collection" : "Remove from my collection",
                font: .systemFont(ofSize: 12))
        } else {
            var n = trackItem; n.isBookMarked = true; saved.append(n)
            showToast(message: "Successfully add in My Collection", font: .systemFont(ofSize: 12))
        }
        UserDefaultsManager.shared.localTracksData = saved
        radioTableView.reloadData()
    }

    // MARK: - backward / forward
    @objc func backwardBtnPressed() {
        if isPlayingQueueTrack {
            if let qi = currentQueueIndex, qi > 0 {
                playTrackAtIndex(qi - 1, fromQueue: true)
            } else if let t = track, selectedIndex > 0 {
                isPlayingQueueTrack = false; currentQueueIndex = nil
                playTrackAtIndex(selectedIndex - 1, fromQueue: false)
            } else { pausePlayer() }
        } else if let t = track, selectedIndex > 0 {
            playTrackAtIndex(selectedIndex - 1, fromQueue: false)
        } else { pausePlayer() }
    }

    @objc func forwardBtnPressed() {
        forwardButtonTapCount += 1
        let queue = PlaybackQueueManager.shared.getQueue()
        let next: (index: Int, fromQueue: Bool)?
        if !queue.isEmpty                                   { next = (0, true) }
        else if let t = track, selectedIndex < t.count - 1 { next = (selectedIndex + 1, false) }
        else                                                { next = nil }

        if shouldPlayAdForwardBtnPressed() && !IAPHandler.shared.isGetPurchase() {
            player?.pause()
            pendingTrackAfterAd = next
            isWaitingForAd = true
            let vc = storyboard?.instantiateViewController(withIdentifier: "AdsAPIView") as! AdsAPIView
            vc.delegate = self; vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
            forwardButtonTapCount = 0
        } else {
            if let n = next { playTrackAtIndex(n.index, fromQueue: n.fromQueue) }
            else { pausePlayer() }
        }
    }

    private func shouldPlayAdForwardBtnPressed() -> Bool { forwardButtonTapCount >= 6 }

    func adsPlaybackDidFinish() {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.isWaitingForAd = false
            if let p = self.pendingTrackAfterAd {
                self.playTrackAtIndex(p.index, fromQueue: p.fromQueue)
                self.pendingTrackAfterAd = nil
            } else {
                let q = PlaybackQueueManager.shared.getQueue()
                if !q.isEmpty                                        { self.playTrackAtIndex(0, fromQueue: true) }
                else if let t = self.track, self.selectedIndex < t.count { self.playTrackAtIndex(self.selectedIndex, fromQueue: false) }
                else                                                 { self.pausePlayer() }
            }
        }
    }

    func shareBtnClicked(url: URL) {
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: [])
        vc.modalPresentationStyle = .popover
        vc.popoverPresentationController?.sourceView = view
        present(vc, animated: true)
    }

    @IBAction func actionLyrics(_ sender: Any) { lyricsBtnClicked() }

    @IBAction func actionClose(_ sender: Any) {
        dismiss(animated: true)
        navigationController?.popViewController(animated: true)
    }

    @objc private func handleIAPPurchase() {
        isPurchaseSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { self.isPurchaseSuccess = false }
    }
    @objc private func handleIAPPurchase1() {}

    @IBAction func clickOn_btnDownload(_ sender: Any) {
        guard IAPHandler.shared.isGetPurchase() || isPurchaseSuccess else {
            let vc = storyboard?.instantiateViewController(withIdentifier: "IAPVC") as! IAPVC
            vc.isshowbackButton = true
            let nav = UINavigationController(rootViewController: vc)
            nav.navigationBar.isHidden = true; nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true); return
        }
        let item: Track? = isPlayingQueueTrack ? currentQueueTrack : track?[safe: selectedIndex]
        guard let trackItem = item,
              let enc = trackItem.mediaPath?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: songPath + enc) else { return }
        let dest = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(url.lastPathComponent)
        btnDownload.isHidden = true; vwProgress.isHidden = false
        circularProgressView.setProgress(0); circularProgressView.isHidden = false
        AF.download(url, to: { _, _ in (dest, [.removePreviousFile, .createIntermediateDirectories]) })
            .downloadProgress { [weak self] p in
                guard let self = self else { return }
                DispatchQueue.main.async { self.circularProgressView.setProgress(Float(p.fractionCompleted)) }
                if p.fractionCompleted == 1.0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.circularProgressView.setProgress(1.0); self.circularProgressView.lineWidth = 2
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.vwProgress.isHidden = true; self.btnDownload.isHidden = false
                            self.isDownload = true; self.circularProgressView.resetProgress()
                            let img = UIImage(systemName: "checkmark.circle.fill")?.withRenderingMode(.alwaysTemplate)
                            self.btnDownload.setImage(img, for: .normal)
                            self.btnDownload.tintColor = .systemGreen
                            self.btnDownload.layer.cornerRadius = 15
                            self.btnDownload.layer.borderColor = UIColor.systemGreen.cgColor
                            self.btnDownload.layer.borderWidth = 2
                            self.btnDownload.clipsToBounds = true
                            self.btnDownload.isUserInteractionEnabled = false
                            self.isPlayingQueueTrack ? self.configureDownload() : self.configureDownload(index: self.selectedIndex)
                        }
                    }
                }
            }
            .response { r in if let f = r.fileURL { print("Downloaded: \(f)") } }
        UserDefaults.standard.set(trackItem.artcover, forKey: "\(url.deletingPathExtension().lastPathComponent)")
    }

    private func setHeaderData(headerTitle: String) -> UIView {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: 30))
        let l = UILabel(frame: CGRect(x: 15, y: 5, width: screenSize.width - 30, height: 20))
        l.text = headerTitle; l.textColor = .white.withAlphaComponent(1.1)
        l.font = UIFont(name: "Avenir Next Ultra Light", size: 19)
        v.addSubview(l); return v
    }
}

// MARK: - UITableView
extension MusicPlayerViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let mainCount  = 2
        let trackCount = (tempTrack?.count ?? 0) > 0 ? tempTrack!.count - 1 : 0
        let queueCount = PlaybackQueueManager.shared.getQueue().count
        let queueRows  = queueCount > 0 ? queueCount + 1 : 0
        return mainCount + queueRows + (trackCount > 0 ? 1 : 0) + trackCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let queueCount = PlaybackQueueManager.shared.getQueue().count
        let queueRows  = queueCount > 0 ? queueCount + 1 : 0

        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "BannerAdCell", for: indexPath) as! BannerAdCell
            for sub in cell.vwMain.subviews { sub.removeFromSuperview() }
            if IAPHandler.shared.isGetPurchase() {
                cell.vwMain.isHidden = true; cell.heightOfVw.constant = 0
            } else {
                cell.vwMain.isHidden = false; cell.heightOfVw.constant = 65
                let banner = GADBannerView(adSize: kGADAdSizeBanner)
                banner.adUnitID = GOOGLE_ADMOB_ForMusicPlayer
                banner.rootViewController = self; banner.delegate = self
                banner.load(GADRequest()); banner.frame = cell.vwMain.bounds
                cell.vwMain.addSubview(banner)
            }
            cell.selectionStyle = .none; cell.backgroundColor = .clear; return cell

        } else if indexPath.row == 1 {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: "RecentPlayerOptionCell", for: indexPath) as? RecentPlayerOptionCell
            else { return UITableViewCell() }
            cell.selectionStyle = .none
            cell.btnLyrics.addTarget(self, action: #selector(lyricsBtnClicked), for: .touchUpInside)
            cell.btnMoreInfo.addTarget(self, action: #selector(moreInfoBtnClicked), for: .touchUpInside)
            cell.btnOption.addTarget(self, action: #selector(optionMenuBtnClicked), for: .touchUpInside)
            cell.btnAddtoCollection.addTarget(self, action: #selector(addToCollection), for: .touchUpInside)
            let item: Track? = isPlayingQueueTrack ? currentQueueTrack : track?[safe: selectedIndex]
            let saved = UserDefaultsManager.shared.localTracksData
            let ti = saved.firstIndex(where: { $0.trackid == item?.convertToSongModel().trackid })
            let bm = ti.flatMap { saved[safe: $0]?.isBookMarked } ?? false
            cell.btnAddtoCollection.setImage(UIImage(named: bm ? "ic_bookmark_fill" : "ic_bookmark"), for: .normal)
            return cell

        } else if indexPath.row == 2 && queueRows > 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell", for: indexPath) as! HeaderCell
            cell.headerLabel.text = "Up Next from Queue"
            cell.selectionStyle = .none; cell.backgroundColor = .clear
            cell.contentView.isUserInteractionEnabled = false; return cell

        } else if indexPath.row >= 2 && indexPath.row < 2 + queueRows {
            let qi = indexPath.row - 3
            let queue = PlaybackQueueManager.shared.getQueue()
            if qi >= 0 && qi < queue.count {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RecentListCell", for: indexPath) as! RecentListCell
                cell.selectionStyle = .none
                cell.artCoverImage.layer.cornerRadius = 3; cell.artCoverImage.layer.masksToBounds = true
                let item = queue[qi]
                cell.trackTitle.text = item.track; cell.artistName.text = item.artist
                if let url = URL(string: (item.artcover ?? "") + "?s=200") {
                    cell.artCoverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                    cell.imgBg.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                }
                return cell
            }
            return UITableViewCell()

        } else {
            let adj = indexPath.row - queueRows
            if adj == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell", for: indexPath) as! HeaderCell
                cell.headerLabel.text = "Up Next"
                cell.selectionStyle = .none; cell.backgroundColor = .clear
                cell.contentView.isUserInteractionEnabled = false; return cell
            } else {
                let ti = adj - 3 + 1
                if ti >= 1, ti < (tempTrack?.count ?? 0) {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "RecentListCell", for: indexPath) as! RecentListCell
                    cell.selectionStyle = .none
                    cell.artCoverImage.layer.cornerRadius = 3; cell.artCoverImage.layer.masksToBounds = true
                    if let item = tempTrack?[ti] {
                        cell.trackTitle.text = item.track; cell.artistName.text = item.artist
                        if let url = URL(string: (item.artcover ?? "") + "?s=200") {
                            cell.artCoverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                            cell.imgBg.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                        }
                    }
                    return cell
                }
                return UITableViewCell()
            }
        }
    }

    private func presentOptionsViewController(for track: Track) {
        guard let vc = storyboard?.instantiateViewController(
            withIdentifier: "OptionsViewController") as? OptionsViewController else { return }
        vc.track = track; vc.delegate = self; vc.modalPresentationStyle = .overFullScreen
        present(vc, animated: true)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let queueCount = PlaybackQueueManager.shared.getQueue().count
        let queueRows  = queueCount > 0 ? queueCount + 1 : 0

        if indexPath.row >= 2 && indexPath.row < 2 + queueRows && indexPath.row != 2 {
            let qi = indexPath.row - 3
            if qi >= 0 && qi < PlaybackQueueManager.shared.getQueue().count {
                isPlayerListTap = false; playTrackAtIndex(qi, fromQueue: true)
                DispatchQueue.main.async { self.radioTableView.reloadData(); self.manageTableViewScroll() }
            }
        } else if indexPath.row >= 2 + queueRows {
            let ti = (indexPath.row - queueRows) - 3 + 1
            if ti >= 1, ti < (tempTrack?.count ?? 0) {
                isPlayerListTap = true; playTrackAtIndex(ti, fromQueue: false)
                playerListTapCount += 1
                if shouldPlayerListPressed() && !IAPHandler.shared.isGetPurchase() {
                    isPlayerListTap = true; playerListTapCount = 0; player?.pause()
                    pendingTrackAfterAd = (ti, false); isWaitingForAd = true
                    let vc = storyboard?.instantiateViewController(withIdentifier: "AdsAPIView") as! AdsAPIView
                    vc.delegate = self; vc.modalPresentationStyle = .fullScreen; present(vc, animated: true)
                }
                DispatchQueue.main.async { self.radioTableView.reloadData(); self.manageTableViewScroll() }
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Ads
extension MusicPlayerViewController: GADAdLoaderDelegate, GADUnifiedNativeAdLoaderDelegate {
    func loadNativeAd() {
        guard !IAPHandler.shared.isGetPurchase() else { return }
        adLoader = GADAdLoader(adUnitID: GOOGLE_ADMOB_NATIVE, rootViewController: self,
                               adTypes: [.unifiedNative], options: nil)
        adLoader.delegate = self; adLoader.load(GADRequest())
    }
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADUnifiedNativeAd) {
        guard !IAPHandler.shared.isGetPurchase() else { return }
        self.nativeAd = nativeAd; manageTableViewScroll()
    }
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: GADRequestError) {
        print("\(adLoader) failed: \(error.localizedDescription)")
    }
}

// MARK: - Playback Core
extension MusicPlayerViewController {

    // MARK: playTrackAtIndex
    private func playTrackAtIndex(_ index: Int, fromQueue: Bool = false) {
        let queue = PlaybackQueueManager.shared.getQueue()
        let list: [Track]? = fromQueue ? queue : self.track
        guard let list = list, index >= 0, index < list.count else {
            print("Error: invalid index \(index)"); pausePlayer(); return
        }
        let item = list[index]
        let urls = playbackURLs(for: item)
        guard let primary = urls.primary ?? urls.fallback else {
            print("Error: no URL for \(item.track ?? "?")"); pausePlayer(); return
        }

        if !fromQueue {
            selectedIndex = index; isPlayingQueueTrack = false
            currentQueueIndex = nil; currentQueueTrack = nil
        } else {
            isPlayingQueueTrack = true; currentQueueIndex = index; currentQueueTrack = item
        }

        stopAndClearPlayer()
        isSetMusic = true; isPlay = true

        play(url: primary, isPlay: true, fallbackURL: urls.primary == nil ? nil : urls.fallback)
        handleRecentInView(index: index, isQueueTrack: fromQueue)

        if fromQueue {
            PlaybackQueueManager.shared.removeFromQueue(at: index)
            currentQueueIndex = PlaybackQueueManager.shared.getQueue().isEmpty ? nil : index
            DispatchQueue.main.async { self.radioTableView.reloadData(); self.manageTableViewScroll() }
        }
    }

    // MARK: stopAndClearPlayer
    private func stopAndClearPlayer() {
        playerItemStatusObserver = nil
        let p = currentPlayer                                    // capture ONCE
        if let obs = timeObserver,      let p = p { p.removeTimeObserver(obs) }
        timeObserver = nil
        if let obs = lyricTimeObserver, let p = p { p.removeTimeObserver(obs) }
        lyricTimeObserver = nil
        if let pl = player {
            NotificationCenter.default.removeObserver(self,
                name: .AVPlayerItemDidPlayToEndTime, object: pl.currentItem)
            pl.pause()
        }
        currentPlayer = nil; hasTriedFallbackForItem = false
    }

    // MARK: play
    func play(url: URL, isPlay: Bool = false, fallbackURL: URL? = nil) {
        print("▶️ \(url)")
        stopAndClearPlayer()
        activateAudioSession()                                   // CRITICAL before player creation

        let playerItem = AVPlayerItem(url: url)

        if let fallback = fallbackURL {
            playerItemStatusObserver = playerItem.observe(\.status, options: [.new, .initial]) {
                [weak self] item, _ in
                guard let self = self else { return }
                if item.status == .failed && !self.hasTriedFallbackForItem {
                    self.hasTriedFallbackForItem = true
                    print("⚠️ Primary failed → fallback")
                    DispatchQueue.main.async {
                        let fi = AVPlayerItem(url: fallback)
                        player?.replaceCurrentItem(with: fi)
                        self.playerItemStatusObserver = fi.observe(\.status, options: [.new, .initial]) {
                            [weak self] it, _ in
                            guard let self = self else { return }
                            if it.status == .readyToPlay {
                                DispatchQueue.main.async {
                                    let dur = player?.currentItem?.asset.duration.seconds ?? 0
                                    self.playerSlider.maximumValue = Float(dur)
                                    self.populateLabelWithTime(self.lblEndTime, time: dur)
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
            playerItemStatusObserver = playerItem.observe(\.status, options: [.new, .initial]) {
                [weak self] item, _ in
                guard let self = self else { return }
                if item.status == .readyToPlay {
                    DispatchQueue.main.async {
                        let dur = item.asset.duration.seconds
                        self.playerSlider.maximumValue = Float(dur)
                        self.populateLabelWithTime(self.lblEndTime, time: dur)
                        self.setupNowPlaying()
                    }
                }
            }
        }

        player        = PlayObserver(playerItem: playerItem)
        currentPlayer = player

        playerSlider.minimumValue = 0; playerSlider.maximumValue = 0; playerSlider.value = 0
        populateLabelWithTime(lblStartTime, time: 0)
        populateLabelWithTime(lblEndTime,   time: 0)
        player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)

        NotificationCenter.default.addObserver(self,
            selector: #selector(playerDidFinishPlaying(sender:)),
            name: .AVPlayerItemDidPlayToEndTime, object: playerItem)

        if isPlay {
            playPauseBtn.setImage(UIImage(named: "ic_pause"), for: .normal)
            updateNowPlaying(isPause: false)
            lyricTimeObserver = player?.addPeriodicTimeObserver(
                forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: .main) {
                [weak self] time in
                guard let self = self, player?.currentItem?.status == .readyToPlay else { return }
                self.showLyric(toTime: CMTimeGetSeconds(time))
            }
            player?.play()
        } else {
            playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
            updateNowPlaying(isPause: true)
            player?.pause()
        }

        // setupNowPlaying now + again after item is buffered
        setupNowPlaying()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.setupNowPlaying()
        }

        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(value: 1, timescale: 1), queue: .main) { [weak self] t in
            guard let self = self else { return }
            self.playerSlider.value = Float(t.seconds)
            self.populateLabelWithTime(self.lblStartTime, time: t.seconds)
            self.updateNowPlayingElapsedTime(t.seconds)
        }
    }

    // MARK: playerDidFinishPlaying
    @objc func playerDidFinishPlaying(sender: Notification) {
        print("🏁 finished | #\(songCounter) repeat:\(isRepeat) waitAd:\(isWaitingForAd)")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.playerSlider.setValue(0, animated: true)
            self.populateLabelWithTime(self.lblStartTime, time: 0)
        }
        if let item = sender.object as? AVPlayerItem {
            NotificationCenter.default.removeObserver(self,
                name: .AVPlayerItemDidPlayToEndTime, object: item)
        }
        removeTimeObserverIfNeeded()
        guard !isWaitingForAd else { return }
        songCounter += 1
        if songCounter % 5 == 0 && !IAPHandler.shared.isGetPurchase() {
            displayAdsView()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.continuePlaying()
            }
        }
    }

    func displayAdsView() {
        guard !IAPHandler.shared.isGetPurchase() else { return }
        player?.pause()
        let q = PlaybackQueueManager.shared.getQueue()
        if !q.isEmpty                                      { pendingTrackAfterAd = (0, true) }
        else if let t = track, selectedIndex < t.count - 1 { pendingTrackAfterAd = (selectedIndex + 1, false) }
        else                                               { pendingTrackAfterAd = nil }
        isWaitingForAd = true
        let vc = storyboard?.instantiateViewController(withIdentifier: "AdsAPIView") as! AdsAPIView
        vc.delegate = self; vc.modalPresentationStyle = .fullScreen; present(vc, animated: true)
    }

    func continuePlaying() {
        guard !isWaitingForAd else { return }
        let q = PlaybackQueueManager.shared.getQueue()
        if isRepeat {
            if isPlayingQueueTrack, let qi = currentQueueIndex { playTrackAtIndex(qi, fromQueue: true) }
            else { playTrackAtIndex(selectedIndex, fromQueue: false) }
        } else if isPlayerListTap {
            playTrackAtIndex(selectedIndex, fromQueue: false); isPlayerListTap = false
        } else if !q.isEmpty {
            playTrackAtIndex(0, fromQueue: true)
        } else if let t = track, selectedIndex < t.count - 1 {
            playTrackAtIndex(selectedIndex + 1, fromQueue: false)
        } else { pausePlayer() }
    }

    // MARK: - Now Playing
    // FIX: Read from Track model (not UILabel) — labels may be stale when called early.
    // Artwork loaded from URL on background thread for reliability across category changes.
    func setupNowPlaying() {
        let item: Track? = isPlayingQueueTrack ? currentQueueTrack : track?[safe: selectedIndex]
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle]                    = item?.track  ?? (trackTitle.text  ?? "")
        info[MPMediaItemPropertyArtist]                  = item?.artist ?? (artistName.text ?? "")
        info[MPNowPlayingInfoPropertyIsLiveStream]        = false
        info[MPNowPlayingInfoPropertyPlaybackRate]        = player?.isPlaying == true ? 1.0 : 0.0
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.currentTime().seconds ?? 0.0
        let dur = player?.currentItem?.asset.duration.seconds ?? 0.0
        if dur > 0, !dur.isNaN, !dur.isInfinite { info[MPMediaItemPropertyPlaybackDuration] = dur }

        if let s = item?.artcover, let artURL = URL(string: s) {
            DispatchQueue.global(qos: .userInitiated).async {
                if let data = try? Data(contentsOf: artURL), let img = UIImage(data: data) {
                    info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
                }
                DispatchQueue.main.async { MPNowPlayingInfoCenter.default().nowPlayingInfo = info }
            }
        } else if let img = artCoverImage.image {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        } else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }

    private func updateNowPlayingElapsedTime(_ elapsed: Double) {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed
        info[MPNowPlayingInfoPropertyPlaybackRate] = player?.isPlaying == true ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func updateNowPlaying(isPause: Bool) {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyPlaybackRate]        = isPause ? 0.0 : 1.0
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.currentTime().seconds ?? 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // MARK: - Remote Transport Controls
    // FIX 1: Tokens stored in ivars → deinit removes ONLY this instance's handlers.
    // FIX 2: next/prev call forward/backwardBtnPressed directly — NOT pausePlayer() first,
    //        because pausePlayer() tears down AVPlayer before the next track can load.
    // FIX 3: play/pause guard the actual player state to return .commandFailed correctly,
    //        which keeps the lock screen button in sync with real playback state.
    func setupRemoteTransportControls() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let cmd = MPRemoteCommandCenter.shared()

        // Remove only OUR previous tokens (never nil — that's a global wipe)
        if let t = playCommandToken   { cmd.playCommand.removeTarget(t) }
        if let t = pauseCommandToken  { cmd.pauseCommand.removeTarget(t) }
        if let t = nextCommandToken   { cmd.nextTrackCommand.removeTarget(t) }
        if let t = prevCommandToken   { cmd.previousTrackCommand.removeTarget(t) }
        if let t = toggleCommandToken { cmd.togglePlayPauseCommand.removeTarget(t) }
        if let t = scrubCommandToken  { cmd.changePlaybackPositionCommand.removeTarget(t) }

        cmd.nextTrackCommand.isEnabled              = true
        cmd.previousTrackCommand.isEnabled          = true
        cmd.changePlaybackPositionCommand.isEnabled = true

        playCommandToken = cmd.playCommand.addTarget { [weak self] _ in
            guard let self = self, let p = player, !p.isPlaying else { return .commandFailed }
            p.play()
            DispatchQueue.main.async { self.playPauseBtn.setImage(UIImage(named: "ic_pause"), for: .normal) }
            self.updateNowPlaying(isPause: false)
            return .success
        }

        pauseCommandToken = cmd.pauseCommand.addTarget { [weak self] _ in
            guard let self = self, let p = player, p.isPlaying else { return .commandFailed }
            p.pause()
            DispatchQueue.main.async { self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal) }
            self.updateNowPlaying(isPause: true)
            return .success
        }

        toggleCommandToken = cmd.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            DispatchQueue.main.async { self.pausePressed() }
            return .success
        }

        // NEXT: same as tapping the on-screen forward button
        nextCommandToken = cmd.nextTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            guard !self.isLastTrack() else { return .commandFailed }
            DispatchQueue.main.async {
                self.isPlayerListTap = false
                self.forwardBtnPressed()   // do NOT call pausePlayer() first
            }
            return .success
        }

        // PREV: same as tapping the on-screen backward button
        prevCommandToken = cmd.previousTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            DispatchQueue.main.async {
                self.backwardBtnPressed()  // do NOT call pausePlayer() first
            }
            return .success
        }

        // SCRUB: lock screen / CC progress bar drag
        scrubCommandToken = cmd.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let e = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            player?.seek(to: CMTime(seconds: e.positionTime, preferredTimescale: 1),
                         toleranceBefore: .zero, toleranceAfter: .zero)
            self.updateNowPlayingElapsedTime(e.positionTime)
            return .success
        }
    }

    // MARK: - Controls
    func populateLabelWithTime(_ label: UILabel, time: Double) {
        guard !time.isNaN, !time.isInfinite else { label.text = "--:--"; return }
        label.text = String(format: "%02d:%02d", Int(time / 60), Int(time) % 60)
    }

    @objc func audioChanged() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.playPauseBtn.setImage(
                UIImage(named: player?.isPlaying == true ? "ic_pause" : "ic_play"), for: .normal)
        }
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

    @IBAction func likeBtnPressed(_ sender: Any) {
        isLike = !isLike
        btnLike.setImage(UIImage(named: isLike ? "ic_like_filled" : "ic_like"), for: .normal)
        if isPlayingQueueTrack { configureLike() } else { configureLike(index: selectedIndex) }
    }

    @IBAction func repeatBtnPressed(_ sender: Any) {
        isRepeat = !isRepeat
        let img = UIImage(named: "ic_repeat")?.withRenderingMode(.alwaysTemplate)
        btnRepeat.setImage(img, for: .normal)
        btnRepeat.tintColor = isRepeat ? .red : .white
    }

    // FIX: Do NOT call pausePlayer() in these events.
    // pausePlayer() → stopAndClearPlayer() destroys AVPlayer.
    // The next/prev track then has no player to replace, so nothing plays.
    @IBAction func backwardBtnEvent(_ sender: Any) { backwardBtnPressed() }

    func isLastTrack() -> Bool {
        guard let t = track else { return false }
        return selectedIndex == t.count - 1
            && !isPlayingQueueTrack
            && PlaybackQueueManager.shared.getQueue().isEmpty
    }

    @IBAction func forwardBtnEvent(_ sender: Any) {
        guard !isLastTrack() else { return }
        isPlayerListTap = false
        forwardBtnPressed()
    }

    @IBAction func progressSliderValueChanged() {
        let secs = Int64(playerSlider.value)
        player?.seek(to: CMTimeMake(value: secs, timescale: 1),
                     toleranceBefore: .zero, toleranceAfter: .zero)
        updateNowPlayingElapsedTime(Double(secs))
    }

    func pausePlayer() {
        stopAndClearPlayer()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.playerSlider.setValue(0, animated: true)
            self.populateLabelWithTime(self.lblStartTime, time: 0)
            self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
        }
        updateNowPlaying(isPause: true)
    }

    private func shouldPlayerListPressed() -> Bool { playerListTapCount >= 6 }
}

// MARK: - Like / Download / Recently Played
extension MusicPlayerViewController {

    func isAlreadyLiked(track: Track) {
        let saved = UserDefaultsManager.shared.localTracksData
        isLike = saved.contains { $0.isFav && $0.trackid == track.trackid }
        btnLike.setImage(UIImage(named: isLike ? "ic_like_filled" : "ic_like"), for: .normal)
    }

    func isAlreadyDownloaded(track: Track) {
        let saved = UserDefaultsManager.shared.localTracksData
        isDownload = saved.contains { $0.isDownload && $0.trackid == track.trackid }
        if isDownload {
            let img = UIImage(systemName: "checkmark.circle.fill")?.withRenderingMode(.alwaysTemplate)
            btnDownload.setImage(img, for: .normal)
            btnDownload.tintColor = .systemGreen
            btnDownload.layer.cornerRadius = 15
            btnDownload.layer.borderColor  = UIColor.systemGreen.cgColor
            btnDownload.layer.borderWidth  = 2
            btnDownload.clipsToBounds = true
            btnDownload.isUserInteractionEnabled = false
        } else {
            btnDownload.setImage(UIImage(named: "ic_download"), for: .normal)
            btnDownload.layer.cornerRadius = 0; btnDownload.layer.borderWidth = 0
            btnDownload.layer.borderColor  = nil; btnDownload.clipsToBounds = false
            btnDownload.isUserInteractionEnabled = true
        }
    }

    func configureLike(index: Int? = nil) {
        let item: Track? = isPlayingQueueTrack ? currentQueueTrack : (index.map { track?[safe: $0] } ?? nil)
        guard let t = item else { return }
        var saved = UserDefaultsManager.shared.localTracksData
        if let i = saved.firstIndex(where: { $0.trackid == t.trackid }) { saved[i].isFav = isLike }
        else { let n = t.convertToSongModel(); n.isFav = isLike; saved.append(n) }
        UserDefaultsManager.shared.localTracksData = saved
    }

    func configureDownload(index: Int? = nil) {
        let item: Track? = isPlayingQueueTrack ? currentQueueTrack : (index.map { track?[safe: $0] } ?? nil)
        guard let t = item else { return }
        var saved = UserDefaultsManager.shared.localTracksData
        if let i = saved.firstIndex(where: { $0.trackid == t.trackid }) { saved[i].isDownload = isDownload }
        else { let n = t.convertToSongModel(); n.isDownload = isDownload; saved.append(n) }
        UserDefaultsManager.shared.localTracksData = saved
    }

    func configureRecentlyPlayed(index: Int? = nil) {
        let item: Track? = isPlayingQueueTrack ? currentQueueTrack : (index.map { track?[safe: $0] } ?? nil)
        guard let t = item else { return }
        var saved = UserDefaultsManager.shared.localTracksData
        if let i = saved.firstIndex(where: { $0.trackid == t.trackid }) { saved[i].isRecentlyPlayed = true }
        else { let n = t.convertToSongModel(); n.isRecentlyPlayed = true; saved.append(n) }
        UserDefaultsManager.shared.localTracksData = saved
    }
}

// MARK: - Safe Subscript
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - OptionsViewControllerDelegate
extension MusicPlayerViewController: OptionsViewControllerDelegate {
    func didUpdateTrackMetadata() {
        DispatchQueue.main.async {
            self.radioTableView.reloadData()
            self.manageTableViewScroll()
        }
    }
}
