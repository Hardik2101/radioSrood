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
    private var currentPlayer: AVPlayer?
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

    // MARK: - Queue state
    var isPlayingQueueTrack: Bool = false
    var currentQueueIndex: Int? = nil
    var currentQueueTrack: Track? = nil

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

        NotificationCenter.default.addObserver(
            self, selector: #selector(didBecomeActiveNotificationReceived),
            name: NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification"), object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(playerInterruption(notification:)),
            name: NSNotification.Name(rawValue: "AVAudioSessionInterruptionNotification"), object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleIAPPurchase),
            name: .PurchaseSuccess, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(queueDidUpdate),
            name: .queueUpdated, object: nil)

        radioTableView.register(UINib(nibName: "BannerAdCell", bundle: nil), forCellReuseIdentifier: "BannerAdCell")
        radioTableView.register(UINib(nibName: "HeaderCell", bundle: nil), forCellReuseIdentifier: "HeaderCell")
        self.radioTableView.isScrollEnabled = false

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(lyricsBtnClicked))
        vwLyrics.isUserInteractionEnabled = true
        vwLyrics.addGestureRecognizer(tapGesture)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.4
        radioTableView.addGestureRecognizer(longPress)

        setupCircularProgressView()
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

    // MARK: - Queue Update Handler
    @objc private func queueDidUpdate() {
        DispatchQueue.main.async {
            self.radioTableView.reloadData()
            self.manageTableViewScroll()
        }
    }

    // MARK: - Long Press Handler
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let point = gesture.location(in: radioTableView)
        guard let indexPath = radioTableView.indexPathForRow(at: point) else { return }

        let queueCount = PlaybackQueueManager.shared.getQueue().count
        let queueRows = queueCount > 0 ? queueCount + 1 : 0

        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()

        guard indexPath.row >= 2 else { return }

        if indexPath.row == 2 && queueRows > 0 {
            return
        }

        if indexPath.row >= 3 && indexPath.row < 2 + queueRows {
            let queueIndex = indexPath.row - 3
            let queue = PlaybackQueueManager.shared.getQueue()
            guard let queueTrack = queue[safe: queueIndex] else {
                print("Error: No queue track at index \(queueIndex)")
                return
            }
            print("Long press on queue track: \(queueTrack.track ?? "Unknown")")
            presentOptionsViewControllerForTrack(queueTrack)
        } else {
            let adjustedRow = indexPath.row - queueRows
            if adjustedRow == 2 { return }
            let trackIndex = adjustedRow - 3 + 1
            guard let selectedTrack = tempTrack?[safe: trackIndex] else {
                print("Error: No track at trackIndex \(trackIndex) for row \(indexPath.row)")
                return
            }
            print("Long press on Up Next track: \(selectedTrack.trackName ?? "Unknown") at trackIndex: \(trackIndex)")
            presentOptionsViewController(for: selectedTrack)
        }
    }

    // MARK: - Options VC Helpers
    private func presentOptionsViewController(for podcastTrack: PodcastObject) {
        guard let optionsVC = storyboard?.instantiateViewController(withIdentifier: "OptionsViewController") as? OptionsViewController else {
            print("Error: Could not instantiate OptionsViewController")
            return
        }
        optionsVC.track = podcastTrack.convertToTrackModel()
        optionsVC.delegate = self
        optionsVC.modalPresentationStyle = .overFullScreen
        present(optionsVC, animated: true)
    }

    private func presentOptionsViewControllerForTrack(_ track: Track) {
        guard let optionsVC = storyboard?.instantiateViewController(withIdentifier: "OptionsViewController") as? OptionsViewController else {
            print("Error: Could not instantiate OptionsViewController")
            return
        }
        optionsVC.track = track
        optionsVC.delegate = self
        optionsVC.modalPresentationStyle = .overFullScreen
        present(optionsVC, animated: true)
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

    // MARK: - manageTableViewScroll (queue-aware)
    func manageTableViewScroll() {
        DispatchQueue.main.async {
            self.radioTableView.reloadData()
            self.radioTableView.layoutIfNeeded()
            let trackCount = (self.tempTrack?.count ?? 0) > 1 ? (self.tempTrack!.count - 1) : 0
            let queueCount = PlaybackQueueManager.shared.getQueue().count
            let queueRows = queueCount > 0 ? queueCount + 1 : 0

            var totalHeight: CGFloat = 0
            totalHeight += IAPHandler.shared.isGetPurchase() ? 0 : 65
            totalHeight += 90
            totalHeight += queueRows > 0 ? CGFloat(queueRows * 90) : 0
            totalHeight += trackCount > 0 ? 40 : 0
            totalHeight += CGFloat(trackCount * 90)

            self.tableBgHeightConstraints.constant = totalHeight
            print("TableView height: \(totalHeight), queueCount: \(queueCount), trackCount: \(trackCount)")
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

    // MARK: - handleRecentInView
    func handleRecentInView(index: Int) {
        var idx = index
        if isShuffle, let tracks = track {
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
        let track = tracks[idx]
        if let imageURL = track.imageURL {
            artCoverImage.af_setImage(withURL: imageURL, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            bgImageView.af_setImage(withURL: imageURL, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            self.imageURl = imageURL
        }
        self.trackTitle.text = track.trackName
        self.artistName.text = track.artistName

        btnDownload.isHidden = !isShowOptionList
        btnLike.isHidden = !isShowOptionList

        isAlreadyDownloaded(track: track)
        isAlreadyLiked(track: track)
        isAlreadyBookmarked(track: track)
        lastIndex = nil

        DataHelper.getLyricsData(artist: track.artistName ?? "", track: track.trackName ?? "") { [weak self] lyricItem in
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
                    self.lblLyricsText.text = ""
                    self.isSyncedLyrics = true
                } else if !plain.isEmpty {
                    self.lyricSynced = plain
                    self.hideLyrics()
                    self.lblLyricsText.text = plain
                    self.isSyncedLyrics = false
                } else {
                    self.hideLyrics()
                }
            }
        }

        if isSetMusic {
            isSetMusic = false
            let urls = playbackURLs(for: track)
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
            songImage: track.imageURL?.absoluteString ?? "",
            songNameTitle: track.trackName ?? "",
            artistSubtitle: track.artistName ?? "",
            musicVC: self
        )
    }

    // MARK: - Queue Track Playback
    private func playQueueTrackAtIndex(_ index: Int) {
        let queue = PlaybackQueueManager.shared.getQueue()
        guard index >= 0, index < queue.count else {
            print("Error: Invalid queue index \(index)")
            return
        }
        let item = queue[index]
        print("Playing queue track: \(item.track ?? "Unknown") at index: \(index)")

        isPlayingQueueTrack = true
        currentQueueIndex = index
        currentQueueTrack = item

        var primaryURL: URL? = nil
        var fallbackURL: URL? = nil
        if let hls = item.hlsMediaPath?.trimmingCharacters(in: .whitespacesAndNewlines), !hls.isEmpty {
            if let url = URL(string: hls), url.scheme != nil {
                primaryURL = url
            } else if let encoded = hls.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                      let url = URL(string: hlsSongPath + encoded) {
                primaryURL = url
            }
        }
        if let media = item.mediaPath?.trimmingCharacters(in: .whitespacesAndNewlines), !media.isEmpty {
            if let url = URL(string: media), url.scheme != nil {
                fallbackURL = url
            } else if let encoded = media.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                      let url = URL(string: songPath + encoded) {
                fallbackURL = url
            }
        }

        guard let playURL = primaryURL ?? fallbackURL else {
            print("Error: No valid URL for queue track \(item.track ?? "Unknown")")
            return
        }

        pausePlayer()
        isPlay = true

        if let artcover = item.artcover, let url = URL(string: artcover) {
            artCoverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            bgImageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
        }
        trackTitle.text = item.track
        artistName.text = item.artist

        DataHelper.getLyricsData(artist: item.artist ?? "", track: item.track ?? "") { [weak self] lyricItem in
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
                    self.lblLyricsText.text = ""
                    self.isSyncedLyrics = true
                } else if !plain.isEmpty {
                    self.lyricSynced = plain
                    self.hideLyrics()
                    self.lblLyricsText.text = plain
                    self.isSyncedLyrics = false
                } else {
                    self.hideLyrics()
                }
            }
        }

        play(url: playURL, isPlay: true, fallbackURL: primaryURL == nil ? nil : fallbackURL)

        PlaybackQueueManager.shared.removeFromQueue(at: index)
        print("Queue track \(item.track ?? "Unknown") removed from queue, queue count now: \(PlaybackQueueManager.shared.getQueue().count)")

        let remainingQueue = PlaybackQueueManager.shared.getQueue()
        currentQueueIndex = remainingQueue.isEmpty ? nil : index < remainingQueue.count ? index : nil

        DispatchQueue.main.async {
            self.radioTableView.reloadData()
            self.manageTableViewScroll()
        }
    }

    // MARK: - Forward / Backward
    @objc func backwardBtnPressed() {
        if isPlayingQueueTrack {
            isPlayingQueueTrack = false
            currentQueueIndex = nil
            currentQueueTrack = nil
            if selectedIndex > 0 { selectedIndex -= 1 }
            isSetMusic = true
            isPlay = true
            handleRecentInView(index: selectedIndex)
            manageTableViewScroll()
            return
        }
        if let track = track {
            if isShuffle {
                if shuffleQueue.isEmpty { resetShuffleQueue() }
                selectedIndex = shuffleQueue.removeFirst()
            } else if selectedIndex > 0 {
                selectedIndex -= 1
            } else {
                pausePlayer()
                self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
                return
            }
            isSetMusic = true
            isPlay = true
            handleRecentInView(index: selectedIndex)
            self.manageTableViewScroll()
            scrollToCurrentTrack()
        } else {
            pausePlayer()
            self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
        }
    }

    @objc func forwardBtnPressed() {
        let queue = PlaybackQueueManager.shared.getQueue()
        if !queue.isEmpty {
            print("Forward: playing next queue track")
            playQueueTrackAtIndex(0)
            return
        }

        if isPlayingQueueTrack {
            isPlayingQueueTrack = false
            currentQueueIndex = nil
            currentQueueTrack = nil
        }
        if let track = track {
            if isShuffle {
                if shuffleQueue.isEmpty { resetShuffleQueue() }
                selectedIndex = shuffleQueue.removeFirst()
            } else if selectedIndex < track.count - 1 {
                selectedIndex += 1
            } else {
                pausePlayer()
                self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
                return
            }
            isSetMusic = true
            isPlay = true
            handleRecentInView(index: selectedIndex)
            self.manageTableViewScroll()
            scrollToCurrentTrack()
        } else {
            pausePlayer()
            self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
        }
    }

    // MARK: - scrollToCurrentTrack (queue-aware)
    private func scrollToCurrentTrack() {
        let queueCount = PlaybackQueueManager.shared.getQueue().count
        let queueRows = queueCount > 0 ? queueCount + 1 : 0
        let indexToScroll = 2 + queueRows + 1 + selectedIndex - (firstTrackList?.count ?? 0)
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
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "LyricPlayViewController") as! LyricPlayViewController
        if isPlayingQueueTrack, let queueTrack = currentQueueTrack {
            vc.currentSong = queueTrack.convertToSongModel()
        } else if let trackItem = track?[safe: selectedIndex] {
            vc.currentSong = trackItem.convertToSongModel()
        }
        vc.imageURl = self.imageURl
        vc.lyricnew = self.lyricSynced
        vc.isSyncedLyrics = self.isSyncedLyrics
        self.present(vc, animated: true)
    }

    @objc func moreInfoBtnClicked() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PlayListViewController") as! PlayListViewController
        if isPlayingQueueTrack, let queueTrack = currentQueueTrack {
            vc.songToSave = queueTrack.convertToSongModel()
        } else if let trackItem = track?[safe: selectedIndex] {
            vc.songToSave = trackItem.convertToSongModel()
        }
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }

    @objc func optionMenuBtnClicked() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PlayerOptionViewController") as! PlayerOptionViewController
        if isPlayingQueueTrack, let queueTrack = currentQueueTrack {
            vc.currentSong = queueTrack.convertToSongModel()
        } else if let trackItem = track?[safe: selectedIndex] {
            vc.currentSong = trackItem.convertToSongModel()
        }
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

