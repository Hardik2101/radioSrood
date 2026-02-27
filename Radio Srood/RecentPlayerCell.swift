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
    var isLike = false
    var isRepeat = false
    var timeObserver: Any?

    // MARK: - Cell Reuse Cleanup
    override func prepareForReuse() {
        super.prepareForReuse()
        // FIX: Clean up player observers when cell is reused to prevent ghost observers
        cleanupObservers()
    }

    // MARK: - Observer Cleanup
    private func cleanupObservers() {
        if let obs = timeObserver {
            player?.removeTimeObserver(obs)
            timeObserver = nil
        }
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }

    // MARK: - Play
    func play(url: URL, isPlay: Bool = false) {
        // FIX: Always clean up previous observers before starting new playback
        cleanupObservers()

        let playerItem = AVPlayerItem(url: url)
        player = PlayObserver(playerItem: playerItem)

        self.playerSlider.minimumValue = 0.0
        self.playerSlider.maximumValue = 0.0   // FIX: start at 0 — real value set once readyToPlay
        self.playerSlider.value = 0.0
        populateLabelWithTime(self.lblStartTime, time: 0.0)
        populateLabelWithTime(self.lblEndTime, time: 0.0)
        player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)

        // FIX: observe item status to set duration once stream is ready
        playerItem.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
            guard let self = self else { return }
            if item.status == .readyToPlay {
                DispatchQueue.main.async {
                    let dur = item.asset.duration.seconds
                    guard dur > 0, !dur.isNaN, !dur.isInfinite else { return }
                    self.playerSlider.maximumValue = Float(dur)
                    self.populateLabelWithTime(self.lblEndTime, time: dur)
                    // FIX: update NowPlaying with real duration once known
                    self.refreshNowPlayingDuration(dur)
                }
            }
        }

        if isPlay {
            self.playPauseBtn.setImage(UIImage(named: "ic_pause"), for: .normal)
            updateNowPlaying(isPause: false)
            player?.play()
        } else {
            self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
            updateNowPlaying(isPause: true)
            player?.pause()
        }

        self.btnLike.setImage(UIImage(named: "ic_like"), for: .normal)
        self.isLike = false
        self.setupNowPlaying()

        // FIX: register end-of-item on the specific playerItem — not nil (which catches ALL items)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying(sender:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        // FIX: time observer on main queue — avoids nested DispatchQueue.main.async
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(value: 1, timescale: 1),
            queue: .main
        ) { [weak self] progressTime in
            guard let self = self else { return }
            self.playerSlider.value = Float(progressTime.seconds)
            self.populateLabelWithTime(self.lblStartTime, time: progressTime.seconds)
            // FIX: keep lock screen elapsed time updated
            self.updateNowPlayingElapsedTime(progressTime.seconds)
        }
    }

    // MARK: - Player Did Finish — FIXED
    @objc func playerDidFinishPlaying(sender: Notification) {
        // FIX: remove observer for this exact item — prevents double fires
        if let item = sender.object as? AVPlayerItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: item)
        }
        // FIX: remove time observer on finish
        if let obs = timeObserver {
            player?.removeTimeObserver(obs)
            timeObserver = nil
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
            // FIX: small delay so AVPlayer state settles before VC loads next track
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }
                self.forwardViaPresenter()
            }
        }
    }

    // MARK: - Presenter Helpers
    private func forwardViaPresenter() {
        if let vc = presentView as? RecentPlayerViewController { vc.forwardBtnPressed() }
        else if let vc = presentView as? MyMusicPlayerViewController { vc.forwardBtnPressed() }
        else if let vc = presentView as? MusicPlayerViewController { vc.forwardBtnPressed() }
    }

    private func backwardViaPresenter() {
        if let vc = presentView as? RecentPlayerViewController { vc.backwardBtnPressed() }
        else if let vc = presentView as? MyMusicPlayerViewController { vc.backwardBtnPressed() }
        else if let vc = presentView as? MusicPlayerViewController { vc.backwardBtnPressed() }
    }

    // MARK: - Now Playing — FIXED
    func setupNowPlaying() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            var nowPlayingInfo = [String: Any]()
            nowPlayingInfo[MPMediaItemPropertyArtist] = self.artistName.text ?? ""
            nowPlayingInfo[MPMediaItemPropertyTitle] = self.trackTitle.text ?? ""
            nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = false
            // FIX: include playback rate and elapsed time from the start
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player?.isPlaying == true ? 1.0 : 0.0
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.currentTime().seconds ?? 0.0
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

    // FIX: update duration once the stream is ready — called from KVO readyToPlay
    private func refreshNowPlayingDuration(_ duration: Double) {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPMediaItemPropertyPlaybackDuration] = duration
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // FIX: lightweight elapsed-time update every second
    private func updateNowPlayingElapsedTime(_ elapsed: Double) {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed
        info[MPNowPlayingInfoPropertyPlaybackRate] = player?.isPlaying == true ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func updateNowPlaying(isPause: Bool) {
        // FIX: create dict if nil — avoids silent failure before setupNowPlaying has run
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPause ? 0.0 : 1.0
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.currentTime().seconds ?? 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    // MARK: - Remote Transport Controls
    // FIX: setupRemoteTransportControls() REMOVED from this cell entirely.
    // Remote controls must be owned by the view controller, not by a reusable cell.
    // Each VC (MusicPlayerViewController, MyMusicPlayerViewController,
    // RecentPlayerViewController) sets up its own command center in viewDidLoad.
    // Having a cell register command center handlers causes:
    //   - Handlers stacking on every cell reuse
    //   - Handlers firing after the cell is off-screen or deallocated
    //   - Conflicts with the VC's own handlers

    // MARK: - IBActions
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
    }

    @IBAction func repeatBtnPressed(_ sender: Any) {
        isRepeat = !isRepeat
        let image = UIImage(named: "ic_repeat")?.withRenderingMode(.alwaysTemplate)
        self.btnRepeat.setImage(image, for: .normal)
        self.btnRepeat.tintColor = isRepeat ? .red : .white
    }

    @IBAction func backwardBtnEvent(_ sender: Any) {
        self.pausePlayer()
        backwardViaPresenter()
    }

    @IBAction func forwardBtnEvent(_ sender: Any) {
        self.pausePlayer()
        forwardViaPresenter()
    }

    // MARK: - Helpers
    func populateLabelWithTime(_ label: UILabel, time: Double) {
        guard !time.isNaN && !time.isInfinite else {
            label.text = "--:--"
            return
        }
        let t = Int(max(0, time))
        label.text = String(format: "%02d:%02d", t / 60, t % 60)
    }

    func pausePlayer() {
        cleanupObservers()
        player?.pause()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.playerSlider.setValue(0, animated: true)
            self.populateLabelWithTime(self.lblStartTime, time: 0.0)
            self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
        }
        player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        updateNowPlaying(isPause: true)
    }

    // MARK: - Deinit
    deinit {
        cleanupObservers()
        // FIX: do NOT call endReceivingRemoteControlEvents or clear nowPlayingInfo here —
        // the cell does not own remote controls. The owning VC handles that in its own deinit.
        print("RecentPlayerCell deinit")
    }
}

// MARK: - RecentPlayerOptionCell
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
    }

    func setUpAirPlayButton() {
        airPlay.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        let buttonView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        if #available(iOS 11.0, *) {
            let routePickerView = AVRoutePickerView(frame: buttonView.bounds)
            routePickerView.tintColor = .white
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
        let imageName = isBookMarked ? "ic_bookmark_fill" : "ic_bookmark"
        btnAddtoCollection.setImage(UIImage(named: imageName), for: .normal)
    }
}
