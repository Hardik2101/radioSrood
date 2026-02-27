import UIKit
import SWRevealViewController
import Alamofire
import AlamofireImage
import GoogleMobileAds
import StoreKit
import MediaPlayer
import AVKit
import SpotlightLyrics
import AVKit
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

    // MARK: - Queue state (mirrors MusicPlayerViewController)
    var isPlayingQueueTrack: Bool = false
    var currentQueueIndex: Int? = nil
    var currentQueueTrack: Track? = nil

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
        // Queue update observer
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
        NotificationCenter.default.removeObserver(self)
        print("Remove screen")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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

        // Ignore Banner and Options rows
        guard indexPath.row >= 2 else { return }

        if indexPath.row == 2 && queueRows > 0 {
            // "Up Next from Queue" header — ignore
            return
        }

        if indexPath.row >= 3 && indexPath.row < 2 + queueRows {
            // Long press on a queue track
            let queueIndex = indexPath.row - 3
            let queue = PlaybackQueueManager.shared.getQueue()
            guard let queueTrack = queue[safe: queueIndex] else {
                print("Error: No queue track at index \(queueIndex)")
                return
            }
            print("Long press on queue track: \(queueTrack.track ?? "Unknown")")
            presentOptionsViewControllerForTrack(queueTrack)

        } else {
            // Long press on an Up Next track
            let adjustedRow = indexPath.row - queueRows
            if adjustedRow == 2 {
                // "Up Next" header — ignore
                return
            }
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
            print("🎵 Lyric: \(line.text)")
            if vwLyrics.isHidden {
                self.lblLyricsText.text = ""
            } else {
                self.lblLyricsText.text = line.text
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
                    if UIApplication.shared.applicationState == .background {
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

    // MARK: - manageTableViewScroll (updated for queue)
    func manageTableViewScroll() {
        DispatchQueue.main.async {
            self.radioTableView.reloadData()
            self.radioTableView.layoutIfNeeded()
            let trackCount = (self.tempTrack?.count ?? 0) > 1 ? (self.tempTrack!.count - 1) : 0
            let queueCount = PlaybackQueueManager.shared.getQueue().count
            let queueRows = queueCount > 0 ? queueCount + 1 : 0

            var totalHeight: CGFloat = 0
            totalHeight += IAPHandler.shared.isGetPurchase() ? 0 : 65 // Banner
            totalHeight += 90  // Options cell
            totalHeight += queueRows > 0 ? CGFloat(queueRows * 90) : 0 // Queue header + rows
            totalHeight += trackCount > 0 ? 40 : 0  // "Up Next" header
            totalHeight += CGFloat(trackCount * 90)  // Track rows

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

        if isShowOptionList {
            btnDownload.isHidden = false
            btnLike.isHidden = false
        } else {
            btnDownload.isHidden = true
            btnLike.isHidden = true
        }
        isAlreadyDownloaded(track: track)
        isAlreadyLiked(track: track)
        isAlreadyBookmarked(track: track)
        lastIndex = nil

        DataHelper.getLyricsData(artist: track.artistName ?? "", track: track.trackName ?? "") { lyricItem in
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
        if isSetupRemoteTransport {
            isSetupRemoteTransport = false
            self.setupRemoteTransportControls()
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

    // MARK: - Queue Track Playback
    private func playQueueTrackAtIndex(_ index: Int) {
        let queue = PlaybackQueueManager.shared.getQueue()
        guard index >= 0, index < queue.count else {
            print("Error: Invalid queue index \(index)")
            return
        }
        let item = queue[index]
        print("Playing queue track: \(item.track ?? "Unknown") at index: \(index)")

        // Store queue track state
        isPlayingQueueTrack = true
        currentQueueIndex = index
        currentQueueTrack = item

        // Build playback URLs
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

        // Update UI
        if let artcover = item.artcover, let url = URL(string: artcover) {
            artCoverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            bgImageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
        }
        trackTitle.text = item.track
        artistName.text = item.artist

        // Fetch lyrics for queue track
        DataHelper.getLyricsData(artist: item.artist ?? "", track: item.track ?? "") { lyricItem in
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

        // Remove from queue after starting playback
        PlaybackQueueManager.shared.removeFromQueue(at: index)
        print("Queue track \(item.track ?? "Unknown") removed from queue, queue count now: \(PlaybackQueueManager.shared.getQueue().count)")

        // Update currentQueueIndex for next queue track
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
            // Revert to last Up Next track
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
        // Check queue first
        let queue = PlaybackQueueManager.shared.getQueue()
        if !queue.isEmpty {
            print("Forward: playing next queue track")
            playQueueTrackAtIndex(0)
            return
        }

        // Otherwise go to next Up Next track
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
        guard let item = track?[safe: selectedIndex] else { return }
        guard let url = item.file else { return }

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
                DispatchQueue.main.async { self?.circularProgressView.setProgress(Float(progress.fractionCompleted)) }
                if progress.fractionCompleted == 1.0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self?.circularProgressView.setProgress(1.0)
                        self?.circularProgressView.lineWidth = 8
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
        let trackItem: Any?
        if isPlayingQueueTrack, let queueTrack = currentQueueTrack {
            trackItem = queueTrack
        } else {
            trackItem = track?[safe: selectedIndex]
        }
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "LyricPlayViewController") as! LyricPlayViewController
        if let qt = trackItem as? Track {
            vc.currentSong = qt.convertToSongModel()
        } else if let pt = trackItem as? PodcastObject {
            vc.currentSong = pt.convertToSongModel()
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
        if let trackIndex = savedTracks.firstIndex(where: { $0.trackid == songModel.trackid }) {
            savedTracks[trackIndex].isBookMarked = isBookMarked
        } else {
            var newItem = songModel
            newItem.isBookMarked = isBookMarked
            savedTracks.append(newItem)
        }
        UserDefaultsManager.shared.localTracksData = savedTracks
        let message = isBookMarked ? "Successfully added to My Collection" : "Removed from My Collection"
        showToast(message: message, font: .systemFont(ofSize: 12.0))
        DispatchQueue.main.async {
            self.radioTableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
        }
    }

    @objc private func handleIAPPurchase() {
        isPurchaseSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { self.isPurchaseSuccess = false }
        manageTableViewScroll()
    }

    // MARK: - State Helpers
    func isAlreadyDownloaded(track: PodcastObject) {
        let savedTracks = UserDefaultsManager.shared.localTracksData
        let songModel = track.convertToSongModel()
        isDownload = savedTracks.first { $0.isDownload && $0.trackid == songModel.trackid } != nil
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
        if let trackIndex = savedTracks.firstIndex(where: { $0.trackid == songModel.trackid }) {
            savedTracks[trackIndex].isDownload = isDownload
        } else {
            var newItem = songModel
            newItem.isDownload = isDownload
            savedTracks.append(newItem)
        }
        UserDefaultsManager.shared.localTracksData = savedTracks
    }

    func isAlreadyLiked(track: PodcastObject) {
        let savedTracks = UserDefaultsManager.shared.localTracksData
        let songModel = track.convertToSongModel()
        isLike = savedTracks.first { $0.isFav && $0.trackid == songModel.trackid } != nil
        DispatchQueue.main.async {
            self.btnLike.setImage(UIImage(named: self.isLike ? "ic_like_filled" : "ic_like"), for: .normal)
        }
    }

    func configureLike(index: Int) {
        guard let item = track?[safe: index] else { return }
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
    }

    func isAlreadyBookmarked(track: PodcastObject) {
        let savedTracks = UserDefaultsManager.shared.localTracksData
        let songModel = track.convertToSongModel()
        isBookMarked = savedTracks.first { $0.isBookMarked && $0.trackid == songModel.trackid } != nil
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension MyMusicPlayerViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { return 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let mainCount = 2 // Banner + Options
        let trackCount = (tempTrack?.count ?? 0) > 1 ? (tempTrack!.count - 1) : 0
        let queueCount = PlaybackQueueManager.shared.getQueue().count
        let queueRows = queueCount > 0 ? queueCount + 1 : 0 // +1 for header
        let totalRows = mainCount + queueRows + (trackCount > 0 ? 1 : 0) + trackCount // +1 for "Up Next" header
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
            let isBookmarked = savedTracks.first { $0.isBookMarked && $0.trackid == item?.convertToSongModel().trackid } != nil
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

            // Up Next track rows (skip first track at index 0)
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

        // Ignore Banner and Options rows
        guard indexPath.row >= 2 else { return }

        // Ignore headers
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
        print("Selected Up Next track at trackIndex: \(trackIndex)")

        // Clear queue state when playing an Up Next track
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
            }
        }
    }
}

// MARK: - GADAdLoaderDelegate
extension MyMusicPlayerViewController: GADAdLoaderDelegate, GADUnifiedNativeAdLoaderDelegate {
    func loadNativeAd() {
        guard !IAPHandler.shared.isGetPurchase() else { return }
        adLoader = GADAdLoader(adUnitID: GOOGLE_ADMOB_NATIVE,
                               rootViewController: self,
                               adTypes: [.unifiedNative],
                               options: nil)
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

// MARK: - Playback
extension MyMusicPlayerViewController {

    private func playbackURLs(for podcast: PodcastObject?) -> (primary: URL?, fallback: URL?) {
        guard let podcast = podcast else { return (nil, nil) }
        var primaryURL: URL? = nil
        var fallbackURL: URL? = nil
        if let file = podcast.file {
            if file.isFileURL { return (nil, file) }
            if file.pathExtension.lowercased() == "m3u8" { return (file, nil) }
            let baseName = (file.lastPathComponent as NSString).deletingPathExtension
            if let hls = URL(string: hlsSongPath + baseName + ".m3u8") { primaryURL = hls }
            fallbackURL = sanitizeStreamURL(file.absoluteString) ?? file
        }
        return (primaryURL, fallbackURL)
    }

    func play(url: URL, isPlay: Bool = false, fallbackURL: URL? = nil) {
        print("Playing URL: \(url)")
        if let player = player, let timeObserver = timeObserver {
            player.pause()
            player.removeTimeObserver(timeObserver)
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
            self.timeObserver = nil
        }
        hasTriedFallbackForItem = false
        playerItemStatusObserver = nil
        let playerItem = AVPlayerItem(url: url)
        if let fallback = fallbackURL {
            playerItemStatusObserver = playerItem.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
                guard let self = self else { return }
                if item.status == .failed {
                    guard !self.hasTriedFallbackForItem else { return }
                    self.hasTriedFallbackForItem = true
                    print("Primary playback failed, attempting fallback: \(fallback)")
                    DispatchQueue.main.async {
                        let fallbackItem = AVPlayerItem(url: fallback)
                        player?.replaceCurrentItem(with: fallbackItem)
                        self.playerItemStatusObserver = fallbackItem.observe(\.status, options: [.new, .initial]) { [weak self] it, _ in
                            guard let self = self else { return }
                            if it.status == .readyToPlay {
                                DispatchQueue.main.async {
                                    self.playerSlider.maximumValue = Float(player?.currentItem?.asset.duration.seconds ?? 0.0)
                                    self.populateLabelWithTime(self.lblEndTime, time: player?.currentItem?.asset.duration.seconds ?? 0.0)
                                }
                            }
                        }
                        player?.play()
                    }
                } else if item.status == .readyToPlay {
                    DispatchQueue.main.async {
                        self.playerSlider.maximumValue = Float(item.asset.duration.seconds)
                        self.populateLabelWithTime(self.lblEndTime, time: item.asset.duration.seconds)
                    }
                }
            }
        } else {
            playerItemStatusObserver = playerItem.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
                guard let self = self else { return }
                if item.status == .readyToPlay {
                    DispatchQueue.main.async {
                        self.playerSlider.maximumValue = Float(item.asset.duration.seconds)
                        self.populateLabelWithTime(self.lblEndTime, time: item.asset.duration.seconds)
                    }
                }
            }
        }
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
            let subtitleURL = URL(string: "https://lyric.srood.stream/jostojo?artist=Fardin%20Faryad&track=Aziz%20Jan&api_key=arman")
            let parser = try? Subtitles(file: subtitleURL!, encoding: .utf8)
            player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: .main) { [weak self] time in
                guard let self = self else { return }
                if player?.currentItem?.status == .readyToPlay {
                    let currentSeconds = CMTimeGetSeconds(player?.currentTime() ?? .zero)
                    self.showLyric(toTime: currentSeconds)
                }
            }
            player?.play()
            print("Player started for URL: \(url)")
        }
        self.setupNowPlaying()
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying(sender:)),
                                               name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 1), queue: .global()) { [weak self] progressTime in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.playerSlider.value = Float(progressTime.seconds)
                self.populateLabelWithTime(self.lblStartTime, time: progressTime.seconds)
            }
        }
    }

    @objc func playerDidFinishPlaying(sender: Notification) {
        playerSlider.setValue(0, animated: true)
        populateLabelWithTime(self.lblStartTime, time: 0.0)
        player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        if let timeObserver = timeObserver, let player = player {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        if isRepeat {
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
        if let track = track, selectedIndex < track.count - 1 {
            forwardBtnPressed()
        } else {
            print("No more tracks to play")
            pausePlayer()
        }
    }

    func populateLabelWithTime(_ label: UILabel, time: Double) {
        let minutes = Int(time / 60)
        let seconds = Int(time) - minutes * 60
        label.text = String(format: "%02d", minutes) + ":" + String(format: "%02d", seconds)
    }

    @IBAction func pausePressed() {
        if player?.isPlaying ?? true {
            DispatchQueue.main.async { self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal) }
            player?.pause()
            updateNowPlaying(isPause: true)
        } else {
            DispatchQueue.main.async { self.playPauseBtn.setImage(UIImage(named: "ic_pause"), for: .normal) }
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
        if isShuffle { return shuffleQueue.isEmpty }
        guard let track = track else { return false }
        return selectedIndex == track.count - 1 && PlaybackQueueManager.shared.getQueue().isEmpty
    }

    @IBAction func backwardBtnEvent(_ sender: Any) {
        self.pausePlayer()
        self.backwardBtnPressed()
    }

    @IBAction func forwardBtnEvent(_ sender: Any) {
        if isLastTrack() { return }
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
                    guard let mediaArtwork = self.createMediaArtwork(from: image) else { return }
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = mediaArtwork
                    DispatchQueue.main.async { MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo }
                }
            }
        }
    }

    func createMediaArtwork(from image: UIImage) -> MPMediaItemArtwork? {
        guard #available(iOS 10.0, *), let cgImage = image.cgImage else { return nil }
        return MPMediaItemArtwork(boundsSize: image.size) { _ in UIImage(cgImage: cgImage) }
    }

    func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            if let player = player, !player.isPlaying {
                player.play()
                self.playPauseBtn.setImage(UIImage(named: "ic_pause"), for: .normal)
                return .success
            }
            return .commandFailed
        }
        commandCenter.pauseCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            if let player = player, player.isPlaying {
                player.pause()
                self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
                return .success
            }
            return .commandFailed
        }
        commandCenter.nextTrackCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            if player != nil { self.pausePlayer(); self.forwardBtnPressed(); return .success }
            return .commandFailed
        }
        commandCenter.previousTrackCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            if player != nil { self.pausePlayer(); self.backwardBtnPressed(); return .success }
            return .commandFailed
        }
    }

    func pausePlayer() {
        if let player = player, let timeObserver = timeObserver {
            player.pause()
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        self.playerSlider.setValue(0, animated: true)
        self.populateLabelWithTime(self.lblStartTime, time: 0.0)
        player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
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
