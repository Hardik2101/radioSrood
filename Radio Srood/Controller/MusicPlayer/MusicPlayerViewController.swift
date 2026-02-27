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
    var circularProgressView: CircularProgressView!

    @IBOutlet var vwProgress: UIView!
    var isPlayingQueueTrack: Bool = false
    var currentQueueIndex: Int? = nil
    var dataHelper: DataHelper!
    var nativeAd: GADUnifiedNativeAd?
    var adLoader: GADAdLoader!
    var isSetupRemoteTransport = false
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
    var timeObserver: Any?
    private var lastIndex: Int? = nil
    private var parser: LyricsParser? = nil
    private var isPurchaseSuccess: Bool = false
    private var currentPlayer: AVPlayer?
    private var playerItemStatusObserver: NSKeyValueObservation?
    private var hasTriedFallbackForItem: Bool = false
    var bannerAdViews: [GADBannerView] = []
    var imageURl: URL?
    var isMyMusic = false
    var playerListTapCount = 0
    var forwardButtonTapCount = 0
    private var parsedLyrics: [LyricLine] = []
    var isPlayerListTap = false
    var songCounter = 0
    var pendingTrackAfterAd: (index: Int, fromQueue: Bool)?
    var isWaitingForAd = false
    var isSyncedLyrics = false
    private var lyricSynced: String = ""
    var currentQueueTrack: Track? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let yourBackImage = UIImage(named: "left-arrow")
        self.navigationController?.navigationBar.backIndicatorImage = yourBackImage
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = yourBackImage
        self.navigationController?.navigationBar.tintColor = .white
        self.navigationController?.navigationBar.topItem?.title = ""
        self.navigationController?.navigationBar.backItem?.title = ""
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItem.Style.plain, target: nil, action: nil)
        radioTableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: 0.1))
        radioTableView.tableFooterView = UIView()
        loadNativeAd()
        prepareView()
        isSetupRemoteTransport = true
        vwDownloadProgress.isHidden = true
        vwDownloadProgress.setProgress(0.0, animated: false)

        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActiveNotificationReceived), name: NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerInterruption(notification:)), name: NSNotification.Name(rawValue: "AVAudioSessionInterruptionNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(audioChanged), name: .musicDidPlay, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(audioChanged), name: .musicDidPause, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleIAPPurchase), name: .PurchaseSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleIAPPurchase1), name: .aaaaaaaaaa, object: nil)

        radioTableView.register(UINib(nibName: "BannerAdCell", bundle: nil), forCellReuseIdentifier: "BannerAdCell")
        radioTableView.register(UINib(nibName: "HeaderCell", bundle: nil), forCellReuseIdentifier: "HeaderCell")
        radioTableView.translatesAutoresizingMaskIntoConstraints = false
        radioTableView.isScrollEnabled = false
        radioTableView.rowHeight = UITableView.automaticDimension
        radioTableView.estimatedRowHeight = 90
        setupCircularProgressView()
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.4
        radioTableView.addGestureRecognizer(longPress)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let point = gesture.location(in: radioTableView)
        guard let indexPath = radioTableView.indexPathForRow(at: point) else { return }
        
        let queueCount = PlaybackQueueManager.shared.getQueue().count
        let queueRows = queueCount > 0 ? queueCount + 1 : 0
        
        var selectedTrack: Track?
        
        if indexPath.row >= 2 && indexPath.row < 2 + queueRows && indexPath.row != 2 {
            let queueIndex = indexPath.row - 3
            selectedTrack = PlaybackQueueManager.shared.getQueue()[safe: queueIndex]
        } else if indexPath.row >= 2 + queueRows {
            let adjustedRow = indexPath.row - queueRows
            let trackIndex = adjustedRow - 3 + 1
            selectedTrack = tempTrack?[safe: trackIndex]
        }
        
        if let track = selectedTrack {
            presentOptionsViewController(for: track)
        }

        // FIX: Setup remote transport controls once here
        setupRemoteTransportControls()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        radioTableView.reloadData()
        manageTableViewScroll()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
            self.navigationController?.navigationBar.shadowImage = UIImage()
            self.navigationController?.navigationBar.isTranslucent = true
        }
        TabbarVC.available?.miniPlayer.miniplayer(hide: true)
        navigationItem.hidesBackButton = true
        navigationController?.setNavigationBarHidden(true, animated: animated)
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

    deinit {
        UIApplication.shared.endReceivingRemoteControlEvents()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [:]
        // FIX: Remove all remote command targets on deinit to avoid ghost handlers
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)
        NotificationCenter.default.removeObserver(self)
        removeTimeObserverIfNeeded()
        print("MusicPlayerViewController deinit")
    }

    // MARK: - Helper to safely remove time observer
    private func removeTimeObserverIfNeeded() {
        if let timeObserver = timeObserver, let player = currentPlayer {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
            self.currentPlayer = nil
        }
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

            let mainCount = 2
            let trackCount = self.tempTrack?.count ?? 0
            let queueCount = PlaybackQueueManager.shared.getQueue().count
            let queueRows = queueCount > 0 ? queueCount + 1 : 0
            let totalRows = mainCount + queueRows + (trackCount > 0 ? 1 : 0) + trackCount

            var totalHeight: CGFloat = 0
            totalHeight += IAPHandler.shared.isGetPurchase() ? 0 : 65
            totalHeight += 90
            totalHeight += queueRows > 0 ? CGFloat(queueRows * 90) : 0
            totalHeight += trackCount > 0 ? 40 : 0
            totalHeight += CGFloat(trackCount * 90) + 90

            self.tableBgHeightConstraints.constant = totalHeight
        }
    }

    func prepareView() {
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

    // MARK: - Data Loading
    private func loadNewReleaseData() {
        dataHelper = DataHelper()
        dataHelper.getNewReleaseData { [weak self] resp in
            guard let self = self, let resp = resp else { return }
            self.track = resp.newRelease.first(where: { $0.id == self.groupID })?.tracks
            self.tempTrack = self.track
            self.isSetMusic = true
            self.isPlay = true
            self.handleRecentInView(index: self.selectedIndex)
            self.manageTableViewScroll()
        }
    }

    private func loadTodayTopPicData() {
        dataHelper = DataHelper()
        dataHelper.getTodayTopPicDetailed { [weak self] resp in
            guard let self = self, let resp = resp else { return }
            self.track = resp.todayTopPick.first(where: { $0.playlistID == self.groupID })?.tracks
            self.tempTrack = self.track
            self.isSetMusic = true
            self.isPlay = true
            self.handleRecentInView(index: self.selectedIndex)
            self.manageTableViewScroll()
        }
    }

    func loadRecentlyAddedDetailedData() {
        dataHelper = DataHelper()
        dataHelper.getRecentlyAddedDataDetailed { [weak self] resp in
            guard let self = self, let resp = resp else { return }
            self.track = resp.recentlyAddedPlayListDetailed.first(where: { $0.playlistID == self.groupID })?.tracks
            self.tempTrack = self.track
            self.isSetMusic = true
            self.isPlay = true
            self.handleRecentInView(index: self.selectedIndex)
            self.manageTableViewScroll()
        }
    }

    private func loadFeaturedDataItems() {
        dataHelper = DataHelper()
        dataHelper.getFeaturedArtistSponserdDetailsData { [weak self] resp in
            guard let self = self, let resp = resp else { return }
            self.track = resp.featuredData.first(where: { $0.fDid == self.groupID })?.featuredItem
            self.tempTrack = self.track
            self.isSetMusic = true
            self.isPlay = true
            self.handleRecentInView(index: self.selectedIndex)
            self.manageTableViewScroll()
        }
    }

    private func loadTrendingPlaylistData() {
        dataHelper = DataHelper()
        dataHelper.getTrendingPlaylistData { [weak self] resp in
            guard let self = self, let resp = resp else { return }
            self.track = resp.trendingTracks.first(where: { $0.id == self.groupID })?.tracks
            self.tempTrack = self.track
            self.isSetMusic = true
            self.isPlay = true
            self.handleRecentInView(index: self.selectedIndex)
            self.manageTableViewScroll()
        }
    }

    private func loadPopularPlaylistData() {
        dataHelper = DataHelper()
        dataHelper.getPopularPlaylistData { [weak self] resp in
            guard let self = self, let resp = resp else { return }
            self.track = resp.popularTracks.first(where: { $0.id == self.groupID })?.tracks
            self.tempTrack = self.track
            self.isSetMusic = true
            self.isPlay = true
            self.handleRecentInView(index: self.selectedIndex)
            self.manageTableViewScroll()
        }
    }

    private func loadPlaylistData() {
        dataHelper = DataHelper()
        dataHelper.getPlaylistData { [weak self] resp in
            guard let self = self, let resp = resp else { return }
            self.track = resp.trendingPlaylist.first(where: { $0.id == self.groupID })?.tracks
            self.tempTrack = self.track
            self.isSetMusic = true
            self.isPlay = true
            self.handleRecentInView(index: self.selectedIndex)
            self.manageTableViewScroll()
        }
    }

    private func loadFeaturedArtistData() {
        dataHelper = DataHelper()
        dataHelper.getFeaturedArtistData { [weak self] resp in
            guard let self = self, let resp = resp else { return }
            self.track = resp.rSroodFeaturedArtistData.first(where: { $0.id == self.groupID })?.tracks
            self.tempTrack = self.track
            self.isSetMusic = true
            self.isPlay = true
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

    func handleRecentInView(index: Int, isQueueTrack: Bool = false) {
        self.artCoverImage.layer.cornerRadius = 3
        self.artCoverImage.layer.masksToBounds = true
        let item = isQueueTrack ? currentQueueTrack : track?[safe: index]
        guard let item = item else {
            print("Error: No track found at index \(index), isQueueTrack: \(isQueueTrack)")
            return
        }
        if let url = URL(string: item.artcover ?? "") {
            self.artCoverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            self.bgImageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "b1.png"))
            imageURl = url
        }
        self.trackTitle.text = item.track
        self.artistName.text = item.artist
        self.isAlreadyLiked(track: item)
        self.isAlreadyDownloaded(track: item)
        if isQueueTrack {
            self.configureRecentlyPlayed()
        } else {
            self.configureRecentlyPlayed(index: index)
        }
        lastIndex = nil

        DataHelper.getLyricsData(artist: item.artist ?? "", track: item.track ?? "") { [weak self] lyricItem in
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

        let urls = self.playbackURLs(for: item)
        if let primary = urls.primary {
            if isSetMusic {
                isSetMusic = false
                self.play(url: primary, isPlay: self.isPlay, fallbackURL: urls.fallback)
            }
        } else if let fallback = urls.fallback {
            if isSetMusic {
                isSetMusic = false
                self.play(url: fallback, isPlay: self.isPlay, fallbackURL: nil)
            }
        } else {
            print("Error: Invalid media URL for track \(item.track ?? "Unknown")")
            pausePlayer()
        }
        AppPlayer.miniPlayerInfo = BasicDetail(
            songImage: item.artcover ?? "",
            songNameTitle: item.track ?? "",
            artistSubtitle: item.artist ?? "",
            musicVC: self
        )
    }

    private func playbackURLs(for track: Track) -> (primary: URL?, fallback: URL?) {
        var primaryURL: URL? = nil
        var fallbackURL: URL? = nil
        if let hls = track.hlsMediaPath?.trimmingCharacters(in: .whitespacesAndNewlines), !hls.isEmpty {
            if let url = URL(string: hls), url.scheme != nil {
                primaryURL = url
            } else if let encoded = hls.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                      let url = URL(string: hlsSongPath + encoded) {
                primaryURL = url
            }
        }
        if let media = track.mediaPath?.trimmingCharacters(in: .whitespacesAndNewlines), !media.isEmpty {
            if let url = URL(string: media), url.scheme != nil {
                fallbackURL = url
            } else if let encoded = media.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                      let url = URL(string: songPath + encoded) {
                fallbackURL = url
            }
        }
        return (primaryURL, fallbackURL)
    }

    private func showLyrics() {
        self.heightView.constant = 40
        self.viewLyrics.isHidden = false
    }

    private func hideLyrics() {
        self.heightView.constant = 0
        self.viewLyrics.isHidden = true
        self.parser = nil
        self.lblLyrics.text = ""
    }

    func showLyric(toTime time: TimeInterval) {
        guard !parsedLyrics.isEmpty else { return }
        guard let index = parsedLyrics.firstIndex(where: { $0.time >= time }) else { return }
        guard lastIndex == nil || index - 1 != lastIndex else { return }
        if index > 0 {
            let line = parsedLyrics[index - 1]
            self.lblLyrics.text = line.text
            lastIndex = index - 1
        }
    }

    @objc func lyricsBtnClicked() {
        let item: Track?
        if isPlayingQueueTrack, let queueTrack = currentQueueTrack {
            item = queueTrack
        } else {
            item = track?[safe: selectedIndex]
        }
        guard let trackItem = item else { return }
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "LyricPlayViewController") as! LyricPlayViewController
        vc.currentSong = trackItem.convertToSongModel()
        vc.imageURl = self.imageURl
        vc.lyricnew = self.lyricSynced
        vc.isSyncedLyrics = self.isSyncedLyrics
        self.present(vc, animated: true)
    }

    @objc func optionMenuBtnClicked() {
        let item: Track? = isPlayingQueueTrack ? currentQueueTrack : track?[safe: selectedIndex]
        guard let trackItem = item else { return }
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PlayerOptionViewController") as! PlayerOptionViewController
        vc.currentSong = trackItem.convertToSongModel()
        vc.track = trackItem
        vc.lyricsNew = self.lyricSynced
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }

    @objc func moreInfoBtnClicked() {
        let item: Track? = isPlayingQueueTrack ? currentQueueTrack : track?[safe: selectedIndex]
        guard let trackItem = item else { return }
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PlayListViewController") as! PlayListViewController
        vc.songToSave = trackItem.convertToSongModel()
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }

    @objc func addToCollection() {
        isMyMusic = !isMyMusic
        let item: Track? = isPlayingQueueTrack ? currentQueueTrack : track?[safe: selectedIndex]
        guard let trackItem = item?.convertToSongModel() else { return }
        var savedTracks = UserDefaultsManager.shared.localTracksData
        let trackIndex = savedTracks.firstIndex(where: { $0.trackid == trackItem.trackid })
        if let trackIndex = trackIndex {
            savedTracks[trackIndex].isBookMarked = !savedTracks[trackIndex].isBookMarked
            showToast(message: savedTracks[trackIndex].isBookMarked ? "Successfully add in My Collection" : "Remove from my collection", font: .systemFont(ofSize: 12.0))
        } else {
            var newItem = trackItem
            newItem.isBookMarked = true
            savedTracks.append(newItem)
            showToast(message: "Successfully add in My Collection", font: .systemFont(ofSize: 12.0))
        }
        UserDefaultsManager.shared.localTracksData = savedTracks
        radioTableView.reloadData()
    }

    // MARK: - Navigation
    @objc func backwardBtnPressed() {
        if isPlayingQueueTrack {
            if let queueIndex = currentQueueIndex, queueIndex > 0 {
                playTrackAtIndex(queueIndex - 1, fromQueue: true)
            } else if let track = track, selectedIndex > 0 {
                isPlayingQueueTrack = false
                currentQueueIndex = nil
                playTrackAtIndex(selectedIndex - 1, fromQueue: false)
            } else {
                pausePlayer()
            }
        } else if let track = track, selectedIndex > 0 {
            playTrackAtIndex(selectedIndex - 1, fromQueue: false)
        } else {
            pausePlayer()
        }
    }

    @objc func forwardBtnPressed() {
        forwardButtonTapCount += 1
        let queue = PlaybackQueueManager.shared.getQueue()

        let nextTrackInfo: (index: Int, fromQueue: Bool)?
        if !queue.isEmpty {
            nextTrackInfo = (0, true)
        } else if let track = track, selectedIndex < track.count - 1 {
            nextTrackInfo = (selectedIndex + 1, false)
        } else {
            nextTrackInfo = nil
        }

        if shouldPlayAdForwardBtnPressed() && !IAPHandler.shared.isGetPurchase() {
            player?.pause()
            pendingTrackAfterAd = nextTrackInfo
            isWaitingForAd = true
            let vc = storyboard?.instantiateViewController(withIdentifier: "AdsAPIView") as! AdsAPIView
            vc.delegate = self
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
            forwardButtonTapCount = 0
        } else {
            if let nextTrack = nextTrackInfo {
                playTrackAtIndex(nextTrack.index, fromQueue: nextTrack.fromQueue)
            } else {
                pausePlayer()
            }
        }
    }

    private func shouldPlayAdForwardBtnPressed() -> Bool {
        return forwardButtonTapCount >= 6
    }

    func adsPlaybackDidFinish() {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.isWaitingForAd = false
            if let pending = self.pendingTrackAfterAd {
                self.playTrackAtIndex(pending.index, fromQueue: pending.fromQueue)
                self.pendingTrackAfterAd = nil
            } else {
                let queue = PlaybackQueueManager.shared.getQueue()
                if !queue.isEmpty {
                    self.playTrackAtIndex(0, fromQueue: true)
                } else if let track = self.track, self.selectedIndex < track.count {
                    self.playTrackAtIndex(self.selectedIndex, fromQueue: false)
                } else {
                    self.pausePlayer()
                }
            }
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

    @IBAction func actionLyrics(_ sender: Any) { lyricsBtnClicked() }

    @IBAction func actionClose(_ sender: Any) {
        self.dismiss(animated: true)
        self.navigationController?.popViewController(animated: true)
    }

    @objc private func handleIAPPurchase() {
        isPurchaseSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.isPurchaseSuccess = false
        }
    }

    @objc private func handleIAPPurchase1() {}

    @IBAction func clickOn_btnDownload(_ sender: Any) {
        let purchase = IAPHandler.shared.isGetPurchase()
        if purchase || self.isPurchaseSuccess {
            let item: Track? = isPlayingQueueTrack ? currentQueueTrack : track?[safe: selectedIndex]
            guard let trackItem = item else { return }
            let urlString = trackItem.mediaPath?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            guard let mediaPathInfo = urlString, let url = URL(string: songPath + mediaPathInfo) else { return }
            let name = url.lastPathComponent
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsURL.appendingPathComponent(name)
            btnDownload.isHidden = true
            vwProgress.isHidden = false
            circularProgressView.setProgress(0)
            circularProgressView.isHidden = false
            AF.download(url, to: { _, _ in (destinationURL, [.removePreviousFile, .createIntermediateDirectories]) })
                .downloadProgress { [weak self] progress in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.circularProgressView.setProgress(Float(progress.fractionCompleted))
                    }
                    if progress.fractionCompleted == 1.0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.circularProgressView.setProgress(1.0)
                            self.circularProgressView.lineWidth = 2
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
                                if self.isPlayingQueueTrack {
                                    self.configureDownload()
                                } else {
                                    self.configureDownload(index: self.selectedIndex)
                                }
                            }
                        }
                    }
                }
                .response { response in
                    if let destinationURL = response.fileURL {
                        print("File downloaded to: \(destinationURL)")
                    }
                }
            UserDefaults.standard.set(trackItem.artcover, forKey: "\(url.deletingPathExtension().lastPathComponent)")
        } else {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "IAPVC") as! IAPVC
            vc.isshowbackButton = true
            let navVC = UINavigationController(rootViewController: vc)
            navVC.navigationBar.isHidden = true
            navVC.modalPresentationStyle = .fullScreen
            self.present(navVC, animated: true)
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
}

