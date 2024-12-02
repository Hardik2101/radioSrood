//
//  MiniPlayerView.swift
//  Radio Srood
//
//  Created by B on 30/11/24.
//  Copyright © 2024 Radio Srood Inc. All rights reserved.
//

import UIKit
import CoreMedia
import AVFoundation

class MiniPlayerView: UIView {
    @IBOutlet weak var imgSong: UIImageView!
    @IBOutlet weak var lblSongName: UILabel!
    @IBOutlet weak var lblPlayerArtist: UILabel!
    @IBOutlet weak var btnPlayPause: UIButton!
    @IBOutlet weak var viewSongProgress: UIProgressView!

    @IBOutlet weak var heightSongVIEW: NSLayoutConstraint!
    @IBOutlet weak var viewCurrentSong: UIView!
    
    // Our custom view from the XIB file
    var view: UIView!
    
    var timeObserver: Any?
    var musicPlayPause: PlayPauseSender?
    var radioPlayPause: PlayPauseSender?
    
    override init(frame: CGRect) {
        super.init(frame: UIScreen.main.bounds)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        xibSetup()
    }
    func xibSetup() {
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        addSubview(view)
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of:self))
        let nib = UINib(nibName: "MiniPlayerView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
    
    @IBAction func actionPlayPause(_ sender: Any) {
        if (player?.isPlaying ?? false){
            player?.pause()
            self.btnPlayPause.setImage(UIImage(named: "ic_play"), for: .normal)
            
        } else {
            player?.play()
            self.btnPlayPause.setImage(UIImage(named: "ic_pause"), for: .normal)
        }
    }
    
    @IBAction func actionOpenSong(_ sender: Any) {
        //UIApplication.shared.keyWindow?.rootViewController ??
        guard let root = (CustomAlertController().topMostController() as? TabbarVC)?.selectedViewController else {
            print("songController is nil")
            return
        }
        guard let vc = AppPlayer.miniPlayerInfo.songController else {
            print("songController is nil")
            return
        }
        
        //presentedViewController == nil &&
        if root.presentedViewController == nil {
            root.present(vc, animated: true)
        } else {
            print("A view controller is already being presented or songController is already presented")
        }
    }
}


extension MiniPlayerView {
    func refreshMiniplayer() {
        self.viewSongProgress.progress = 0.0
        self.lblSongName.text = AppPlayer.miniPlayerInfo.songName
        self.lblPlayerArtist.text = AppPlayer.miniPlayerInfo.artistSongName
        if AppPlayer.miniPlayerInfo.songImage != "" {
            self.imgSong.af_setImage(withURL: URL(string: AppPlayer.miniPlayerInfo.songImage)!, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
        }
        let musicPlay = player?.isPlaying ?? false
        let radioPlay = AppPlayer.radio.isPlaying
        if !musicPlay, !radioPlay {
            self.btnPlayPause.setImage(UIImage(named: "ic_play"), for: .normal)
            self.viewCurrentSong.isHidden = true
            self.heightSongVIEW.constant = 0
            return
        }
        
        self.btnPlayPause.setImage(UIImage(named: "ic_pause"), for: .normal)
        self.viewCurrentSong.isHidden = false
        self.heightSongVIEW.constant = 60
        
        //NotificationCenter.default.removeObserver(self)
        //NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying(sender:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        
        timeObserver = nil
        musicPlayPause = nil
        radioPlayPause = nil
        if let player, musicPlay {
            let totalTime = Float(player.currentItem?.asset.duration.seconds ?? 0.0)
            timeObserver = player.addPeriodicTimeObserver(
                forInterval: CMTime(value: 1, timescale: 1),
                queue: DispatchQueue.global(),
                using: { [weak self] (progressTime) in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.viewSongProgress.progress = ((Float(progressTime.seconds) / totalTime) * 100.0) / 100.0
                    }
                }
            )
            
            musicPlayPause = PlayPauseSender(player: {player})
            musicPlayPause?.onPlaybackStateChange = { nowPlay in
                self.btnPlayPause.setImage(UIImage(named: nowPlay ? "ic_pause" : "ic_play"), for: .normal)
            }
        } else if radioPlay {
            radioPlayPause = PlayPauseSender(player: {AppPlayer.radio})
            radioPlayPause?.onPlaybackStateChange = { nowPlay in
                self.btnPlayPause.setImage(UIImage(named: nowPlay ? "ic_pause" : "ic_play"), for: .normal)
            }
        } else {
            
        }
    }
    
    
//    @objc func playerDidFinishPlaying(sender: Notification) {
//        viewSongProgress.progress = 0.0
//        
//        let musicPlay = player?.isPlaying ?? false
//        //let radioPlay = AppPlayer.radio.isPlaying
//        let current = musicPlay ? player : AppPlayer.radio
//        current?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
//    }
}
