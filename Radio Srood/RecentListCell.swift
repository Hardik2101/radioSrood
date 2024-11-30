
import UIKit
import MediaPlayer
import AVKit
import GoogleMobileAds

class RadioCell: UITableViewCell {

    @IBOutlet weak var artCoverImage: UIImageView!
    @IBOutlet weak var trackTitle: UILabel!
    @IBOutlet weak var artistName: UILabel!
    @IBOutlet weak var currentPlayCounts: UILabel!
    @IBOutlet weak var playPauseBtn: UIButton!
    @IBOutlet weak var shareBtn: UIButton!
    @IBOutlet weak var btnLike: UIButton!
    
    var radioPlayer: AVPlayer {
        get { AppPlayer.radio }
        set {
            AppPlayer.radioURL = radioUrl
            AppPlayer.radio = newValue
        }
    }
    var asset: AVAsset? = nil
    var playerItem: AVPlayerItem!
    var dataHelper: DataHelper!
    var radioUrl: String!
    var isPlaying = false
    weak var presentView: RadioWithRecentViewController?
    var isLike = false

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(RadioCell.didBecomeActiveNotificationReceived),
                                               name:NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification"),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(RadioCell.playerInterruption(notification:)),
                                               name:NSNotification.Name(rawValue: "AVAudioSessionInterruptionNotification"),
                                               object: nil)
        if !isPlaying {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)

                do {
                    try AVAudioSession.sharedInstance().setActive(true)

                } catch let error as NSError {
                    print(error.localizedDescription)
                }
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            self.becomeFirstResponder()
        }
        NotificationCenter.default.addObserver(
            self, selector: #selector(RadioCell.stopPlayer),
            name: .pauseRadio, object: nil
        )
    }

    @objc func stopPlayer() {
        if isPlaying {
            DispatchQueue.main.async {
                self.playPauseBtn.setImage(UIImage(named: "play.png"), for:.normal)
            }
            radioPlayer.pause()
            updateNowPlaying(isPause: true)
            isPlaying = false
        }
    }

    @objc func playerInterruption(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }
        if type == .began {
            radioPlayer.pause()
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
                        /*Radio Already play by other screen */
                        if AppPlayer.radioURL != radioUrl {
                            NotificationCenter.default.post(name: .pauseRadio, object: nil, userInfo: nil)
                        }
                        
                        let playURL = URL(string: self.radioUrl)
                        self.asset = AVAsset(url: playURL!)
                        self.playerItem = AVPlayerItem(url:playURL!)
                        self.playerItem.addObserver(self, forKeyPath: "timedMetadata", options: [], context: nil)
                        self.playerItem.addObserver(self, forKeyPath: "presentationSize", options: [], context: nil)
                        self.radioPlayer = AVPlayer(playerItem: self.playerItem)
                        self.radioPlayer.play()
                        self.setupNowPlaying()
                        self.updateNowPlaying(isPause: true)
                    } else {
                        self.radioPlayer.play()
                    }
                }
            }
        }
    }

    @objc func didBecomeActiveNotificationReceived() {
        updateNowPlaying(isPause: true)
    }

    func makeScreen(_ isPlay: Bool = false) {
        playPauseBtn.setTitle("play", for: .normal)
        setupPlayer()
        stationDidChange(isPlay)
    }

    func setupPlayer () {
        radioPlayer.allowsExternalPlayback = true
        radioPlayer.usesExternalPlaybackWhileExternalScreenIsActive = true
    }

    func stationDidChange(_ isPlay: Bool = false) {
        /*Radio Already play by other screen */
        if AppPlayer.radioURL != radioUrl {
            NotificationCenter.default.post(name: .pauseRadio, object: nil, userInfo: nil)
        }
        if !isPlay {
            radioPlayer.pause()
        }
        let playURL = URL(string: radioUrl)
        asset = AVAsset(url: playURL!)
        playerItem = AVPlayerItem(url: playURL!)
        playerItem.addObserver(self, forKeyPath: "timedMetadata", options: [], context: nil)
        playerItem.addObserver(self, forKeyPath: "presentationSize", options: [], context: nil)
        radioPlayer = AVPlayer(playerItem: playerItem)
        if !isPlay {
            playPauseBtn.setImage(UIImage(named: "play.png"), for:.normal)
            radioPlayer.pause()
        } else {
            playPauseBtn.setImage(UIImage(named: "pause.png"), for:.normal)
            radioPlayer.play()
    //       setupNowPlaying()
        }
        isPlaying = isPlay
    }

    func playPauseback(){
        if isPlaying {
            radioPlayer.pause()
            isPlaying = false
        }else{
            radioPlayer.play()
            isPlaying = true
        }
    }

    @IBAction func pausePressed() {
        if isPlaying {
            DispatchQueue.main.async {
                self.playPauseBtn.setImage(UIImage(named: "play.png"), for:.normal)
            }
            radioPlayer.pause()
            updateNowPlaying(isPause: true)
            isPlaying = false
        } else {
            /*Radio Already play by other screen */
            if AppPlayer.radioURL != radioUrl {
                //.pauseRadio is in stationDidChange
                stationDidChange(true)
            }
            
            DispatchQueue.main.async {
                self.playPauseBtn.setImage(UIImage(named: "pause.png"), for: .normal)
            }
            player = PlayObserver() //killing player before radio
            radioPlayer.play()
            isPlaying = true
            setupNowPlaying()
            updateNowPlaying(isPause: false)
            presentView?.update()
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

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath != "timedMetadata" { return }
        if let data: AVPlayerItem = object as? AVPlayerItem {
            if let dataItem = data.timedMetadata {
                for item in dataItem {
                    let metaArray: Array<Any> = [playerItem?.timedMetadata as Any]
                    print("Total objects in array \(metaArray[0])")
                    let data = item.stringValue
                    if data == nil {
                        trackTitle.text = "metadata not load"
                        artistName.text = "metadata not load"
                        currentPlayCounts.text = "metadata not load"
                    } else {
                        loadRecentListData()
                    }
                }
            }
        }
    }

    func loadRecentListData() {
        dataHelper = DataHelper()
        dataHelper.getRecentListData(completion: { [weak self] resp in
            guard let self = self else { return }
            if let currentSong = resp.value(forKey: "currentTrack") as? NSDictionary {
                if let currentTrack = currentSong.value(forKey: "currentTrack") as? String {
                    self.trackTitle.text = currentTrack
                }
                if let currentArtist = currentSong.value(forKey: "currentArtist") as? String {
                    self.artistName.text = currentArtist
                }
                if let currentPlayCounts = currentSong.value(forKey: "currentPlayCounts") as? Int {
                    self.currentPlayCounts.text = "Plays: \(currentPlayCounts)"
                }
                if let currentArtCover = currentSong.value(forKey: "currentArtCover") as? String, let url = URL(string: currentArtCover) {
                    self.getDataFromUrl(url: url, completion: { [self] (datax, responce, error) in
                        DispatchQueue.main.async {
                            self.artCoverImage.image = UIImage(data: datax!)
                            self.presentView?.bgImageView.image = UIImage(data: datax!)
                            self.updateNowPlaying(isPause: true)
                            self.setupNowPlaying()
                        }
                    })
                }
            }
            self.btnLike.setImage(UIImage(named: "ic_like"), for: .normal)
            self.isLike = false
            self.presentView?.radioData = resp
            self.presentView?.loadCurrentLyricData()
            self.presentView?.loadNativeAd()
            self.presentView?.radioTableView.reloadData()
        })
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

    func getDataFromUrl(url: URL, completion: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> Void) {
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            completion(data, response, error)
        }.resume()
    }

    public func radioStop(){
        radioPlayer.pause()
    }

    @IBAction func share(_ sender:UIButton) {
        let trackName = trackTitle.text ?? "Radio Srood"
        let shareText = String (format: "I am listening to %@ on Radio Srood app! Download the app @ http://radiosrood.com/iOS", trackName)
        var imageArtShare: UIImage!

        if (artCoverImage.image == nil) {
            imageArtShare = UIImage(named:"no_image.jpg")
        } else {
            imageArtShare = artCoverImage.image
        }
        let vc = UIActivityViewController(activityItems: [shareText, imageArtShare], applicationActivities: [])
        vc.modalPresentationStyle = .popover;
        if let wPPC = vc.popoverPresentationController {
            wPPC.sourceView = sender
        }
        presentView?.present(vc, animated: true, completion: nil)
    }

    func setupRemoteTransportControls() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [unowned self] event in
            if !(presentView?.isPrevent ?? false) {
                print("Play command - is playing: \(self.radioPlayer.isPlaying)")
                if !self.radioPlayer.isPlaying {
                    self.radioPlayer.play()
                    return .success
                }
            }
            return .commandFailed
        }

        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if !(presentView?.isPrevent ?? false) {
                print("Pause command - is playing: \(self.radioPlayer.isPlaying)")
                if self.radioPlayer.isPlaying {
                    self.radioPlayer.pause()
                    return .success
                }
            }
            return .commandFailed
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self,
                                                  name:NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification"),
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name:NSNotification.Name(rawValue: "AVAudioSessionInterruptionNotification"),
                                                  object: nil)
    }

}

