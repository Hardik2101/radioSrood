//
//  AudioObserver.swift
//  Radio Srood
//
//  Created by B on 01/12/24.
//  Copyright © 2024 Radio Srood Inc. All rights reserved.
//

import Foundation
import AVFoundation


///Pause radio if needed, whenever play called
class PlayObserver: AVPlayer {
    override func play() {
        NotificationCenter.default.post(name: .pauseRadio, object: nil, userInfo: nil)
        super.play()
    }
    
    override init(playerItem: AVPlayerItem?) {
        super.init(playerItem: playerItem)
    }
    override init() {
        super.init()
    }
}

/*
 class PlayObsever: AVPlayer {
 //    var isRadio: Bool = false
 override func play() {
 //        if !isRadio, AppPlayer.radio.isPlaying {
 //            AppPlayer.radio.pause()
 //        }
 //        if isRadio, player?.isPlaying ?? false {
 //            player?.pause()
 //        }
 super.play()
 }
 }
 */


class PlayPauseSender: NSObject {
    var audioGet: (()->(AVPlayer?))!
    private(set) var isPlaying: Bool = false
    private(set) var isBuffering: Bool = false
    
    var onPlaybackStateChange: ((Bool) -> Void)?
    var onBufferingStateChange: ((Bool) -> Void)?
    
    init?(player: @escaping ()->(AVPlayer?)) {
        guard let x = player() else {
            return nil
        }
        super.init()
        audioGet = player
        x.addObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), options: [.new, .initial], context: nil)
    }
    
    deinit {
        // Remove observer
        //audioGet()?.addObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), options: [.new, .initial], context: nil)
        audioGet()?.removeObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus))
    }
    
    // KVO Observation
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == #keyPath(AVPlayer.timeControlStatus),
              let player = object as? AVPlayer else { return }
        updatePlaybackState(player)
    }
    
    private func updatePlaybackState(_ player: AVPlayer) {
        switch player.timeControlStatus {
        case .paused:
            isPlaying = false
            isBuffering = false
        case .waitingToPlayAtSpecifiedRate:
            isPlaying = false
            isBuffering = true
        case .playing:
            isPlaying = true
            isBuffering = false
        @unknown default:
            break
        }
        
        // Notify UI using callbacks
        onPlaybackStateChange?(isPlaying)
        onBufferingStateChange?(isBuffering)
    }
}