// MARK: - UITableView
extension MusicPlayerViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { return 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let mainCount = 2
        let trackCount = (tempTrack?.count ?? 0) > 0 ? (tempTrack!.count - 1) : 0
        let queueCount = PlaybackQueueManager.shared.getQueue().count
        let queueRows = queueCount > 0 ? queueCount + 1 : 0
        let totalRows = mainCount + queueRows + (trackCount > 0 ? 1 : 0) + trackCount
        return totalRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let queueCount = PlaybackQueueManager.shared.getQueue().count
        let queueRows = queueCount > 0 ? queueCount + 1 : 0

        if indexPath.row == 0 {
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
                bannerView.frame = cell.vwMain.bounds
                cell.vwMain.addSubview(bannerView)
            }
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            return cell
        } else if indexPath.row == 1 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "RecentPlayerOptionCell", for: indexPath) as? RecentPlayerOptionCell else {
                return UITableViewCell()
            }
            cell.selectionStyle = .none
            cell.btnLyrics.addTarget(self, action: #selector(lyricsBtnClicked), for: .touchUpInside)
            cell.btnMoreInfo.addTarget(self, action: #selector(moreInfoBtnClicked), for: .touchUpInside)
            cell.btnOption.addTarget(self, action: #selector(optionMenuBtnClicked), for: .touchUpInside)
            cell.btnAddtoCollection.addTarget(self, action: #selector(addToCollection), for: .touchUpInside)
            let item: Track? = isPlayingQueueTrack ? currentQueueTrack : track?[safe: selectedIndex]
            let savedTracks = UserDefaultsManager.shared.localTracksData
            let trackIndex = savedTracks.firstIndex(where: { $0.trackid == item?.convertToSongModel().trackid })
            let isBookmarked = trackIndex.flatMap { savedTracks[safe: $0]?.isBookMarked } ?? false
            cell.btnAddtoCollection.setImage(UIImage(named: isBookmarked ? "ic_bookmark_fill" : "ic_bookmark"), for: .normal)
            return cell
        } else if indexPath.row == 2 && queueRows > 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell", for: indexPath) as! HeaderCell
            cell.headerLabel.text = "Up Next from Queue"
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            cell.contentView.isUserInteractionEnabled = false
            return cell
        } else if indexPath.row >= 2 && indexPath.row < 2 + queueRows {
            let queue = PlaybackQueueManager.shared.getQueue()
            let queueIndex = indexPath.row - 3
            if queueIndex >= 0 && queueIndex < queue.count {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RecentListCell", for: indexPath) as! RecentListCell
                cell.selectionStyle = .none
                cell.artCoverImage.layer.cornerRadius = 3
                cell.artCoverImage.layer.masksToBounds = true
                let item = queue[queueIndex]
                cell.trackTitle.text = item.track
                cell.artistName.text = item.artist
                if let url = URL(string: item.artcover ?? "" + "?s=200") {
                    cell.artCoverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                    cell.imgBg.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                }
                return cell
            }
            return UITableViewCell()
        } else {
            let adjustedRow = indexPath.row - queueRows
            if adjustedRow == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell", for: indexPath) as! HeaderCell
                cell.headerLabel.text = "Up Next"
                cell.selectionStyle = .none
                cell.backgroundColor = .clear
                cell.contentView.isUserInteractionEnabled = false
                return cell
            } else {
                let trackIndex = adjustedRow - 3 + 1
                if trackIndex >= 1 && trackIndex < tempTrack?.count ?? 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "RecentListCell", for: indexPath) as! RecentListCell
                    cell.selectionStyle = .none
                    cell.artCoverImage.layer.cornerRadius = 3
                    cell.artCoverImage.layer.masksToBounds = true
                    if let item = tempTrack?[trackIndex] {
                        cell.trackTitle.text = item.track
                        cell.artistName.text = item.artist
                        if let url = URL(string: item.artcover ?? "" + "?s=200") {
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
        guard let optionsVC = storyboard?.instantiateViewController(withIdentifier: "OptionsViewController") as? OptionsViewController else {
            print("Error: Could not instantiate OptionsViewController")
            return
        }
        optionsVC.track = track
        optionsVC.delegate = self  // if you want delegate callbacks
        optionsVC.modalPresentationStyle = .overFullScreen
        present(optionsVC, animated: true)
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let queueCount = PlaybackQueueManager.shared.getQueue().count
        let queueRows = queueCount > 0 ? queueCount + 1 : 0

        if indexPath.row >= 2 && indexPath.row < 2 + queueRows && indexPath.row != 2 {
            let queueIndex = indexPath.row - 3
            if queueIndex >= 0 && queueIndex < PlaybackQueueManager.shared.getQueue().count {
                isPlayerListTap = false
                playTrackAtIndex(queueIndex, fromQueue: true)
                DispatchQueue.main.async { self.radioTableView.reloadData(); self.manageTableViewScroll() }
            }
        } else if indexPath.row >= 2 + queueRows {
            let adjustedRow = indexPath.row - queueRows
            let trackIndex = adjustedRow - 3 + 1
            if trackIndex >= 1 && trackIndex < tempTrack?.count ?? 0 {
                isPlayerListTap = true
                playTrackAtIndex(trackIndex, fromQueue: false)
                playerListTapCount += 1
                if shouldPlayerListPressed() && !IAPHandler.shared.isGetPurchase() {
                    isPlayerListTap = true
                    playerListTapCount = 0
                    player?.pause()
                    pendingTrackAfterAd = (trackIndex, false)
                    isWaitingForAd = true
                    let vc = storyboard?.instantiateViewController(withIdentifier: "AdsAPIView") as! AdsAPIView
                    vc.delegate = self
                    vc.modalPresentationStyle = .fullScreen
                    self.present(vc, animated: true)
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
extension MusicPlayerViewController {

    private func playTrackAtIndex(_ index: Int, fromQueue: Bool = false) {
        let queue = PlaybackQueueManager.shared.getQueue()
        let trackList: [Track]? = fromQueue ? queue : self.track
        guard let trackList = trackList, index >= 0, index < trackList.count else {
            print("Error: Invalid track index \(index)")
            pausePlayer()
            return
        }
        let item = trackList[index]
        let urls = self.playbackURLs(for: item)
        guard let primary = urls.primary ?? urls.fallback else {
            print("Error: Invalid media URL for track \(item.track ?? "Unknown")")
            pausePlayer()
            return
        }

        if !fromQueue {
            selectedIndex = index
            isPlayingQueueTrack = false
            currentQueueIndex = nil
            currentQueueTrack = nil
        } else {
            isPlayingQueueTrack = true
            currentQueueIndex = index
            currentQueueTrack = item
        }

        // FIX: Fully tear down player before rebuilding
        stopAndClearPlayer()
        isSetMusic = false
        isPlay = true
        self.play(url: primary, isPlay: true, fallbackURL: urls.primary == nil ? nil : urls.fallback)
        handleRecentInView(index: index, isQueueTrack: fromQueue)

        if fromQueue {
            PlaybackQueueManager.shared.removeFromQueue(at: index)
            currentQueueIndex = PlaybackQueueManager.shared.getQueue().isEmpty ? nil : index
            DispatchQueue.main.async {
                self.radioTableView.reloadData()
                self.manageTableViewScroll()
            }
        }
    }

    // FIX: Single clean teardown method
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
                                    // FIX: Update NowPlaying with correct duration after fallback ready
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
                        // FIX: Update NowPlaying with correct duration once ready
                        self.setupNowPlaying()
                    }
                }
            }
        }

        player = PlayObserver(playerItem: playerItem)
        currentPlayer = player

        self.playerSlider.minimumValue = 0.0
        self.playerSlider.maximumValue = 0.0
        self.playerSlider.value = 0.0
        populateLabelWithTime(self.lblStartTime, time: 0.0)
        populateLabelWithTime(self.lblEndTime, time: 0.0)
        player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)

        // FIX: Observe end-of-item BEFORE playing
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.playerDidFinishPlaying(sender:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem  // FIX: use playerItem directly, not player?.currentItem
        )

        if isPlay {
            self.playPauseBtn.setImage(UIImage(named: "ic_pause"), for: .normal)
            self.updateNowPlaying(isPause: false)

            // Lyric sync observer (1s interval)
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

        // FIX: Time observer stored properly
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(value: 1, timescale: 1),
            queue: DispatchQueue.main  // FIX: use main queue to avoid dispatch async inside
        ) { [weak self] progressTime in
            guard let self = self else { return }
            self.playerSlider.value = Float(progressTime.seconds)
            self.populateLabelWithTime(self.lblStartTime, time: progressTime.seconds)
            // FIX: Keep NowPlaying elapsed time in sync
            self.updateNowPlayingElapsedTime(progressTime.seconds)
        }
    }

    // MARK: - Player Did Finish
    @objc func playerDidFinishPlaying(sender: Notification) {
        print("🏁 Song finished, counter: \(songCounter), repeat: \(isRepeat), waitingForAd: \(isWaitingForAd)")

        // FIX: Reset UI on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.playerSlider.setValue(0, animated: true)
            self.populateLabelWithTime(self.lblStartTime, time: 0.0)
        }

        // FIX: Remove observer for this specific item to avoid duplicate fires
        if let item = sender.object as? AVPlayerItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: item)
        }

        // Remove time observer
        removeTimeObserverIfNeeded()

        guard !isWaitingForAd else {
            print("⏸ Waiting for ad, skipping auto-advance")
            return
        }

        songCounter += 1
        if songCounter % 5 == 0 && !IAPHandler.shared.isGetPurchase() {
            displayAdsView()
        } else {
            // FIX: Small delay ensures player state is fully settled before next track
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.continuePlaying()
            }
        }
    }

    func displayAdsView() {
        guard !IAPHandler.shared.isGetPurchase() else { return }
        player?.pause()
        let queue = PlaybackQueueManager.shared.getQueue()
        if !queue.isEmpty {
            pendingTrackAfterAd = (0, true)
        } else if let track = track, selectedIndex < track.count - 1 {
            pendingTrackAfterAd = (selectedIndex + 1, false)
        } else {
            pendingTrackAfterAd = nil
        }
        isWaitingForAd = true
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "AdsAPIView") as! AdsAPIView
        vc.delegate = self
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }

    func continuePlaying() {
        guard !isWaitingForAd else { return }

        let queue = PlaybackQueueManager.shared.getQueue()
        print("▶️ continuePlaying: repeat=\(isRepeat), queue=\(queue.count), selectedIndex=\(selectedIndex), track count=\(track?.count ?? 0)")

        if isRepeat {
            if isPlayingQueueTrack, let queueIndex = currentQueueIndex {
                playTrackAtIndex(queueIndex, fromQueue: true)
            } else {
                playTrackAtIndex(selectedIndex, fromQueue: false)
            }
        } else if isPlayerListTap {
            playTrackAtIndex(selectedIndex, fromQueue: false)
            isPlayerListTap = false
        } else if !queue.isEmpty {
            playTrackAtIndex(0, fromQueue: true)
        } else if let track = track, selectedIndex < track.count - 1 {
            playTrackAtIndex(selectedIndex + 1, fromQueue: false)
        } else {
            pausePlayer()
        }
    }

    // MARK: - Now Playing - FIXED
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
            // FIX: Include duration
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

    // FIX: New method - keep elapsed time updated without rebuilding entire info dict
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

    // MARK: - Remote Transport Controls - FIXED
    func setupRemoteTransportControls() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()

        // FIX: Remove old targets before adding new ones
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

        // FIX: nextTrackCommand now uses weak self and calls forwardBtnPressed correctly
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            DispatchQueue.main.async {
                guard !self.isLastTrack() else { return }
                self.isPlayerListTap = false
                self.pausePlayer()
                self.forwardBtnPressed()
            }
            return .success
        }

        // FIX: previousTrackCommand uses weak self and calls backwardBtnPressed correctly
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            DispatchQueue.main.async {
                self.pausePlayer()
                self.backwardBtnPressed()
            }
            return .success
        }

        // FIX: Scrubbing from lock screen / Control Center
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let e = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            let targetTime = CMTime(seconds: e.positionTime, preferredTimescale: 1)
            player?.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
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

    @objc func audioChanged() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.playPauseBtn.setImage(UIImage(named: player?.isPlaying == true ? "ic_pause" : "ic_play"), for: .normal)
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
        let image = UIImage(named: "ic_repeat")?.withRenderingMode(.alwaysTemplate)
        self.btnRepeat.setImage(image, for: .normal)
        self.btnRepeat.tintColor = isRepeat ? .red : .white
    }

    @IBAction func backwardBtnEvent(_ sender: Any) {
        self.pausePlayer()
        self.backwardBtnPressed()
    }

    func isLastTrack() -> Bool {
        guard let track = track else { return false }
        return selectedIndex == track.count - 1 && !isPlayingQueueTrack && PlaybackQueueManager.shared.getQueue().isEmpty
    }

    @IBAction func forwardBtnEvent(_ sender: Any) {
        guard !isLastTrack() else { return }
        isPlayerListTap = false
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

    private func shouldPlayerListPressed() -> Bool {
        return playerListTapCount >= 6
    }
}

