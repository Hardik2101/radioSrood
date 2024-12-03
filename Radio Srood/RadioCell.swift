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
        let current = radio.isPlaying
        
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
        configureCurrentPlayingSong()//thisOnly happen
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
                var miniplayerInfo = BasicDetail(radioVC: presentView)
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
