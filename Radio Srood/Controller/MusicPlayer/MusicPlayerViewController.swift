
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

protocol MusicPlayerViewControllerDelegate : AnyObject{
    func dismissMusicPlayer()
}

private struct LyricLine {
    let time: TimeInterval
    let text: String
}

class MusicPlayerViewController: UIViewController, GADBannerViewDelegate,AdsAPIViewDelegate {
    
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

    var bannerAdViews: [GADBannerView] = []
    var imageURl: URL?
    var isMyMusic = false
    var playerListTapCount = 0

    var forwardButtonTapCount = 0
    private var parsedLyrics: [LyricLine] = []

//    var adsView: AdsAPIView?

    var isPlayerListTap = false
    var songCounter = 0
    
    private var lyricSynced: String = ""

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
      //  self.view!.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        loadNativeAd()
        prepareView()
        isSetupRemoteTransport = true
        vwDownloadProgress.isHidden = true
        vwDownloadProgress.setProgress(0.0, animated: false)
        NotificationCenter.default.addObserver(
            self, selector: #selector(RadioViewController.didBecomeActiveNotificationReceived),
            name:NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification"),
            object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(RadioViewController.playerInterruption(notification:)),
            name:NSNotification.Name(rawValue: "AVAudioSessionInterruptionNotification"),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(audioChanged),
            name: .musicDidPlay, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(audioChanged),
            name: .musicDidPause, object: nil
        )
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleIAPPurchase), name: .PurchaseSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleIAPPurchase1), name: .aaaaaaaaaa, object: nil)

        
        radioTableView.register(UINib(nibName: "BannerAdCell", bundle: nil), forCellReuseIdentifier: "BannerAdCell")
        radioTableView.register(UINib(nibName: "HeaderCell", bundle: nil), forCellReuseIdentifier: "HeaderCell")
        radioTableView.translatesAutoresizingMaskIntoConstraints = false
        radioTableView.isScrollEnabled = false
        radioTableView.rowHeight = UITableView.automaticDimension
        radioTableView.estimatedRowHeight = 90
        setupCircularProgressView()

//        adsView?.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        radioTableView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
            self.navigationController?.navigationBar.shadowImage = UIImage()
            self.navigationController?.navigationBar.isTranslucent = true
        }
        TabbarVC.available?.miniPlayer.miniplayer(hide: true)
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
        NotificationCenter.default.removeObserver(
            self, name:NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification"),
            object: nil)
        NotificationCenter.default.removeObserver(
            self, name:NSNotification.Name(rawValue: "AVAudioSessionInterruptionNotification"),
            object: nil)
        NotificationCenter.default.removeObserver(
            self, name: .musicDidPlay, object: nil
        )
        NotificationCenter.default.removeObserver(
            self, name: .musicDidPause, object: nil
        )
        NotificationCenter.default.removeObserver(self)
        print("Remove screen")
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
            
            let mainCount = 2 // Banner + Options
            let trackCount = max((self.tempTrack?.count ?? 0) - 1, 0)
            let queueCount = PlaybackQueueManager.shared.getQueue().count
            let queueRows = queueCount > 0 ? queueCount + 1 : 0
            let totalRows = mainCount + queueRows + 1 + trackCount // Banner, Options, Queue, "Up Next", Tracks
            
            // Adjust height based on row types
            var totalHeight: CGFloat = 0
            totalHeight += IAPHandler.shared.isGetPurchase() ? 0 : 65 // Banner height
            totalHeight += 90 // Options cell height
            totalHeight += queueRows > 0 ? CGFloat(queueRows * 90) : 0 // Queue rows
            totalHeight += 40 // "Up Next" header
            totalHeight += CGFloat(trackCount * 90) // Tracks
            
            self.tableBgHeightConstraints.constant = totalHeight
            print("TableView content height: \(totalHeight), totalRows: \(totalRows), queueCount: \(queueCount)")
        }
    }



    
    func prepareView() {
        switch homeHeader {
        case .featured:       loadFeaturedDataItems()
        case .hotTrackes:    loadNewReleaseData()
        case .currentRadio:   break
        case .trending:       loadTrendingPlaylistData()
        case .popularTracks:  loadPopularPlaylistData()
        case .playlists:      loadPlaylistData()
        case .featuredArtist: loadFeaturedArtistData()
        case .myPlaylist:     break
        case .recentlyPlayed: break
        case .todayTopPic:
            loadTodayTopPicData()
        case .recentlyAdded:
            loadRecentlyAddedDetailedData()
        }
    }
    