// MARK: - UITableViewDelegate, UITableViewDataSource
extension MyMusicPlayerViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { return 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let mainCount = 2
        let trackCount = (tempTrack?.count ?? 0) > 1 ? (tempTrack!.count - 1) : 0
        let queueCount = PlaybackQueueManager.shared.getQueue().count
        let queueRows = queueCount > 0 ? queueCount + 1 : 0
        let totalRows = mainCount + queueRows + (trackCount > 0 ? 1 : 0) + trackCount
        print("Row count: mainCount=\(mainCount), queueRows=\(queueRows), trackCount=\(trackCount), totalRows=\(totalRows)")
        return totalRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let queueCount = PlaybackQueueManager.shared.getQueue().count
        let queueRows = queueCount > 0 ? queueCount + 1 : 0

        // Row 0: Banner Ad
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

        // Row 1: Options
        } else if indexPath.row == 1 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "RecentPlayerOptionCell", for: indexPath) as? RecentPlayerOptionCell else {
                let fallbackCell = UITableViewCell()
                fallbackCell.textLabel?.text = "Options Unavailable"
                fallbackCell.textLabel?.textColor = .white
                fallbackCell.backgroundColor = .clear
                return fallbackCell
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

        // Row 2: "Up Next from Queue" header (only if queue has items)
        } else if indexPath.row == 2 && queueRows > 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell", for: indexPath) as! HeaderCell
            cell.headerLabel.text = "Up Next from Queue"
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            cell.contentView.isUserInteractionEnabled = false
            return cell

        // Rows 3...(2+queueRows-1): Queue tracks
        } else if indexPath.row >= 3 && indexPath.row < 2 + queueRows {
            let queue = PlaybackQueueManager.shared.getQueue()
            let queueIndex = indexPath.row - 3
            if queueIndex >= 0 && queueIndex < queue.count {
                let cell = tableView.dequeueReusableCell(withIdentifier: "MusicListCell", for: indexPath) as! MusicListCell
                cell.selectionStyle = .none
                cell.artCoverImage.layer.cornerRadius = 3
                cell.artCoverImage.layer.masksToBounds = true
                let item = queue[queueIndex]
                cell.trackTitle.text = item.track
                cell.artistName.text = item.artist
                if let url = URL(string: item.artcover ?? "") {
                    cell.artCoverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                    cell.imgBg.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                }
                cell.backgroundColor = .clear
                return cell
            }
            return UITableViewCell()

        // Remaining rows: "Up Next" header + track list
        } else {
            let adjustedRow = indexPath.row - queueRows

            // "Up Next" header
            if adjustedRow == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell", for: indexPath) as! HeaderCell
                cell.headerLabel.text = "Up Next"
                cell.selectionStyle = .none
                cell.backgroundColor = .clear
                cell.contentView.isUserInteractionEnabled = false
                return cell
            }

            // Up Next track rows
            let trackIndex = adjustedRow - 3 + 1
            if trackIndex >= 1 && trackIndex < tempTrack?.count ?? 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "MusicListCell", for: indexPath) as! MusicListCell
                cell.selectionStyle = .none
                cell.artCoverImage.layer.cornerRadius = 3
                cell.artCoverImage.layer.masksToBounds = true
                if let item = tempTrack?[trackIndex] {
                    cell.trackTitle.text = item.trackName
                    cell.artistName.text = item.artistName
                    if let url = item.imageURL {
                        cell.artCoverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                        cell.imgBg.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                    }
                }
                cell.backgroundColor = .clear
                return cell
            }
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let queueCount = PlaybackQueueManager.shared.getQueue().count
        let queueRows = queueCount > 0 ? queueCount + 1 : 0
        tableView.deselectRow(at: indexPath, animated: true)

        guard indexPath.row >= 2 else { return }

        // Ignore queue header
        if indexPath.row == 2 && queueRows > 0 { return }

        // Queue track tapped
        if indexPath.row >= 3 && indexPath.row < 2 + queueRows {
            let queueIndex = indexPath.row - 3
            let queue = PlaybackQueueManager.shared.getQueue()
            guard queueIndex >= 0, let _ = queue[safe: queueIndex] else {
                print("Error: Invalid queue index \(queueIndex)")
                return
            }
            print("Selected queue track at queueIndex: \(queueIndex)")
            playQueueTrackAtIndex(queueIndex)
            DispatchQueue.main.async {
                tableView.reloadData()
                self.manageTableViewScroll()
            }
            return
        }

        // "Up Next" header
        let adjustedRow = indexPath.row - queueRows
        if adjustedRow == 2 { return }

        // Up Next track tapped
        let trackIndex = adjustedRow - 3 + 1
        guard trackIndex >= 1, trackIndex < tempTrack?.count ?? 0 else {
            print("Error: Invalid track index \(trackIndex)")
            return
        }

        isPlayingQueueTrack = false
        currentQueueIndex = nil
        currentQueueTrack = nil

        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
        cell.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
            cell.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
        }) { _ in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                cell.transform = .identity
                cell.isUserInteractionEnabled = true
            }) { _ in
                self.pausePlayer()
                self.selectedIndex = trackIndex
                self.isPlay = true
                self.isSetMusic = true
                self.handleRecentInView(index: self.selectedIndex)
                self.manageTableViewScroll()
                self.scrollToCurrentTrack()
            }
        }
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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.playerDidFinishPlaying(sender:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        if isPlay {
            self.playPauseBtn.setImage(UIImage(named: "ic_pause"), for: .normal)
            self.updateNowPlaying(isPause: false)
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

        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(value: 1, timescale: 1),
            queue: .main
        ) { [weak self] progressTime in
            guard let self = self else { return }
            self.playerSlider.value = Float(progressTime.seconds)
            self.populateLabelWithTime(self.lblStartTime, time: progressTime.seconds)
            self.updateNowPlayingElapsedTime(progressTime.seconds)
        }
    }

    // MARK: - Player Did Finish
    @objc func playerDidFinishPlaying(sender: Notification) {
        print("🏁 Song finished, isRepeat: \(isRepeat), selectedIndex: \(selectedIndex)")

        if let item = sender.object as? AVPlayerItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: item)
        }

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
            return
        }

        // Check queue first
        let queue = PlaybackQueueManager.shared.getQueue()
        if !queue.isEmpty {
            print("Song finished, playing next queue track")
            playQueueTrackAtIndex(0)
            return
        }

        // Otherwise play next Up Next track
        isPlayingQueueTrack = false
        currentQueueIndex = nil
        currentQueueTrack = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self, let track = self.track, self.selectedIndex < track.count - 1 else {
                self?.pausePlayer()
                return
            }
            self.forwardBtnPressed()
        }
    }

    // MARK: - Now Playing
    func setupNowPlaying() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            var nowPlayingInfo = [String: Any]()
            nowPlayingInfo[MPMediaItemPropertyArtist] = self.artistName.text ?? ""
            nowPlayingInfo[MPMediaItemPropertyTitle] = self.trackTitle.text ?? ""
            nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = false
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player?.isPlaying == true ? 1.0 : 0.0
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.currentTime().seconds ?? 0.0
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

    // MARK: - Remote Transport Controls
    func setupRemoteTransportControls() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()

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

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            DispatchQueue.main.async {
                guard !self.isLastTrack() else { return }
                self.pausePlayer()
                self.forwardBtnPressed()
            }
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            DispatchQueue.main.async {
                self.pausePlayer()
                self.backwardBtnPressed()
            }
            return .success
        }

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
        return selectedIndex == track.count - 1 && PlaybackQueueManager.shared.getQueue().isEmpty
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

// MARK: - OptionsViewControllerDelegate
extension MyMusicPlayerViewController: OptionsViewControllerDelegate {
    func didUpdateTrackMetadata() {
        DispatchQueue.main.async {
            self.radioTableView.reloadData()
            self.manageTableViewScroll()
            if let currentTrack = self.track?[safe: self.selectedIndex] {
                self.isAlreadyLiked(track: currentTrack)
                self.isAlreadyDownloaded(track: currentTrack)
                self.isAlreadyBookmarked(track: currentTrack)
            }
        }
    }
}
