
import UIKit
import MediaPlayer
import AVKit

class RecentPlayerCell: UITableViewCell {

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

    weak var presentView: UIViewController?
   // var player: AVPlayer?
    var isLike = false
    var isRepeat = false
    var timeObserver: Any?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

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
        if isRepeat {
            player?.play()
        } else {
            NotificationCenter.default.removeObserver(self,
                                                      name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                      object: nil)
            if let timeObserver = timeObserver {
                player?.removeTimeObserver(timeObserver)
            }
            if let presentView = presentView as? RecentPlayerViewController {
                presentView.forwardBtnPressed()
            }
            if let presentView = presentView as? MyMusicPlayerViewController {
                presentView.forwardBtnPressed()
            }
            if let presentView = presentView as? MusicPlayerViewController {
                presentView.forwardBtnPressed()
            }
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

    @IBAction func backwardBtnEvent(_ sender: Any) {
        self.pausePlayer()
        if let presentView = self.presentView as? RecentPlayerViewController {
            presentView.backwardBtnPressed()
        }
        if let presentView = self.presentView as? MyMusicPlayerViewController {
            presentView.backwardBtnPressed()
        }
        if let presentView = self.presentView as? MusicPlayerViewController {
            presentView.backwardBtnPressed()
        }
    }

    @IBAction func forwardBtnEvent(_ sender: Any) {
        self.pausePlayer()
        if let presentView = self.presentView as? RecentPlayerViewController {
            presentView.forwardBtnPressed()
        }
        if let presentView = self.presentView as? MyMusicPlayerViewController {
            presentView.forwardBtnPressed()
        }
        if let presentView = self.presentView as? MusicPlayerViewController {
            presentView.forwardBtnPressed()
        }
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
                if let presentView = self.presentView as? RecentPlayerViewController {
                    presentView.forwardBtnPressed()
                }
                if let presentView = self.presentView as? MyMusicPlayerViewController {
                    presentView.forwardBtnPressed()
                }
                if let presentView = self.presentView as? MusicPlayerViewController {
                    presentView.forwardBtnPressed()
                }
                return .success
            }
            return .commandFailed
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            if player != nil {
                self.pausePlayer()
                if let presentView = self.presentView as? RecentPlayerViewController {
                    presentView.backwardBtnPressed()
                }
                if let presentView = self.presentView as? MyMusicPlayerViewController {
                    presentView.backwardBtnPressed()
                }
                if let presentView = self.presentView as? MusicPlayerViewController {
                    presentView.backwardBtnPressed()
                }
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
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
    }

    deinit {
        UIApplication.shared.endReceivingRemoteControlEvents()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [:]
        NotificationCenter.default.removeObserver(self)
    }

}

class RecentPlayerOptionCell: UITableViewCell {

    @IBOutlet weak var btnOption: UIButton!
    @IBOutlet weak var btnLyrics: UIButton!
    @IBOutlet weak var airPlayView: UIView!
    @IBOutlet weak var airPlayBloke: UIView!
    @IBOutlet weak var btnMoreInfo: UIButton!
    
    @IBOutlet weak var btnAddtoCollection: UIButton!
    var airPlay = UIView()

    override func awakeFromNib() {
        super.awakeFromNib()
        setUpAirPlayButton()
        airPlayBloke.addSubview(airPlay)
        
//        btnAddtoCollection.imageView?.image = UIImage(named: "ic_like_filled")
        
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
//            self.btnAddtoCollection.imageView?.image = UIImage(named: "ic_like_info")
//
//        })
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
    
    func updateAddToCollectionButtonImage(isBookMarked: Bool) {
        let imageName = isBookMarked ? "ic_like_filled" : "ic_like_info"
        btnAddtoCollection.setImage(UIImage(named: imageName), for: .normal)
    }
}