//    func loadBannerAds() {
//            guard !IAPHandler.shared.isGetPurchase() else {
//                return
//            }
//
//            let adView1 = GADBannerView(adSize: kGADAdSizeBanner)
//            adView1.adUnitID = GOOGLE_ADMOB_ForMusicPlayer
//            adView1.rootViewController = self
//            adView1.delegate = self
//            adView1.load(GADRequest())
//
//
//            bannerAdViews = [adView1]
//        }

    
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
    
    private func loadNewReleaseData() {
        dataHelper = DataHelper()
        dataHelper.getNewReleaseData { [weak self] resp in
            guard let self = self else { return }
            if let resp = resp {
                self.track = resp.newRelease.first(where: { $0.id == self.groupID})?.tracks
                print("tracks======1", self.track)
                print("tracks======2", self.groupID)
                print("tracks======3", resp.newRelease.first(where: { $0.id == self.groupID}))
                print("Available playlistIDs from API:")
                for playlist in resp.newRelease {
                    print("playlistID:", playlist.id)
                }

                self.tempTrack = self.track
                self.isSetMusic = true
                self.isPlay = true
                self.handleRecentInView(index: self.selectedIndex)
                self.manageTableViewScroll()            }
        }
    }
    
    private func loadTodayTopPicData() {
        
        dataHelper = DataHelper()
        
        // Debug log to confirm correct groupID
        print("🚨 loadTodayTopPicData() called with groupID =", self.groupID)
        
        dataHelper.getTodayTopPicDetailed { [weak self] resp in
            guard let self = self else { return }
            
            // Clear any previous data first
            self.track = []
            self.tempTrack = []
            
            if let resp = resp {
                print("📥 Received API response for TodayTopPic")

                self.track = resp.todayTopPick.first(where: { $0.playlistID == self.groupID })?.tracks
                self.tempTrack = self.track
                
                // Debug logs
                print("🎵 Matched Tracks:", self.track ?? [])
                print("📀 Matching Playlist Object:", resp.todayTopPick.first(where: { $0.playlistID == self.groupID }))
                print("🎯 Current groupID:", self.groupID)
                print("📚 All playlistIDs from API:")
                for playlist in resp.todayTopPick {
                    print("🆔 \(playlist.playlistID)")
                }

                // Update flags
                self.isSetMusic = true
                self.isPlay = true
                
                // Update UI
                self.handleRecentInView(index: self.selectedIndex)
                self.manageTableViewScroll()
            }
        }
    }
    
    func loadRecentlyAddedDetailedData() {
        
        dataHelper = DataHelper()
        
        dataHelper.getRecentlyAddedDataDetailed { [weak self] resp in
            guard let self = self else { return }
            if let resp = resp {
                self.track = resp.recentlyAddedPlayListDetailed.first(where: { $0.playlistID == self.groupID})?.tracks
                self.tempTrack = self.track
                self.isSetMusic = true
                self.isPlay = true
                self.handleRecentInView(index: self.selectedIndex)
                self.manageTableViewScroll()            }
        }
    }
    
    private func loadFeaturedDataItems() {
        dataHelper = DataHelper()
        dataHelper.getFeaturedArtistSponserdDetailsData { [weak self] resp in
            guard let self = self else { return }
            if let resp = resp {
                self.track = resp.featuredData.first(where: { $0.fDid == self.groupID})?.featuredItem
                self.tempTrack = self.track
                self.isSetMusic = true
                self.isPlay = true
                self.handleRecentInView(index: self.selectedIndex)
                self.manageTableViewScroll()
            }
        }
    }
    
