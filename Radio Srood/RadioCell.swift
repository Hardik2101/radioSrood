//
//  RadioCell.swift
//  Radio Srood
//
//  Created by B on 01/12/24.
//  Copyright © 2024 Radio Srood Inc. All rights reserved.
//

import UIKit
import MediaPlayer
import AVKit

class RadioCell: UITableViewCell {
    
    @IBOutlet weak var artCoverImage: UIImageView!
    @IBOutlet weak var trackTitle: UILabel!
    @IBOutlet weak var artistName: UILabel!
    @IBOutlet weak var currentPlayCounts: UILabel!
    @IBOutlet weak var playPauseBtn: UIButton!
    @IBOutlet weak var shareBtn: UIButton!
    @IBOutlet weak var btnLike: UIButton!
    
    var radioPlayer: RadioObserver {
        get { radio }
        set {
            AppPlayer.radioURL = radioUrl
            radio = newValue
        }
    }
    var asset: AVAsset? = nil
    var playerItem: AVPlayerItem!
    var dataHelper: DataHelper!
    var radioUrl: String!
    var isPlaying = false
    weak var presentView: RadioWithRecentViewController?
    var isLike = false
    var radioMiniPlayerInfo: BasicDetail?
    private var isSkeletonVisible = false
    private var shimmerTimer: Timer?
    private var shimmerBlocks: [UIView] = []
    private var shimmerAlphaIncreasing = true
    private var shimmerProgress: CGFloat = 0.0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        NotificationCenter.default.addObserver(
            self, selector: #selector(RadioCell.didBecomeActiveNotificationReceived),
            name:NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(RadioCell.playerInterruption(notification:)),
            name:NSNotification.Name(rawValue: "AVAudioSessionInterruptionNotification"),
            object: nil
        )
        
