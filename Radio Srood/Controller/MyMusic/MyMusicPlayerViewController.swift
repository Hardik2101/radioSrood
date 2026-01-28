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
    // KVO observer for player item status (HLS failure detection)
    private var playerItemStatusObserver: NSKeyValueObservation?
    private var hasTriedFallbackForItem: Bool = false
    
    private var lyricSynced: String = ""
    var imageURl: URL?
    var circularProgressView: CircularProgressView!
    private var isPurchaseSuccess: Bool = false
    private var isBookMarked: Bool = false // Replaced isMyMusic with isBookMarked for consistency

    var isShowOptionList: Bool = false
    private var parsedLyrics: [LyricLine] = []
    private var lastIndex: Int? = nil
    
    var shuffleQueue: [Int] = []
    
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
        NotificationCenter.default.removeObserver(self)
        print("Remove screen")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func showLyric(toTime time: TimeInterval) {
        guard !parsedLyrics.isEmpty else { return }
        guard let index = parsedLyrics.firstIndex(where: { $0.time >= time }) else {
            return
        }
        guard lastIndex == nil || index - 1 != lastIndex else {
            return
        }
        if index > 0 {
            let line = parsedLyrics[index - 1]
            lastIndex = index - 1
            print("🎵 Lyric: \(line.text)")
            
            if vwLyrics.isHidden {
                self.lblLyricsText.text = ""
            }else {
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
    func sanitizeStreamURL(_ urlString: String?) -> URL? {
        guard let urlString = urlString else { return nil }

        // Decode percent encoding
        var decoded = urlString.removingPercentEncoding ?? urlString
        
        // If it accidentally includes full https:// inside, extract the last one
        if let range = decoded.range(of: "https://", options: .backwards) {
            decoded = String(decoded[range.lowerBound...])
        }
        
        return URL(string: decoded)
    }

    func resetShuffleQueue() {
        guard let track = track else { return }
        shuffleQueue = Array(0..<track.count).shuffled()
    }

    func handleRecentInView(index: Int) {
        var idx = index
        if isShuffle, let tracks = track {
            if shuffleQueue.isEmpty {
                resetShuffleQueue()
            }
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
        DataHelper.getLyricsData(
            artist: track.artistName ?? "",
            track: track.trackName ?? ""
        ) { lyricItem in

            guard let lyricItem = lyricItem else {
                DispatchQueue.main.async {
                    self.hideLyrics()
                }
                return
            }

            let synced = lyricItem.syncedLyrics.trimmingCharacters(in: .whitespacesAndNewlines)
            let plain  = lyricItem.plainLyrics.trimmingCharacters(in: .whitespacesAndNewlines)

            DispatchQueue.main.async {

                if !synced.isEmpty {
                    // ✅ Prefer synced lyrics
                    self.lyricSynced = synced
                    self.parseLyricSynced()

                    self.showLyrics()
                    self.lblLyricsText.text = ""

                } else if !plain.isEmpty {
                    // ✅ Fallback to plain lyrics
                    self.lyricSynced = plain
                    self.showLyrics()
                    self.lblLyricsText.text = plain

                } else {
                    // ❌ No lyrics at all
                    self.hideLyrics()
                }
            }
        }

        // Prefer HLS (m3u8) then fallback to MP3
        if isSetMusic {
            isSetMusic = false
            // Build primary (HLS) and fallback (MP3) URLs from PodcastObject.file
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

    @objc func backwardBtnPressed() {
        if let track = track {
            if isShuffle {
                // For backward, you may want to keep a history stack if you want true back navigation
                if shuffleQueue.isEmpty {
                    resetShuffleQueue()
                }
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
            let indexToScroll = 2 + selectedIndex - (firstTrackList?.count ?? 0)
            if indexToScroll >= 0 && indexToScroll < radioTableView.numberOfRows(inSection: 0) {
                let indexPathToScroll = IndexPath(row: indexToScroll, section: 0)
                radioTableView.scrollToRow(at: indexPathToScroll, at: .middle, animated: true)
            } else {
                print("Invalid index for scrolling: \(indexToScroll)")
                radioTableView.scrollToRow(at: IndexPath(row: 1, section: 0), at: .top, animated: true)
            }
        } else {
            pausePlayer()
            self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
        }
    }

    @objc func forwardBtnPressed() {
        if let track = track {
            if isShuffle {
                if shuffleQueue.isEmpty {
                    resetShuffleQueue()
                }
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
            let indexToScroll = 2 + selectedIndex - (firstTrackList?.count ?? 0)
            if indexToScroll >= 0 && indexToScroll < radioTableView.numberOfRows(inSection: 0) {
                let indexPathToScroll = IndexPath(row: indexToScroll, section: 0)
                radioTableView.scrollToRow(at: indexPathToScroll, at: .middle, animated: true)
            } else {
                print("Invalid index for scrolling: \(indexToScroll)")
                radioTableView.scrollToRow(at: IndexPath(row: 1, section: 0), at: .top, animated: true)
            }
        } else {
            pausePlayer()
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
                    self?.circularProgressView.setProgress(Float(progress.fractionCompleted))
                }
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
        guard let trackItem = track?[safe: selectedIndex] else {
            print("No track selected for lyrics")
            return
        }
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "LyricPlayViewController") as! LyricPlayViewController
        vc.currentSong = trackItem.convertToSongModel()
        vc.imageURl = self.imageURl
        vc.lyricnew = self.lyricSynced
        self.present(vc, animated: true)
    }

    @objc func moreInfoBtnClicked() {
        guard let trackItem = track?[safe: selectedIndex] else {
            print("Error: No track for more info")
            return
        }
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PlayListViewController") as! PlayListViewController
        vc.songToSave = trackItem.convertToSongModel()
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
    
    @objc func optionMenuBtnClicked() {
        guard let trackItem = track?[safe: selectedIndex] else {
            print("Error: No track for options")
            return
        }
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PlayerOptionViewController") as! PlayerOptionViewController
        vc.currentSong = trackItem.convertToSongModel()
        vc.lyricsNew = self.lyricSynced
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
    
    @objc func addToCollection() {
        guard let trackItem = track?[safe: selectedIndex] else {
            print("Error: No track to add to collection")
            return
        }
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
        print("Bookmark updated for track: \(trackItem.trackName ?? "Unknown"), trackid: \(songModel.trackid), isBookMarked: \(isBookMarked)")
        // Reload only the options cell
        DispatchQueue.main.async {
            self.radioTableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
        }
    }
    
    @objc private func handleIAPPurchase() {
        isPurchaseSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.isPurchaseSuccess = false
        }
        manageTableViewScroll() // Update table height if ads are removed
    }
    
    func isAlreadyDownloaded(track: PodcastObject) {
        let savedTracks = UserDefaultsManager.shared.localTracksData
        let songModel = track.convertToSongModel()
        let isInDownloads = savedTracks.first { $0.isDownload && $0.trackid == songModel.trackid }
        isDownload = isInDownloads != nil
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
        print("Checked download status for track: \(track.trackName ?? "Unknown"), trackid: \(songModel.trackid), isDownload: \(isDownload)")
    }

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
        print("Configured download for track: \(item.trackName ?? "Unknown"), trackid: \(songModel.trackid), isDownload: \(isDownload)")
    }
    
    func isAlreadyLiked(track: PodcastObject) {
        let savedTracks = UserDefaultsManager.shared.localTracksData
        let songModel = track.convertToSongModel()
        let isInFav = savedTracks.first { $0.isFav && $0.trackid == songModel.trackid }
        isLike = isInFav != nil
        DispatchQueue.main.async {
            self.btnLike.setImage(UIImage(named: self.isLike ? "ic_like_filled" : "ic_like"), for: .normal)
        }
        print("Checked like status for track: \(track.trackName ?? "Unknown"), trackid: \(songModel.trackid), isLike: \(isLike)")
    }

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
        print("Configured like for track: \(item.trackName ?? "Unknown"), trackid: \(songModel.trackid), isLike: \(isLike)")
    }

    func isAlreadyBookmarked(track: PodcastObject) {
        let savedTracks = UserDefaultsManager.shared.localTracksData
        let songModel = track.convertToSongModel()
        let isInCollection = savedTracks.first { $0.isBookMarked && $0.trackid == songModel.trackid }
        isBookMarked = isInCollection != nil
        print("Checked bookmark status for track: \(track.trackName ?? "Unknown"), trackid: \(songModel.trackid), isBookMarked: \(isBookMarked)")
    }
}

extension MyMusicPlayerViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let mainCount = 2 // Banner + Options
        let trackCount = (tempTrack?.count ?? 0) > 1 ? (tempTrack!.count - 1) : 0
        let totalRows = mainCount + trackCount
        print("Row count: mainCount=\(mainCount), trackCount=\(trackCount), totalRows=\(totalRows)")
        return totalRows
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
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "RecentPlayerOptionCell", for: indexPath) as? RecentPlayerOptionCell else {
                print("Error: Failed to dequeue RecentPlayerOptionCell")
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
            // Set bookmark button image
            let item = track?[safe: selectedIndex]
            let savedTracks = UserDefaultsManager.shared.localTracksData
            let isBookmarked = savedTracks.first { $0.isBookMarked && $0.trackid == item?.convertToSongModel().trackid } != nil
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
                        let indexToScroll = 2 + self.selectedIndex - (self.firstTrackList?.count ?? 0)
                        if indexToScroll >= 2 && indexToScroll < totalRowsInSection {
                            let indexPathToScroll = IndexPath(row: indexToScroll, section: 0)
                            tableView.scrollToRow(at: indexPathToScroll, at: .middle, animated: true)
                        } else {
                            tableView.scrollToRow(at: IndexPath(row: 1, section: 0), at: .top, animated: true)
                        }
                    } else {
                        print("Invalid selected index: \(selectedTrackIndex)")
                    }
                }
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
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
    // Build primary (HLS) and fallback (MP3) URLs for a PodcastObject
    private func playbackURLs(for podcast: PodcastObject?) -> (primary: URL?, fallback: URL?) {
        guard let podcast = podcast else { return (nil, nil) }
        var primaryURL: URL? = nil
        var fallbackURL: URL? = nil

        // If the file is local, use it as fallback only
        if let file = podcast.file {
            if file.isFileURL {
                fallbackURL = file
                return (nil, fallbackURL)
            }

            // If file itself already points to an HLS playlist
            if file.pathExtension.lowercased() == "m3u8" {
                primaryURL = file
                return (primaryURL, nil)
            }

            // Otherwise assume it's an MP3 URL and construct HLS path using hlsSongPath
            // Use lastPathComponent without extension and append .m3u8
            let last = file.lastPathComponent
            let baseName = (last as NSString).deletingPathExtension
            if let hls = URL(string: hlsSongPath + baseName + ".m3u8") {
                primaryURL = hls
            }

            // Fallback is the original file (MP3) or sanitized URL
            fallbackURL = sanitizeStreamURL(file.absoluteString) ?? file
        }
        return (primaryURL, fallbackURL)
    }
    
    // Main play function with optional fallback URL (HLS primary, MP3 fallback)
    func play(url: URL, isPlay: Bool = false, fallbackURL: URL? = nil) {
        print("Playing URL: \(url)")
        // Ensure previous player is fully cleared
        if let player = player, let timeObserver = timeObserver {
            player.pause()
            player.removeTimeObserver(timeObserver)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
            self.timeObserver = nil
        }
        hasTriedFallbackForItem = false
        // remove previous observer if any
        playerItemStatusObserver = nil
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
                        player?.replaceCurrentItem(with: fallbackItem)
                        // Observe fallback readyToPlay to update UI
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
            // If no fallback, still observe readyToPlay to set duration
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
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying(sender:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
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
                    self.timeObserver = nil
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
        if isShuffle {
            return shuffleQueue.isEmpty
        }
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
            self.timeObserver = nil
        }
        self.playerSlider.setValue(0, animated: true)
        self.populateLabelWithTime(self.lblStartTime, time: 0.0)
        player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
        updateNowPlaying(isPause: true)
    }
}
