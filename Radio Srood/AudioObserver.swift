//
//  AudioObserver.swift
//  Radio Srood
//
//  Created by B on 01/12/24.
//  Copyright © 2024 Radio Srood Inc. All rights reserved.
//

import Foundation
import AVFoundation

// MARK: - PlayObserver
/// Pauses radio if needed whenever play is called on the music player.
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
        removeObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus))
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard keyPath == #keyPath(AVPlayer.timeControlStatus),
              let player = object as? AVPlayer else { return }

        // FIX: KVO can fire on any thread. Always dispatch to main thread before
        // posting notifications or touching any shared state, to prevent the
        // "Simultaneous accesses" exclusivity violation crash.
        DispatchQueue.main.async { [weak self] in
            guard self != nil else { return }
            self?.updatePlaybackState(player)
        }
    }

    private func updatePlaybackState(_ player: AVPlayer) {
        // This now always runs on the main thread (dispatched above).
        let isPlaying: Bool
        let isBuffering: Bool

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
            isPlaying = false
            isBuffering = false
        }

        print("Music isPlaying: \(isPlaying), isBuffering: \(isBuffering)")
        NotificationCenter.default.post(
            name: isPlaying ? .musicDidPlay : .musicDidPause,
            object: nil,
            userInfo: nil
        )
    }
}

// MARK: - RadioObserver
/// Pauses music player if needed whenever play is called on the radio player.
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

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard keyPath == #keyPath(AVPlayer.timeControlStatus),
              let player = object as? AVPlayer else { return }

        // FIX: Same fix as PlayObserver — dispatch to main thread before posting
        // notifications to prevent simultaneous access to shared state (e.g.
        // UserDefaultsManager.shared.localTracksData) from multiple threads.
        DispatchQueue.main.async { [weak self] in
            guard self != nil else { return }
            self?.updatePlaybackState(player)
        }
    }

    private func updatePlaybackState(_ player: AVPlayer) {
        // This now always runs on the main thread (dispatched above).
        let isPlaying: Bool
        let isBuffering: Bool

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
            isPlaying = false
            isBuffering = false
        }

        print("Radio isPlaying: \(isPlaying), isBuffering: \(isBuffering)")
        NotificationCenter.default.post(
            name: isPlaying ? .radioDidPlay : .radioDidPause,
            object: nil,
            userInfo: nil
        )
    }
}
