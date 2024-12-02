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
    
    @IBOutlet weak var viewCurrentSong: UIView!
    
    // Our custom view from the XIB file
    var view: UIView!
    
    var timeObserver: Any?
    
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
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(audioChanged),
            name: .radioDidPlay, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(audioChanged),
            name: .radioDidPause, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(audioChanged),
            name: .musicDidPlay, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(audioChanged),
            name: .musicDidPause, object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(
            self, name: .radioDidPlay, object: nil
        )
        NotificationCenter.default.removeObserver(
            self, name: .radioDidPause, object: nil
        )
        NotificationCenter.default.removeObserver(
            self, name: .musicDidPlay, object: nil
        )
        NotificationCenter.default.removeObserver(
            self, name: .musicDidPause, object: nil
        )
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
    
    
    @objc func audioChanged() {
        let isRadioPlaying = AppPlayer.miniPlayerInfo.musicVC == nil
        let audio = isRadioPlaying ? radio : player
        if audio?.isPlaying ?? false {
            self.btnPlayPause.setImage(UIImage(named: "ic_pause"), for: .normal)
        } else {
            self.btnPlayPause.setImage(UIImage(named: "ic_play"), for: .normal)
        }
    }
    
    @IBAction func actionPlayPause(_ sender: Any) {
        let isRadioPlaying = AppPlayer.miniPlayerInfo.musicVC == nil
        let audio = isRadioPlaying ? radio : player
        
        if audio?.isPlaying ?? false {
            audio?.pause()
            self.btnPlayPause.setImage(UIImage(named: "ic_play"), for: .normal)
        } else {
            audio?.play()
            self.btnPlayPause.setImage(UIImage(named: "ic_pause"), for: .normal)
        }
    }
    
    @IBAction func actionOpenSong(_ sender: Any) {
        //UIApplication.shared.keyWindow?.rootViewController ??
        guard let root = (CustomAlertController().topMostController() as? TabbarVC)?.selectedViewController else {
            print("Root is nil")
            return
        }
        guard let vc = AppPlayer.miniPlayerInfo.musicVC else {
            print("miniPlayerInfo.musicVC is nil")
            return
        }
        
        //presentedViewController == nil &&
        if root.presentedViewController == nil {
            root.present(vc, animated: true)
        } else {
            print("A view controller is already being presented or musicVC is already presented")
        }
    }
}


extension MiniPlayerView {
    func refreshMiniplayer() {
        self.viewSongProgress.progress = 0.0
        self.lblSongName.text = AppPlayer.miniPlayerInfo.songNameTitle
        self.lblPlayerArtist.text = AppPlayer.miniPlayerInfo.artistSubtitle
        if AppPlayer.miniPlayerInfo.songImage != "" {
            self.imgSong.af_setImage(withURL: URL(string: AppPlayer.miniPlayerInfo.songImage)!, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
        }
        
        let musicPlay = player?.isPlaying ?? false
        let radioPlay = radio.isPlaying
        if !musicPlay, !radioPlay {
            self.btnPlayPause.setImage(UIImage(named: "ic_play"), for: .normal)
            self.viewCurrentSong.isHidden = true
            return
        }
        
        self.btnPlayPause.setImage(UIImage(named: "ic_pause"), for: .normal)
        self.viewCurrentSong.isHidden = false
        
        //NotificationCenter.default.removeObserver(self)
        //NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying(sender:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        
        timeObserver = nil
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
            
            
        } else if radioPlay {
            
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