        if !isPlaying {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            self.becomeFirstResponder()
        }
        NotificationCenter.default.addObserver(
            self, selector: #selector(changeRadioState),
            name: .radioDidPlay, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(changeRadioState),
            name: .radioDidPause, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(RadioCell.stopPlayer),
            name: .pauseRadio, object: nil
        )
    }
    

    override func layoutSubviews() {
        super.layoutSubviews()
        guard isSkeletonVisible else { return }

        viewWithTag(9999)?.removeFromSuperview()

        let overlay = UIView(frame: contentView.bounds)
        overlay.tag = 9999
        overlay.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.clipsToBounds = true
        contentView.addSubview(overlay)

        contentView.layoutIfNeeded()

        let imgSize: CGFloat = min(contentView.bounds.width - 32, contentView.bounds.height - 80)
        let imgFrame = CGRect(
            x: (contentView.bounds.width - imgSize) / 2,
            y: 16,
            width: imgSize,
            height: imgSize
        )

        let labelY = imgFrame.maxY + 16
        let titleWidth = contentView.bounds.width * 0.60
        let titleFrame = CGRect(
            x: (contentView.bounds.width - titleWidth) / 2,
            y: labelY,
            width: titleWidth,
            height: 14
        )

        let artistWidth = contentView.bounds.width * 0.40
        let artistFrame = CGRect(
            x: (contentView.bounds.width - artistWidth) / 2,
            y: labelY + 22,
            width: artistWidth,
            height: 11
        )

        // ✅ Button centered below labels
        let btnFrame = contentView.convert(playPauseBtn.frame, from: playPauseBtn.superview)
        let centeredBtnFrame = CGRect(
            x: (contentView.bounds.width - btnFrame.width) / 2,
            y: artistFrame.maxY + 20,
            width: btnFrame.width,
            height: btnFrame.height
        )

        let frames: [(CGRect, CGFloat)] = [
            (imgFrame, 6),
            (titleFrame, 5),
            (artistFrame, 4),
            (centeredBtnFrame, centeredBtnFrame.width / 2),
        ]

        var blocks: [(UIView, CGFloat)] = []

        for (frame, radius) in frames {
            let base = UIView(frame: frame)
            base.backgroundColor = UIColor(white: 0.20, alpha: 1.0)
            base.layer.cornerRadius = radius
            base.layer.masksToBounds = true
            overlay.addSubview(base)
            blocks.append((base, frame.width))
        }

        // ✅ Dispatch AFTER run loop commits the layer tree
        DispatchQueue.main.async {
            for (i, (base, width)) in blocks.enumerated() {
                self.addSkeletonShimmer(to: base, width: width, index: i)
            }
        }
    }

    private func addSkeletonShimmer(to base: UIView, width: CGFloat, index: Int) {
        // Remove any existing shimmer
        base.layer.sublayers?.filter { $0.name == "shimmerGradient" }.forEach { $0.removeFromSuperlayer() }

        let gradientLayer = CAGradientLayer()
        gradientLayer.name = "shimmerGradient"
        gradientLayer.frame = CGRect(x: 0, y: 0, width: width, height: base.frame.height)
        gradientLayer.colors = [
            UIColor(white: 0.20, alpha: 1.0).cgColor,
            UIColor(white: 0.55, alpha: 1.0).cgColor,
            UIColor(white: 0.20, alpha: 1.0).cgColor,
        ]
        gradientLayer.locations  = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint   = CGPoint(x: 1, y: 0.5)
        base.layer.addSublayer(gradientLayer)

        // ✅ Animate the gradient startPoint/endPoint — most reliable way
        let startAnim = CABasicAnimation(keyPath: "startPoint")
        startAnim.fromValue = CGPoint(x: -1.0, y: 0.5)
        startAnim.toValue   = CGPoint(x: 1.0, y: 0.5)

        let endAnim = CABasicAnimation(keyPath: "endPoint")
        endAnim.fromValue = CGPoint(x: 0.0, y: 0.5)
        endAnim.toValue   = CGPoint(x: 2.0, y: 0.5)

        let group = CAAnimationGroup()
        group.animations    = [startAnim, endAnim]
        group.duration      = 1.3
        group.repeatCount   = .infinity
        group.beginTime     = CACurrentMediaTime() + Double(index) * 0.15
        group.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        group.isRemovedOnCompletion = false
        group.fillMode      = .forwards

        gradientLayer.add(group, forKey: "shimmer")
    }


    private func startShimmerTimer() {
        shimmerTimer?.invalidate()
        shimmerAlphaIncreasing = true

        // Set all blocks to base color first
        for block in shimmerBlocks {
            block.backgroundColor = UIColor(white: 0.20, alpha: 1.0)
        }

        shimmerTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.tickShimmer()
            }
        }
        RunLoop.main.add(shimmerTimer!, forMode: .common) // ✅ .common keeps it running during scrolling
    }
    private func tickShimmer() {
        let speed: CGFloat = 0.018
        if shimmerAlphaIncreasing {
            shimmerProgress += speed
            if shimmerProgress >= 1.0 {
                shimmerProgress = 1.0
                shimmerAlphaIncreasing = false
            }
        } else {
            shimmerProgress -= speed
            if shimmerProgress <= 0.0 {
                shimmerProgress = 0.0
                shimmerAlphaIncreasing = true
            }
        }

        // ✅ Interpolate between dark (0.20) and bright (0.55)
        let brightness = 0.20 + (shimmerProgress * 0.35)
        for block in shimmerBlocks {
            block.backgroundColor = UIColor(white: brightness, alpha: 1.0)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(
            self, name: NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification"), object: nil
        )
        NotificationCenter.default.removeObserver(
            self, name: NSNotification.Name(rawValue: "AVAudioSessionInterruptionNotification"), object: nil
        )
        NotificationCenter.default.removeObserver(
            self, name: .radioDidPlay, object: nil
        )
        NotificationCenter.default.removeObserver(
            self, name: .radioDidPause, object: nil
        )
//        NotificationCenter.default.removeObserver(
//            self, name: .pauseRadio, object: nil
//        )
    }
    
    @objc func changeRadioState() {
        let current = radio.isPlaying &&  AppPlayer.radioURL == radioUrl
        
        isPlaying = current
        DispatchQueue.main.async {
            self.playPauseBtn.setImage(UIImage(named: current ? "pause.png" : "play.png"), for:.normal)
        }
        updateNowPlaying(isPause: !current)
    }
    
    @objc func stopPlayer() {
        if isPlaying {
            isPlaying = false
            radioPlayer.pause()
            DispatchQueue.main.async {
                self.playPauseBtn.setImage(UIImage(named: "play.png"), for:.normal)
            }
            updateNowPlaying(isPause: true)
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
            return
        } else if type != .ended {
            return
        }
            
        //Only when type == .ended
        guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
            return
        }
        let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
        if !options.contains(.shouldResume) { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            if UIApplication.shared.applicationState != .background {
                self.radioPlayer.play()
                configureCurrentPlayingSong()
                return
            }
            
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
            self.radioPlayer = RadioObserver(playerItem: self.playerItem)
            self.radioPlayer.play()
            self.setupNowPlaying()
            self.updateNowPlaying(isPause: true)
            
            self.configureCurrentPlayingSong()
        }
    }
    
    @objc func didBecomeActiveNotificationReceived() {
        updateNowPlaying(isPause: true)
    }
    
    func configureCurrentPlayingSong() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AppPlayer.miniPlayerInfo = self.radioMiniPlayerInfo ?? BasicDetail(radioVC: self.presentView)
            //config***
        }
        
        //(self.tabBarController as? TabbarVC)?.miniPlayer.refreshMiniplayer()
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
        radioPlayer = RadioObserver(playerItem: playerItem)
        if !isPlay {
            playPauseBtn.setImage(UIImage(named: "play.png"), for:.normal)
            radioPlayer.pause()
        } else {
            playPauseBtn.setImage(UIImage(named: "pause.png"), for:.normal)
            radioPlayer.play()
            //setupNowPlaying()
            configureCurrentPlayingSong()
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
            configureCurrentPlayingSong()
        }
    }
    // Add these two methods to RadioCell class

    func showSkeleton() {
        isSkeletonVisible = true
        setNeedsLayout()
        layoutIfNeeded()
    }

    func hideSkeleton() {
        isSkeletonVisible = false
        viewWithTag(9999)?.removeFromSuperview()
    }

    @IBAction func pausePressed() {
        if isPlaying {
            DispatchQueue.main.async {
                self.playPauseBtn.setImage(UIImage(named: "play.png"), for:.normal)
            }
            radioPlayer.pause()
            updateNowPlaying(isPause: true)
            isPlaying = false
            return
        }
        
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
        configureCurrentPlayingSong()
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
        //super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
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
                var miniplayerInfo = BasicDetail(radioVC: self.presentView)
                if let currentTrack = currentSong.value(forKey: "currentTrack") as? String {
                    self.trackTitle.text = currentTrack
                    miniplayerInfo.songNameTitle = currentTrack
                }
                if let currentArtist = currentSong.value(forKey: "currentArtist") as? String {
                    self.artistName.text = currentArtist
                    miniplayerInfo.artistSubtitle = currentArtist
                }
                if let currentPlayCounts = currentSong.value(forKey: "currentPlayCounts") as? Int {
                    self.currentPlayCounts.text = "Plays: \(currentPlayCounts)"
                }
                if let currentArtCover = currentSong.value(forKey: "currentArtCover") as? String, let url = URL(string: currentArtCover) {
                    miniplayerInfo.songImage = currentArtCover
                    self.getDataFromUrl(url: url, completion: { [self] (datax, responce, error) in
                        DispatchQueue.main.async {
                            self.artCoverImage.image = UIImage(data: datax!)
                            self.presentView?.bgImageView.image = UIImage(data: datax!)
                            self.updateNowPlaying(isPause: true)
                            self.setupNowPlaying()
                        }
                    })
                }
                self.radioMiniPlayerInfo = miniplayerInfo
                
                if AppPlayer.miniPlayerInfo.radioVC != nil {
                    self.configureCurrentPlayingSong()
                } else {
                    print("song changed but radio stoped.")
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
    
    func setUI(currentSong: NSDictionary) -> URL? {
        var miniplayerInfo = BasicDetail(radioVC: presentView)
        if let currentTrack = currentSong.value(forKey: "currentTrack") as? String {
            trackTitle.text = currentTrack
            miniplayerInfo.songNameTitle = currentTrack
        }
        if let currentArtist = currentSong.value(forKey: "currentArtist") as? String {
            artistName.text = currentArtist
            miniplayerInfo.artistSubtitle = currentArtist
        }
        if let currentPlayCounts = currentSong.value(forKey: "currentPlayCounts") as? Int {
            self.currentPlayCounts.text = "Plays: \(currentPlayCounts)"
        }
        if let currentArtCover = currentSong.value(forKey: "currentArtCover") as? String, let url = URL(string: currentArtCover) {
            artCoverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            miniplayerInfo.songImage = currentArtCover
            self.radioMiniPlayerInfo = miniplayerInfo
            return url
        }
        self.radioMiniPlayerInfo = miniplayerInfo
        return nil
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
            
            guard let image = self.artCoverImage.image else {
                // Handle case where image is nil
                print("Error: artCoverImage.image is nil")
                return
            }
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
                    configureCurrentPlayingSong()
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
}


extension RadioCell : StopPlayerDelegate {
    func stopPlayerInDidDisappear() {
        stopPlayer()
    }
}
