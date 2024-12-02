//
//  Player.swift
//  proradio20
//
//  Created by studio76 on 13.11.15.
//  Copyright © 2015 Studio76. All rights reserved.
//

import AVKit

public extension NSNotification.Name {
    static let pauseRadio = NSNotification.Name(rawValue: "PauseRadio")
    static let reloadRadio = NSNotification.Name(rawValue: "ReloadRadio")
}

var player: PlayObserver? {
    get { AppPlayer.music }
    set {
        (CustomAlertController().topMostController() as? TabbarVC)?.miniPlayer.musicPlayPause = nil
        AppPlayer.music = newValue
    }
}

struct AppPlayer {
    static var radio = AVPlayer()
    static var radioURL = ""
    
    fileprivate static var music: PlayObserver? = nil
    
    /// Set player(music/radio) first
    static var miniPlayerInfo = BasicDetail() {
        willSet { print("Old value: \(miniPlayerInfo)") }
        didSet {
            print("New value: \(miniPlayerInfo)")
            (CustomAlertController().topMostController() as? TabbarVC)?.miniPlayer.refreshMiniplayer()
        }
    }
}


struct BasicDetail {
    var songImage : String = ""
    var artistSongName : String = ""
    var songName : String = ""
    var songController : UIViewController?
}


extension AVPlayer {
    var isPlaying: Bool {
        return ((rate != 0) && (error == nil))
    }
}