//    private func loadSponserData() {
//        dataHelper = DataHelper()
//        dataHelper.getFeaturedArtistSponserdData { [weak self] (resp: NewSponserModel?) in
//            guard let self = self else { return }
//            if let resp = resp {
//                // Find the first FeaturedTop with a matching featuredSongID
//                if let featuredTop = resp.featuredTop.first(where: { $0.featuredSongID == self.groupID }) {
//                    if let featuredItem = featuredTop.featuredItem {
//                        // Assuming Track and FeaturedItem are compatible
//                        self.track = [featuredItem] // Create a single-item array
//                    } else {
//                        self.track = [] // No featured item, initialize as empty array
//                    }
//
//                    self.tempTrack = self.track
//                    self.isSetMusic = true
//                    self.isPlay = true
//                    self.handleRecentInView(index: self.selectedIndex)
//                    
//                    // Update UI constraints
//                    self.tableBgHeightConstraints.constant = CGFloat(((self.tempTrack?.count ?? 0) * 60) + 165)
//                    self.radioTableView.reloadData()
//                } else {
//                    // Handle the case where no matching featured item is found
//                    self.track = []
//                    self.tempTrack = []
//                    self.isSetMusic = false
//                    self.isPlay = false
//                    self.tableBgHeightConstraints.constant = 165 // Default height
//                    self.radioTableView.reloadData()
//                }
//            }
//        }
//    }

    private func loadTrendingPlaylistData() {
        dataHelper = DataHelper()
        dataHelper.getTrendingPlaylistData { [weak self] resp in
            guard let self = self else { return }
            if let resp = resp {
                self.track = resp.trendingTracks.first(where: { $0.id == self.groupID})?.tracks
                self.tempTrack = self.track
                self.isSetMusic = true
                self.isPlay = true
                self.handleRecentInView(index: self.selectedIndex)
                self.manageTableViewScroll()
            }
        }
    }
    
    private func loadPopularPlaylistData() {
        dataHelper = DataHelper()
        dataHelper.getPopularPlaylistData { [weak self] resp in
            guard let self = self else { return }
            if let resp = resp {
                self.track = resp.popularTracks.first(where: { $0.id == self.groupID})?.tracks
                self.tempTrack = self.track
                self.isSetMusic = true
                self.isPlay = true
                self.handleRecentInView(index: self.selectedIndex)
                self.manageTableViewScroll()
            }
        }
    }
    
    private func loadPlaylistData() {
        dataHelper = DataHelper()
        dataHelper.getPlaylistData { [weak self] resp in
            guard let self = self else { return }
            if let resp = resp {
                self.track = resp.trendingPlaylist.first(where: { $0.id == self.groupID})?.tracks
                self.tempTrack = self.track
                self.isSetMusic = true
                self.isPlay = true
                self.handleRecentInView(index: self.selectedIndex)
                self.manageTableViewScroll()
            }
        }
    }
    
    private func loadFeaturedArtistData() {
        dataHelper = DataHelper()
        dataHelper.getFeaturedArtistData { [weak self] resp in
            guard let self = self else { return }
            if let resp = resp {
                self.track = resp.rSroodFeaturedArtistData.first(where: { $0.id == self.groupID})?.tracks
                self.tempTrack = self.track
                self.isSetMusic = true
                self.isPlay = true
                self.handleRecentInView(index: self.selectedIndex)
                self.manageTableViewScroll()            }
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

    func handleRecentInView(index: Int) {
        self.artCoverImage.layer.cornerRadius = 3
        self.artCoverImage.layer.masksToBounds = true
        if let item = track?[index] {
            if let url = URL(string: item.artcover ?? "" ?? "") {
                self.artCoverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                self.bgImageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "b1.png"))
                imageURl = url
            }
            self.trackTitle.text = item.track
            self.artistName.text = item.artist
            self.isAlreadyLiked(track: item)
            self.isAlreadyDownloaded(track: item)
            self.configureRecentlyPlayed(index: self.selectedIndex)
            lastIndex = nil
            
            DataHelper.getLyricsData(artist: item.artist ?? "", track: item.track ?? "") { lyricItem in
                if let lyricItem = lyricItem {
                    print("✅ Artist: \(lyricItem.artistName)")
                    print("✅ Track: \(lyricItem.trackName)")
                    print("✅ Synced Lyrics Path: \(lyricItem.syncedLyrics)")
                    self.lyricSynced = lyricItem.syncedLyrics
                    self.parseLyricSynced()
                } else {
                    print("⚠️ No lyrics found.")
                    self.lyricSynced = ""
                }

                if self.lyricSynced.isEmpty {
                    self.heightView.constant = 0
                    self.viewLyrics.isHidden = true
                    self.parser = nil
                } else {
                    self.heightView.constant = 40
                    self.viewLyrics.isHidden = false
                    self.lblLyrics.text = ""

//                    let fullLyricURL = "\(lyricsURL)\(self.lyricSynced)"
//                    guard let url = URL(string: fullLyricURL), !fullLyricURL.isEmpty else {
//                        print("🚫 Invalid or empty lyrics URL: \(fullLyricURL)")
//                        return
//                    }
//
//                    do {
//                        let data = try Data(contentsOf: url)
//                        guard let lyricsString = String(data: data, encoding: .utf8)?.emptyToNil() else {
//                            print("🈳 Lyrics content is empty")
//                            return
//                        }
//                        self.parser = LyricsParser(lyrics: lyricsString)
//                    } catch {
//                        print("❌ Failed to load synced lyrics: \(error.localizedDescription)")
//                    }
                }
            }

            if let urlString = item.mediaPath?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: songPath + urlString) {
                if isSetMusic {
                    isSetMusic = false
                    self.play(url: url, isPlay: self.isPlay)
                }
                if isSetupRemoteTransport {
                    isSetupRemoteTransport = false
                    self.setupRemoteTransportControls()
                }
            }
            
            AppPlayer.miniPlayerInfo = BasicDetail(
                songImage: item.artcover ?? "",
                songNameTitle: item.track ?? "",
                artistSubtitle: item.artist ?? "",
                musicVC: self
            )
            //config***
        }
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
            self.lblLyrics.text = line.text
            lastIndex = index - 1
            print("🎵 \(line.text)")
        }
    }

    
    @objc func lyricsBtnClicked() {
    
        if let track = track {
            if self.lyricSynced != ""{
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "LyricPlayViewController") as! LyricPlayViewController
//                vc.lyricsUrl = "\(lyricsURL)\(track[selectedIndex].lyric_synced ?? "")"
                vc.currentSong = track[selectedIndex].convertToSongModel()
                vc.imageURl = self.imageURl
                vc.lyricnew = self.lyricSynced
                self.present(vc, animated: true)
            } else {
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "LyricPlayViewController") as! LyricPlayViewController
//                vc.lyricsUrl = "\(lyricsURL)\(track[selectedIndex].lyric_synced ?? "")"
                vc.currentSong = track[selectedIndex].convertToSongModel()
                vc.imageURl = self.imageURl
                vc.lyricnew = self.lyricSynced
                self.present(vc, animated: true)

            }
        }
    }
    
    @objc func optionMenuBtnClicked() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PlayerOptionViewController") as! PlayerOptionViewController

        if let track = track {
            vc.currentSong = track[selectedIndex].convertToSongModel()
        }
        vc.track = track?[selectedIndex]
        vc.lyricsNew = self.lyricSynced
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
    
    @objc func addToCollection() {
//        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PlayListViewController") as! PlayListViewController
        
        isMyMusic = !isMyMusic
        
//        if isMyMusic {
//            showToast(message: "Successfully add in My Collection", font: .systemFont(ofSize: 12.0))
//        } else {
//            showToast(message: "Remove from my collection", font: .systemFont(ofSize: 12.0))
//        }

        let item = track?[selectedIndex].convertToSongModel()
        var savedTracks = UserDefaultsManager.shared.localTracksData
        let trackIndex = savedTracks.firstIndex(where: {$0.trackid == item?.trackid})
        if let trackIndex = trackIndex{
            savedTracks[trackIndex].isBookMarked = !savedTracks[trackIndex].isBookMarked
            
            if savedTracks[trackIndex].isBookMarked {
                showToast(message: "Successfully add in My Collection", font: .systemFont(ofSize: 12.0))
            } else {
                showToast(message: "Remove from my collection", font: .systemFont(ofSize: 12.0))
            }

        }
        else{
            let newItem = item
            newItem?.isBookMarked = true
            savedTracks.append(newItem ?? SongModel())
        }
        UserDefaultsManager.shared.localTracksData = savedTracks
        radioTableView.reloadData()
//        showToast(message: "Successfully add in My Collection", font: .systemFont(ofSize: 12.0))

        
        //        vc.delegate = self
//        vc.modalPresentationStyle = .fullScreen

    }
    @objc func moreInfoBtnClicked() {
//        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MoreInfoViewController") as! MoreInfoViewController
//        if let track = track {
//            vc.track = track[selectedIndex]
//        }
//        self.present(vc, animated: true, completion: nil)
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PlayListViewController") as! PlayListViewController
        vc.songToSave = track?[selectedIndex].convertToSongModel() ?? SongModel()
//        vc.delegate = self
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)

    }
    
    @objc func backwardBtnPressed() {
        if let track = track, selectedIndex > 0 {
            selectedIndex -= 1
            isSetMusic = true
            isPlay = true
            handleRecentInView(index: selectedIndex)
            self.manageTableViewScroll()
            // Scroll to the selected song to make it visible
            let indexPathToScroll = IndexPath(row: 2 + selectedIndex - (firstTrackList?.count ?? 0), section: 0)
            radioTableView.scrollToRow(at: indexPathToScroll, at: .top, animated: true)
        } else {
            player?.pause()
            self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
        }
    }
    
    @objc func forwardBtnPressed() {
        if let track = track, selectedIndex < track.count - 1 {
            // Increment the selected index
            selectedIndex += 1
            isSetMusic = true
            isPlay = true
            handleRecentInView(index: selectedIndex)
            
            // Increase the song counter
            songCounter += 1
            
            // Check if it's time to display the ad
            if songCounter % 6 == 0 {
                if IAPHandler.shared.isGetPurchase() {
                    // Pause the player
                    player?.pause()
                    
                    // Show AdsAPIView
                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "AdsAPIView") as! AdsAPIView
                    vc.modalPresentationStyle = .fullScreen
                    self.present(vc, animated: true)
                } else {
                    // Continue playing the next song
                    playNextSong()
                }
            } else {
                // Continue playing the next song
                playNextSong()
            }
            
        } else {
            // Handle when there are no more songs
            player?.pause()
            self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
        }
    }


    @objc func forwardBtnPressed1() {
        if let track = track, selectedIndex < track.count - 1 {
            // Increment the selected index
            selectedIndex += 1
            isSetMusic = true
            isPlay = true
            handleRecentInView(index: selectedIndex)
            
            // Check if an ad should be played
            if shouldPlayAd() {
                // Pause the player
                player?.pause()
                
                // Show AdsAPIView
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "AdsAPIView") as! AdsAPIView
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true)
            } else {
                // Continue playing the next song
                playNextSong()
            }
        } else {
            // Handle when there are no more songs
            player?.pause()
            self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
        }
    }


    // Check if an ad should be played (for example, every second click)
    private func shouldPlayAd() -> Bool {
        // Implement your logic here
        // For example, play ad every second click
        return selectedIndex % 6 == 0
    }
    
    func adsPlaybackDidFinish() {
        // Dismiss AdsAPIView when the ad finishes
        dismiss(animated: true) {
            // Play the next song after dismissing the AdsAPIView

//            self.playNextSong()
        }
    }
    
    private func playNextSong() {
        // Continue playing the next song
        if let track = track, selectedIndex < track.count - 1 {
            let nextSongIndexPath = IndexPath(row: selectedIndex + 1, section: 0)
            radioTableView.scrollToRow(at: nextSongIndexPath, at: .top, animated: true)
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
    
    @IBAction func actionLyrics(_ sender: Any) {
        if let track = track {
            if self.lyricSynced != ""{
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "LyricPlayViewController") as! LyricPlayViewController
//                vc.lyricsUrl = "\(lyricsURL)\(track[selectedIndex].lyric_synced ?? "")"
                vc.currentSong = track[selectedIndex].convertToSongModel()
                vc.imageURl = self.imageURl
                vc.lyricnew = self.lyricSynced
                self.present(vc, animated: true)
            } else {
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "LyricPlayViewController") as! LyricPlayViewController
//                vc.lyricsUrl = "\(lyricsURL)\(track[selectedIndex].lyric_synced ?? "")"
                vc.currentSong = track[selectedIndex].convertToSongModel()
                vc.imageURl = self.imageURl
                vc.lyricnew = self.lyricSynced
                self.present(vc, animated: true)

            }
        }
    }
    
    @IBAction func actionClose(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @objc private func handleIAPPurchase() {
        isPurchaseSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: {
            self.isPurchaseSuccess = false
        })
    }
    
    @objc private func handleIAPPurchase1() {
        print("ahsahksajkshajkhsahsa")
    }


    private func shouldPlayerListPressed() -> Bool {
        return playerListTapCount >= 6
    }

    
    private func shouldPlayAdForwardBtnPressed() -> Bool {
        // Implement your logic here
        // For example, play ad every second click
//        return selectedIndex % 2 == 0
        return forwardButtonTapCount >= 6
    }
    

    @IBAction func clickOn_btnDownload(_ sender: Any) {
        let purchase = IAPHandler.shared.isGetPurchase()

        if purchase || self.isPurchaseSuccess {
            if let currentTrack = track?[selectedIndex] {
                let urlString = currentTrack.mediaPath?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                guard let mediaPathInfo = urlString,
                      let url = URL(string: songPath + mediaPathInfo) else {
                    return
                }

                let name = url.lastPathComponent
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let destinationURL = documentsURL.appendingPathComponent(name)

                // UI: Replace button with progress view
                btnDownload.isHidden = true
                vwProgress.isHidden = false
                circularProgressView.setProgress(0)
                circularProgressView.isHidden = false

                // Start download
                AF.download(url, to: { _, _ in
                    return (destinationURL, [.removePreviousFile, .createIntermediateDirectories])
                })
                .downloadProgress { progress in
                    DispatchQueue.main.async {
                        self.circularProgressView.setProgress(Float(CGFloat(Float(progress.fractionCompleted))))
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
                                self.configureDownload(index: self.selectedIndex)
                                let image = UIImage(systemName: "checkmark.circle.fill")?.withRenderingMode(.alwaysTemplate)
                                self.btnDownload.setImage(image, for: .normal)
                                self.btnDownload.tintColor = .systemGreen
                                self.btnDownload.layer.cornerRadius = 15
                                self.btnDownload.layer.borderColor = UIColor.systemGreen.cgColor
                                self.btnDownload.layer.borderWidth = 2
                                self.btnDownload.clipsToBounds = true
                                self.btnDownload.isUserInteractionEnabled = false

                            }
                        }
                    }

                }
                .response { response in
                    if let destinationURL = response.fileURL {
                        print("File downloaded to: \(destinationURL)")
                    }
                }

                // Save cover
                UserDefaults.standard.set(currentTrack.artcover, forKey: "\(url.deletingPathExtension().lastPathComponent)")
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

extension MusicPlayerViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 // Single section
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let mainCount = 2 // Banner + Options
        let trackCount = max((tempTrack?.count ?? 0) - 1, 0) // Ensure non-negative
        let queueCount = PlaybackQueueManager.shared.getQueue().count
        let queueRows = queueCount > 0 ? queueCount + 1 : 0 // Queue items + "Queue Up Next"
        let totalRows = mainCount + queueRows + 1 + trackCount // Banner, Options, Queue, "Up Next", Tracks
        print("Row count: mainCount=\(mainCount), queueRows=\(queueRows), trackCount=\(trackCount), total=\(totalRows)")
        return totalRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let queueCount = PlaybackQueueManager.shared.getQueue().count
        let queueRows = queueCount > 0 ? queueCount + 1 : 0 // Queue items + "Queue Up Next"
        
        print("Configuring cell for row: \(indexPath.row), queueCount: \(queueCount), queueRows: \(queueRows)")
        
        if indexPath.row == 0 {
            // Banner ad
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
            }
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            let bannerView = GADBannerView(adSize: kGADAdSizeBanner)
            bannerView.adUnitID = GOOGLE_ADMOB_ForMusicPlayer
            bannerView.rootViewController = self
            bannerView.delegate = self
            bannerView.load(GADRequest())
            bannerView.frame = cell.vwMain.bounds
            cell.vwMain.addSubview(bannerView)
            return cell
        } else if indexPath.row == 1 {
            // Options cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecentPlayerOptionCell", for: indexPath) as! RecentPlayerOptionCell
            cell.selectionStyle = .none
            cell.btnLyrics.addTarget(self, action: #selector(lyricsBtnClicked), for: .touchUpInside)
            cell.btnMoreInfo.addTarget(self, action: #selector(moreInfoBtnClicked), for: .touchUpInside)
            cell.btnOption.addTarget(self, action: #selector(optionMenuBtnClicked), for: .touchUpInside)
            cell.btnAddtoCollection.addTarget(self, action: #selector(addToCollection), for: .touchUpInside)
            let item = track?[selectedIndex].convertToSongModel()
            var savedTracks = UserDefaultsManager.shared.localTracksData
            let trackIndex = savedTracks.firstIndex(where: { $0.trackid == item?.trackid })
            let imageName = savedTracks[trackIndex ?? 0].isBookMarked ?? false ? "ic_bookmark_fill" : "ic_bookmark"
            cell.btnAddtoCollection.setImage(UIImage(named: imageName), for: .normal)
            return cell
        } else if indexPath.row == 2 && queueRows > 0 {
            // "Queue Up Next" cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell", for: indexPath) as! HeaderCell
            cell.headerLabel.text = "Queue Up Next (\(queueCount) items)"
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            cell.contentView.isUserInteractionEnabled = false
            return cell
        } else if indexPath.row >= 2 && indexPath.row < 2 + queueRows {
            // Queue items
            let queue = PlaybackQueueManager.shared.getQueue()
            let queueIndex = indexPath.row - 3
            print("Queue item at row: \(indexPath.row), queueIndex: \(queueIndex), queue.count: \(queue.count)")
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
            print("Error: Invalid queue index \(queueIndex)")
            return UITableViewCell() // Fallback
        } else {
            // "Up Next" and tracks
            let adjustedRow = indexPath.row - queueRows
            print("Main content at row: \(indexPath.row), adjustedRow: \(adjustedRow), tempTrack.count: \(tempTrack?.count ?? 0)")
            if adjustedRow == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell", for: indexPath) as! HeaderCell
                cell.headerLabel.text = "Up Next"
                cell.selectionStyle = .none
                cell.backgroundColor = .clear
                cell.contentView.isUserInteractionEnabled = false
                return cell
            } else {
                let trackIndex = (adjustedRow + 1) - 2
                if trackIndex >= 0 && trackIndex < tempTrack?.count ?? 0 {
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
                print("Error: Invalid track index \(trackIndex)")
                return UITableViewCell() // Fallback
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let queueCount = PlaybackQueueManager.shared.getQueue().count
        let queueRows = queueCount > 0 ? queueCount + 1 : 0
        
        if indexPath.row >= 2 && indexPath.row < 2 + queueRows && indexPath.row != 2 {
            // Queue item selection
            let queue = PlaybackQueueManager.shared.getQueue()
            let queueIndex = indexPath.row - 3
            print("Selecting queue item at row: \(indexPath.row), queueIndex: \(queueIndex)")
            if queueIndex >= 0 && queueIndex < queue.count {
                let selectedTrack = queue[queueIndex]
                print("Selected queue item: \(selectedTrack.track ?? "")")
                selectedIndex = 0
                track = [selectedTrack]
                isSetMusic = true
                isPlay = true
                handleRecentInView(index: 0)
                PlaybackQueueManager.shared.removeFromQueue(at: queueIndex) // Updated line
                manageTableViewScroll()
            } else {
                print("Error: Invalid queue index \(queueIndex)")
            }
        } else if indexPath.row >= 2 + queueRows {
            // Main content selection
            pausePlayer()
            let adjustedRow = indexPath.row - queueRows
            let selectedTrackIndex = (firstTrackList?.count ?? 0) + adjustedRow - 1
            print("Selecting main item at row: \(indexPath.row), adjustedRow: \(adjustedRow), selectedTrackIndex: \(selectedTrackIndex)")
            if let track = track, selectedTrackIndex >= 0 && selectedTrackIndex < track.count {
                self.selectedIndex = selectedTrackIndex
                self.isPlay = true
                isSetMusic = true
                handleRecentInView(index: selectedIndex)
                manageTableViewScroll()
                playerListTapCount += 1
                if shouldPlayerListPressed() {
                    isPlayerListTap = true
                    playerListTapCount = 0
                    if !IAPHandler.shared.isGetPurchase() {
                        player?.pause()
                        let vc = storyboard?.instantiateViewController(withIdentifier: "AdsAPIView") as! AdsAPIView
                        vc.modalPresentationStyle = .fullScreen
                        self.present(vc, animated: true)
                    }
                } else {
                    let numberOfVisibleRows = radioTableView.indexPathsForVisibleRows?.count ?? 0
                    if selectedTrackIndex < numberOfVisibleRows {
                        let indexPathToScroll = IndexPath(row: selectedTrackIndex, section: 0)
                        radioTableView.scrollToRow(at: indexPathToScroll, at: .top, animated: true)
                    } else {
                        print("Invalid selected index: \(selectedTrackIndex)")
                    }
                }
            } else {
                print("Error: Invalid selected track index \(selectedTrackIndex)")
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
extension MusicPlayerViewController: GADAdLoaderDelegate, GADUnifiedNativeAdLoaderDelegate {
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
        self.manageTableViewScroll()    }
    
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: GADRequestError) {
        print("\(adLoader) failed with error: \(error.localizedDescription)")
    }
}


extension MusicPlayerViewController {
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
            let subtitleURL = URL(string: "https://lyric.srood.stream/jostojo?artist=Fardin%20Faryad&track=Aziz%20Jan&api_key=arman")//URL(fileURLWithPath: subtitleFile!)
            let parser = try? Subtitles(file: subtitleURL!, encoding: .utf8)
            player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: .main) { [weak self] time in
                guard let self = self else { return }
                if player?.currentItem?.status == .readyToPlay {
                    let currentSeconds = CMTimeGetSeconds(player?.currentTime() ?? .zero)
                    self.showLyric(toTime: currentSeconds)
                }
            }
            player?.play()
        }
       // self.btnLike.setImage(UIImage(named: "ic_like"), for: .normal)
       // self.isLike = false
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
        
        // Increase the song counter
        songCounter += 1
        
        // Check if it's time to display the ad
        if songCounter % 5 == 0 {
            if !IAPHandler.shared.isGetPurchase() {
                displayAdsView()
            } else {
                continuePlaying()
            }
            
        } else {
            // Continue playing if it's not time to display the ad
            continuePlaying()
        }
    }

    func displayAdsView() {
        if !IAPHandler.shared.isGetPurchase() {
            // Pause the player and present AdsAPIView only if isGwrPurchase is false
            player?.pause()
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "AdsAPIView") as! AdsAPIView
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        }
    }

    func continuePlaying() {
        if isRepeat {
            player?.play()
        } else if isPlayerListTap {
            player?.play()
        } else {
            print("debug: MusicPlayerViewController / \(#function)")
            NotificationCenter.default.removeObserver(
                self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil
            )
            if let track = track, selectedIndex < track.count-1 {
                if let timeObserver = timeObserver {
                    if player != nil {
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

    @objc func audioChanged() {
        if player?.isPlaying ?? false {
            self.playPauseBtn.setImage(UIImage(named: "ic_pause"), for: .normal)
        } else {
            self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
        }
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
        configureLike(index: self.selectedIndex)
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
        if isLastTrack() {
            return
        }

        self.pausePlayer()
        self.backwardBtnPressed()
    }
    
    func isLastTrack() -> Bool {
        guard let track = track else {
            return false
        }
        return selectedIndex == track.count - 1
    }



    @IBAction func forwardBtnEvent(_ sender: Any) {
        if isLastTrack() {
            return
        }

        isPlayerListTap = false
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
        if let timeObserver = timeObserver, player != nil {
            player?.removeTimeObserver(timeObserver)
        }
    }

}


extension MusicPlayerViewController{
    func isAlreadyLiked(track : Track){
        let savedTracks = UserDefaultsManager.shared.localTracksData
        let isInFav = savedTracks.filter({$0.isFav && track.trackid == $0.trackid})
        if isInFav.count > 0{
            isLike = true
        }
        else{
            isLike = false
        }
        if isLike {
            btnLike.setImage(UIImage(named: "ic_like_filled"), for: .normal)
        } else {
            btnLike.setImage(UIImage(named: "ic_like"), for: .normal)
        }
    }
    
    
    func isAlreadyDownloaded(track : Track){
        let savedTracks = UserDefaultsManager.shared.localTracksData
        let isInFav = savedTracks.filter({$0.isDownload && track.trackid == $0.trackid})
        if isInFav.count > 0{
            isDownload = true
        }
        else{
            isDownload = false
        }
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
    
    func configureLike(index : Int){
        if let item = track?[index] {
            var savedTracks = UserDefaultsManager.shared.localTracksData
            let trackIndex = savedTracks.firstIndex(where: {$0.trackid == item.trackid})
            if let trackIndex = trackIndex{
                savedTracks[trackIndex].isFav = isLike
            }
            else{
                let newItem = item.convertToSongModel()
                newItem.isFav = true
                savedTracks.append(newItem)
            }
            UserDefaultsManager.shared.localTracksData = savedTracks
        }
    }
    
    func configureDownload(index : Int){
        if let item = track?[index] {
            var savedTracks = UserDefaultsManager.shared.localTracksData
            let trackIndex = savedTracks.firstIndex(where: {$0.trackid == item.trackid})
            if let trackIndex = trackIndex{
                savedTracks[trackIndex].isDownload = isDownload
            }
            else{
                let newItem = item.convertToSongModel()
                newItem.isDownload = true
                savedTracks.append(newItem)
            }
            UserDefaultsManager.shared.localTracksData = savedTracks
        }
    }
    
    
    func configureRecentlyPlayed(index: Int) {
        if let item = track?[index] {
            var savedTracks = UserDefaultsManager.shared.localTracksData
            let trackIndex = savedTracks.firstIndex { $0.trackid == item.trackid }

            if let trackIndex = trackIndex {
                // Track already exists, update properties as needed
                savedTracks[trackIndex].isRecentlyPlayed = true
            } else {
                // Track is not in the list, add it with isRecentlyPlayed set to true
                let newItem = item.convertToSongModel()
                newItem.isRecentlyPlayed = true
                savedTracks.append(newItem)
            }

            UserDefaultsManager.shared.localTracksData = savedTracks
        }
    }

}

