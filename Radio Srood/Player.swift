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
}

var player: PlayObserver? {
    get { AppPlayer.musicData }
    set {
        AppPlayer.musicData = newValue
    }
}
var radio: RadioObserver {
    get { AppPlayer.radioData }
    set {
        AppPlayer.radioData = newValue
    }
}

struct AppPlayer {
    static var radioURL = ""
    fileprivate static var radioData = RadioObserver()
    
    fileprivate static var musicData: PlayObserver? = nil
    
    
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
    var songImage: String = ""
    var songNameTitle: String = ""
    var artistSubtitle: String = ""
    
    var musicVC: UIViewController?
}


extension AVPlayer {
    var isPlaying: Bool {
        return ((rate != 0) && (error == nil))
    }
}
