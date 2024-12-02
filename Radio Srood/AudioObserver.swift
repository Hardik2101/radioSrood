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
        addObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), options: [.new], context: nil)
    }
    override init() {
        super.init()
        addObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), options: [.new], context: nil)
    }
    
    deinit {
        // Remove observer
        //audioGet()?.addObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), options: [.new, .initial], context: nil)
        removeObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus))
    }
    
    // KVO Observation
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == #keyPath(AVPlayer.timeControlStatus),
              let player = object as? AVPlayer else { return }
        updatePlaybackState(player)
    }
    
    private func updatePlaybackState(_ player: AVPlayer) {
        var isPlaying = false
        var isBuffering = false
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
        print("Music isPlaying: \(isPlaying), isBuffering: \(isBuffering)")
        NotificationCenter.default.post(name: isPlaying ? .musicDidPlay : .musicDidPause, object: nil, userInfo: nil)
    }
}


class RadioObserver: AVPlayer {
    override func play() {
        NotificationCenter.default.post(name: .pauseMusic, object: nil, userInfo: nil)
        super.play()
    }
    
    override init(playerItem: AVPlayerItem?) {
        super.init(playerItem: playerItem)
        addObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), options: [.new], context: nil)
    }
    override init() {
        super.init()
        addObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), options: [.new], context: nil)
    }
    
    deinit {
        removeObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus))
    }
    
    // KVO Observation
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == #keyPath(AVPlayer.timeControlStatus),
              let player = object as? AVPlayer else { return }
        updatePlaybackState(player)
    }
    
    private func updatePlaybackState(_ player: AVPlayer) {
        var isPlaying = false
        var isBuffering = false
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
        print("Radio isPlaying: \(isPlaying), isBuffering: \(isBuffering)")
        NotificationCenter.default.post(name: isPlaying ? .radioDidPlay : .radioDidPause, object: nil, userInfo: nil)
    }
}
