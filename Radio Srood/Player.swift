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

struct AppPlayer {
    static var radio = AVPlayer()
    static var radioURL = ""
    static var music: PlayObserver? = nil
}

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

var player: PlayObserver? {
    get { AppPlayer.music }
    set { AppPlayer.music = newValue }
}
var songImage : String = ""
var artistSongName : String = ""
var songName : String = ""
var songController : UIViewController?


extension AVPlayer {
    var isPlaying: Bool {
        return ((rate != 0) && (error == nil))
    }
}
