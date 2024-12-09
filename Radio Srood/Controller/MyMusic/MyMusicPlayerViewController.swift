
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
   // var player: AVPlayer?
    var isLike = false
    var isRepeat = false
    var timeObserver: Any?
    

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
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItem.Style.plain, target: nil, action: nil)
        radioTableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: 0.1))
        radioTableView.tableFooterView = UIView()
        if let reveal = self.revealViewController(){
            self.view!.addGestureRecognizer(reveal.panGestureRecognizer())
        }
        handleRecentInView(index: self.selectedIndex)
        self.tableBgHeightConstraints.constant = CGFloat((((self.tempTrack?.count ?? 0)-1) * 60)+165)
        loadNativeAd()
        isSetupRemoteTransport = true
        NotificationCenter.default.addObserver(
            self, selector: #selector(RadioViewController.didBecomeActiveNotificationReceived),
            name:NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification"), object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(RadioViewController.playerInterruption(notification:)),
            name:NSNotification.Name(rawValue: "AVAudioSessionInterruptionNotification"), object: nil
        )
        
        radioTableView.register(UINib(nibName: "BannerAdCell", bundle: nil), forCellReuseIdentifier: "BannerAdCell")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        radioTableView.reloadData()
        TabbarVC.available?.miniPlayer.viewCurrentSong.isHidden = true
        NotificationCenter.default.post(name: .MiniPlayerVisibilityChanged, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    deinit {
        //timeObserver = nil
        
        //this removeTimeObserver doing crash when same screen reappear.
//        if let timeObserver = self.timeObserver, let player = player {
//            player.removeTimeObserver(timeObserver)
//        }

        // Additional cleanup tasks
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

    func handleRecentInView(index: Int) {
        self.artCoverImage.layer.cornerRadius = 3
        self.artCoverImage.layer.masksToBounds = true
        if let track = track?[index] {
            //        self.artCoverImage.image = track.image
            //        bgImageView.image = track.image
            if let imageURL = track.imageURL {
                artCoverImage.af_setImage(withURL: imageURL, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                bgImageView.af_setImage(withURL: imageURL, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            }
            self.trackTitle.text = track.trackName
            self.artistName.text = track.artistName
            if isSetMusic {
                isSetMusic = false
                self.play(url: track.file, isPlay: self.isPlay)
            }
            
            AppPlayer.miniPlayerInfo = BasicDetail(
                songImage: track.imageURL?.absoluteString ?? "",
                songNameTitle: track.trackName,
                artistSubtitle: track.artistName,
                musicVC: self
            )
            //config***
        }
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
            self.tableBgHeightConstraints.constant = CGFloat((((self.tempTrack?.count ?? 0)-1) * 60)+165)
            self.radioTableView.reloadData()

            // Check if the selected index is within the bounds of the table view
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
            self.tableBgHeightConstraints.constant = CGFloat((((self.tempTrack?.count ?? 0)-1) * 60)+165)
            self.radioTableView.reloadData()

            // Check if the selected index is within the bounds of the table view
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

    func shareBtnClicked(url: URL) {
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: [])
        vc.modalPresentationStyle = .popover
        if let wPPC = vc.popoverPresentationController {
            wPPC.sourceView = self.view
        }
        self.present(vc, animated: true, completion: nil)
    }

}

extension MyMusicPlayerViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let mainCount = 2
        return mainCount + ((tempTrack?.count ?? 0) - 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
//            if nativeAd != nil {
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
                // Set the banner view frame
                //                bannerView.frame = CGRect(x: 0, y: 0, width: vwAds.frame.width, height: vwAds.frame.height)
                // Remove any existing subviews from vwAds
                
                cell.vwMain.addSubview(bannerView)
                
                // Set the banner view frame
                bannerView.frame = cell.vwMain.bounds

            }
            
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            
            // Load banner ad into the cell's view hierarchy
            
            return cell
//            } else {
//                let cell = tableView.dequeueReusableCell(withIdentifier: "RecentPlayerOptionCell", for: indexPath) as! RecentPlayerOptionCell
//                cell.selectionStyle = .none
//                return cell
//            }
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
                }
                cell.trackTitle.text = item.trackName
                cell.artistName.text = item.artistName
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            break
        case 1:
            break
        default:
            pausePlayer()
            let selectedTrackIndex = (firstTrackList?.count ?? 0) + indexPath.row - 1

            if let track = track, selectedTrackIndex < track.count {
                self.selectedIndex = selectedTrackIndex
                self.isPlay = true
                isSetMusic = true
                handleRecentInView(index: selectedIndex)
                tableBgHeightConstraints.constant = CGFloat((((tempTrack?.count ?? 0)-1) * 60) + 165)
                radioTableView.reloadData()

                let totalRowsInSection = radioTableView.numberOfRows(inSection: 0)

                if selectedTrackIndex < totalRowsInSection {
                    let indexPathToScroll = IndexPath(row: selectedTrackIndex, section: 0)
                    radioTableView.scrollToRow(at: indexPathToScroll, at: .top, animated: true)
                } else {
                    radioTableView.scrollToRow(at: indexPath, at: .top, animated: true)
                }
            } else {
                // Handle the case when the selected index is out of bounds
                print("Invalid selected index")
            }
        }
    }
}

extension MyMusicPlayerViewController: GADAdLoaderDelegate, GADUnifiedNativeAdLoaderDelegate {

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
        guard !IAPHandler.shared.isGetPurchase() else {
            return
        }

        self.nativeAd = nativeAd
        self.tableBgHeightConstraints.constant = CGFloat((((self.tempTrack?.count ?? 0)-1) * 60)+165)
        DispatchQueue.main.async {
            self.radioTableView.reloadData()
        }
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
        self.btnLike.setImage(UIImage(named: "ic_like"), for: .normal)
        self.isLike = false
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
            NotificationCenter.default.removeObserver(self,
                                                      name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                      object: nil)
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
    func isLastTrack() -> Bool {
        guard let track = track else {
            return false
        }
        return selectedIndex == track.count - 1
    }

    @IBAction func backwardBtnEvent(_ sender: Any) {

        /////
        self.pausePlayer()
        self.backwardBtnPressed()
    }

    @IBAction func forwardBtnEvent(_ sender: Any) {
        if isLastTrack() {
            // Disable the forward button or perform any desired action
//            self.btnForward.isEnabled = false
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
                // Create the media artwork asynchronously
                DispatchQueue.global(qos: .background).async {
                    guard let mediaArtwork = self.createMediaArtwork(from: image) else {
                        print("Error creating media artwork")
                        return
                    }
                    
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = mediaArtwork
                    
                    // Update nowPlayingInfo on the main queue
                    DispatchQueue.main.async {
                        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                    }
                }
            } else {
                // Handle case where image is nil
                print("Error: artCoverImage.image is nil")
            }
        }
    }
    
    func createMediaArtwork(from image: UIImage) -> MPMediaItemArtwork? {
        guard let cgImage = image.cgImage else {
            print("Error: Failed to create CGImage from UIImage")
            return nil
        }
        
        return MPMediaItemArtwork(boundsSize: image.size) { _ in
            return UIImage(cgImage: cgImage)
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
        if let timeObserver = timeObserver, let player = player {
            player.removeTimeObserver(timeObserver)
        }
    }

}
