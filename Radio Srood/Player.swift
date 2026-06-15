//
//  Player.swift
//  proradio20
//
//  Created by studio76 on 13.11.15.
//  Copyright © 2015 Studio76. All rights reserved.
//

import AVKit

public extension NSNotification.Name {
    //MARK: For Do Changes
    static let pauseMusic = NSNotification.Name(rawValue: "PauseMusic")
    static let pauseRadio = NSNotification.Name(rawValue: "PauseRadio")
    static let reloadRadio = NSNotification.Name(rawValue: "ReloadRadio")
    
    
    //MARK: For Update UI
    static let musicDidPause = NSNotification.Name(rawValue: "MusicDidPause")
    static let musicDidPlay = NSNotification.Name(rawValue: "MusicDidPlay")
    
    static let radioDidPause = NSNotification.Name(rawValue: "RadioDidPause")
    static let radioDidPlay = NSNotification.Name(rawValue: "RadioDidPlay")
    
    
    static let MiniPlayerVisibilityChanged = Notification.Name("MiniPlayerVisibilityChanged")
}

var player: PlayObserver? {
    get { AppPlayer.musicData }
    set {
        if let old = AppPlayer.musicData, old !== newValue {
            old.pause()
        }
        AppPlayer.musicData = newValue
    }
}
var radio: RadioObserver {
    get { AppPlayer.radioData }
    set {
        if AppPlayer.radioData !== newValue {
            AppPlayer.radioData.pause()
        }
        AppPlayer.radioData = newValue
    }
}

struct AppPlayer {
    static var radioURL = ""
    fileprivate static var radioData = RadioObserver()
    
    fileprivate static var musicData: PlayObserver? = nil

    static func pauseMusic() {
        musicData?.pause()
    }

    static func pauseMusic(except observer: PlayObserver) {
        if let current = musicData, current !== observer {
            current.pause()
        }
    }

    static func pauseRadio() {
        radioData.pause()
    }

    private static var isCoordinationConfigured = false

    static func configurePlaybackCoordination() {
        guard !isCoordinationConfigured else { return }
        isCoordinationConfigured = true
        NotificationCenter.default.addObserver(
            forName: .pauseMusic, object: nil, queue: .main
        ) { _ in pauseMusic() }
        NotificationCenter.default.addObserver(
            forName: .pauseRadio, object: nil, queue: .main
        ) { _ in pauseRadio() }
    }
    
    
    /// Set player(music/radio) first
    static var miniPlayerInfo = BasicDetail() {
        willSet { print("Old value: \(miniPlayerInfo)") }
        didSet {
            print("New value: \(miniPlayerInfo)")
            TabbarVC.available?.miniPlayer.refreshMiniplayer()
        }
    }
}


struct BasicDetail {
    var songImage: String = ""
    var songNameTitle: String = ""
    var artistSubtitle: String = ""
    
    var musicVC: UIViewController?
    var radioVC: UIViewController?
}


extension AVPlayer {
    var isPlaying: Bool {
        return ((rate != 0) && (error == nil))
    }
}