// MARK: - Like / Download / Recently Played
extension MusicPlayerViewController {
    func isAlreadyLiked(track: Track) {
        let savedTracks = UserDefaultsManager.shared.localTracksData
        isLike = savedTracks.contains { $0.isFav && $0.trackid == track.trackid }
        btnLike.setImage(UIImage(named: isLike ? "ic_like_filled" : "ic_like"), for: .normal)
    }

    func isAlreadyDownloaded(track: Track) {
        let savedTracks = UserDefaultsManager.shared.localTracksData
        isDownload = savedTracks.contains { $0.isDownload && $0.trackid == track.trackid }
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
    }

    func configureLike(index: Int? = nil) {
        let item: Track? = isPlayingQueueTrack ? currentQueueTrack : (index != nil ? track?[safe: index!] : nil)
        guard let trackItem = item else { return }
        var savedTracks = UserDefaultsManager.shared.localTracksData
        if let i = savedTracks.firstIndex(where: { $0.trackid == trackItem.trackid }) {
            savedTracks[i].isFav = isLike
        } else {
            let newItem = trackItem.convertToSongModel()
            newItem.isFav = isLike
            savedTracks.append(newItem)
        }
        UserDefaultsManager.shared.localTracksData = savedTracks
    }

    func configureDownload(index: Int? = nil) {
        let item: Track? = isPlayingQueueTrack ? currentQueueTrack : (index != nil ? track?[safe: index!] : nil)
        guard let trackItem = item else { return }
        var savedTracks = UserDefaultsManager.shared.localTracksData
        if let i = savedTracks.firstIndex(where: { $0.trackid == trackItem.trackid }) {
            savedTracks[i].isDownload = isDownload
        } else {
            let newItem = trackItem.convertToSongModel()
            newItem.isDownload = isDownload
            savedTracks.append(newItem)
        }
        UserDefaultsManager.shared.localTracksData = savedTracks
    }

    func configureRecentlyPlayed(index: Int? = nil) {
        let item: Track? = isPlayingQueueTrack ? currentQueueTrack : (index != nil ? track?[safe: index!] : nil)
        guard let trackItem = item else { return }
        var savedTracks = UserDefaultsManager.shared.localTracksData
        if let i = savedTracks.firstIndex(where: { $0.trackid == trackItem.trackid }) {
            savedTracks[i].isRecentlyPlayed = true
        } else {
            let newItem = trackItem.convertToSongModel()
            newItem.isRecentlyPlayed = true
            savedTracks.append(newItem)
        }
        UserDefaultsManager.shared.localTracksData = savedTracks
    }
}

// MARK: - Safe Collection Subscript
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
extension MusicPlayerViewController: OptionsViewControllerDelegate {
    func didUpdateTrackMetadata() {
        DispatchQueue.main.async {
            self.radioTableView.reloadData()
            self.manageTableViewScroll()
        }
    }
}