extension RadioCell : StopPlayerDelegate {

    func stopPlayerInDidDisappear() {
        stopPlayer()
    }

}

class AdViewCell: UITableViewCell {

    @IBOutlet weak var unifiedNativeAdView: GADUnifiedNativeAdView!
    @IBOutlet weak var lblAd: UILabel!
    @IBOutlet weak var bgView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        bgView.layer.cornerRadius = 5
        lblAd.layer.cornerRadius = 3
        // Initialization code
    }

}

class RecentListCell: UITableViewCell {

    @IBOutlet weak var artCoverImage: UIImageView!
    @IBOutlet weak var trackTitle: UILabel!
    @IBOutlet weak var artistName: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        artCoverImage.image = nil
        // Initialization code
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        artCoverImage.image = nil
    }

}

class UpNextCell: UITableViewCell {

    @IBOutlet weak var title: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}

class OptionCell: UITableViewCell {

    @IBOutlet weak var btnLyrics: UIButton!
    @IBOutlet weak var btnShare: UIButton!
    @IBOutlet weak var btnMoreInfo: UIButton!
    @IBOutlet weak var airPlayView: UIView!
    @IBOutlet weak var airPlayBloke: UIView!

    var airPlay = UIView()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpAirPlayButton()
        airPlayBloke.addSubview(airPlay)
        // Initialization code
    }

    func setUpAirPlayButton() {
        airPlay.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        let buttonView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        if #available(iOS 11.0, *) {
            let routePickerView = AVRoutePickerView(frame: buttonView.bounds)
            routePickerView.tintColor = UIColor.white
            routePickerView.activeTintColor = .white
            buttonView.addSubview(routePickerView)
            airPlay.addSubview(buttonView)
        } else {
            let airplayButton = MPVolumeView(frame: buttonView.bounds)
            airplayButton.showsVolumeSlider = false
            buttonView.addSubview(airplayButton)
            airPlay.addSubview(buttonView)
        }
    }

}

class MusicListCell: UITableViewCell {

    @IBOutlet weak var artCoverImage: UIImageView!
    @IBOutlet weak var trackTitle: UILabel!
    @IBOutlet weak var artistName: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        artCoverImage.image = nil
        // Initialization code
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        artCoverImage.image = nil
    }

}
