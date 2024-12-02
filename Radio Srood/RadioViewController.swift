

import UIKit
import SWRevealViewController
import MediaPlayer
import AVKit
import Alamofire
import AlamofireImage
import GoogleMobileAds
import StoreKit


class RadioViewController: UIViewController, GADInterstitialDelegate {
    
    @IBOutlet weak var menuBtn :      UIBarButtonItem!
    @IBOutlet weak var radioImage:    UIImageView!
    @IBOutlet weak var radioName:     UILabel!
    @IBOutlet weak var radioTitle:    UILabel!
    @IBOutlet weak var playPauseBtn:  UIButton!
    @IBOutlet weak var shareBtn:      UIButton!
    @IBOutlet weak var appleBtn:      UIButton!
    
    
    var radioPlayer: AVPlayer {
        get { AppPlayer.radio }
        set {
            AppPlayer.radioURL = radioUrl
            AppPlayer.radio = newValue
        }
    }
    var asset : AVAsset? = nil
    var playerItem: AVPlayerItem!
    
    var dataHelper: DataHelper!
    var radioData: NSDictionary!
    var albumArtwork: MPMediaItemArtwork!
    var radioUrl: String!
    var isPlaying = false
    var timerListen: Timer!
    var trackName: String!
    var artImage: UIImage!
    var appleMusicUrl = ""
    var interstitial: GADInterstitial!
    var countTime = 0
    var mediaImage: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 14.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
        } else if #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()
        } else {
            // Fallback for earlier iOS versions (if needed)
            // Handle the case where SKStoreReviewController is not available
            // or other fallback behavior.
        }
       
        self.artImage = UIImage(named:"Lav_Radio_Logo.png")
        self.trackName = ""
        
//        menuBtn.target = self.revealViewController()
//        menuBtn.action = #selector(SWRevealViewController.revealToggle(_:))
//        self.view!.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        
//        menuBtn.action = #selector(menuButtonClicked(_:))

        
        NotificationCenter.default.addObserver(
            self, selector: #selector(RadioViewController.didBecomeActiveNotificationReceived),
            name:NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification"), object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(RadioViewController.playerInterruption(notification:)),
            name:NSNotification.Name(rawValue: "AVAudioSessionInterruptionNotification"), object: nil
        )
        
        if !isPlaying {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
                
                do {
                    try AVAudioSession.sharedInstance().setActive(true)
                    
                } catch let error as NSError {
                    print(error.localizedDescription)
                }
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            self.becomeFirstResponder()
        }
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(loadRadioData),
            name: .reloadRadio, object: nil
        )
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(stopPlayer),
            name: .pauseRadio, object: nil
        )
        loadInterstitial()
        loadRadioData()
    }
    
//    @objc func menuButtonClicked(_ sender: UIBarButtonItem) {
//        self.navigationController?.popViewController(animated: true)
//    }
    
    deinit {
        NotificationCenter.default.removeObserver(
            self, name:NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification"),
            object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self, name:NSNotification.Name(rawValue: "AVAudioSessionInterruptionNotification"),
            object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self, name: .reloadRadio, object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self, name: .pauseRadio, object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
    }
    
    @objc func stopPlayer() {
        if (isPlaying){
            DispatchQueue.main.async {
                self.playPauseBtn.setImage(UIImage(named: "play.png"), for:.normal)
            }
            radioPlayer.pause()
            updateNowPlaying(isPause: true)
            isPlaying = false
        }
    }
    
    @objc func loadRadioData() {
        self.dataHelper = DataHelper()
        if let data  = UserDefaults.standard.value(forKey: "NowPlayData2") as? NSDictionary {
            self.radioData = data
            self.makeScreenFromList()
            
        } else {
            self.dataHelper.getRadioData { (data) in
                if let _ = data.value(forKey: "radio_url") as? String {
                    self.radioData = data
                    self.makeScreen()
                }
            }
        }
        setupRemoteTransportControls()
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
        }
        else if type == .ended {
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
                    if UIApplication.shared.applicationState == .background {
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
                        self.radioPlayer = AVPlayer(playerItem: self.playerItem)
                        self.radioPlayer.play()
                        self.setupNowPlaying()
                        self.updateNowPlaying(isPause: true)
                    } else {
                        self.radioPlayer.play()
                    }
                }
            }
        }
    }
    
    private func loadInterstitial() {
        guard !IAPHandler.shared.isGetPurchase() else {
            // Skip loading the ad if the purchase is made
            return
        }

        interstitial = GADInterstitial(adUnitID: GOOGLE_ADMOB_INTER)
        interstitial!.delegate = self
        interstitial!.load(GADRequest())
    }
    
    func interstitialDidFailToReceiveAdWithError (
        interstitial: GADInterstitial,
        error: GADRequestError) {
        print("interstitialDidFailToReceiveAdWithError: %@" + error.localizedDescription)
    }
    
    func interstitialDidDismissScreen (_ interstitial: GADInterstitial) {
        print("interstitialDidDismissScreen")
        
    }
    
    func banners(){
        guard !IAPHandler.shared.isGetPurchase() else {
            return
        }

        if (interstitial!.isReady) {
            interstitial!.present(fromRootViewController: self)
        } else {
            
            loadInterstitial()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "notify"), object: nil)
    }
    
    @objc func didBecomeActiveNotificationReceived() {
        updateNowPlaying(isPause: true)
    }
    
    func makeScreen()  {
        self.radioImage.layer.cornerRadius = 5
        self.radioImage.layer.masksToBounds = true
        
        self.radioName.text = self.radioData.value(forKey: "name") as? String
        self.radioTitle.text = "Click To Play"
        
        self.radioUrl = self.radioData.value(forKey: "radio_url") as? String
        print(self,radioUrl)
        
        self.playPauseBtn.setTitle("play", for: .normal)
        
        self.appleBtn.isHidden = true
        
        setupPlayer()
        stationDidChange()
    }
    
    func makeScreenFromList()  {
        self.radioImage.layer.cornerRadius = 5
        self.radioImage.layer.masksToBounds = true
        
        self.radioName.text = self.radioData.value(forKey: "tv_name") as? String
        self.radioTitle.text = "Click To Play"
        
        self.radioUrl = self.radioData.value(forKey: "tv_stream") as? String
        print(self,radioUrl)
        
        self.playPauseBtn.setTitle("play", for: .normal)
        
        self.appleBtn.isHidden = true
        
        if let image_name = self.radioData.value(forKey: "image") as? String {
            let img = BASE_BACKEND_URL + UPLOAD_IMAGE + image_name
            if let urla = URL(string:img) {
                self.radioImage.af_setImage(withURL: urla, placeholderImage: nil, filter: nil, imageTransition: .crossDissolve(0.5), completion: { response in
                    if response.value != nil {
                        self.artImage = response.value
                    }
                })
            }
        }
        
        setupPlayer()
        stationDidChange()
    }
    
    func setupPlayer () {
        radioPlayer.allowsExternalPlayback = true
        radioPlayer.usesExternalPlaybackWhileExternalScreenIsActive = true
    }
    
    func stationDidChange() {
        /*Radio Already play by other screen */
        if AppPlayer.radioURL != radioUrl {
            NotificationCenter.default.post(name: .pauseRadio, object: nil, userInfo: nil)
        }
        radioPlayer.pause()
        
        let playURL = URL(string: self.radioUrl)
        
        asset = AVAsset(url: playURL!)
        playerItem = AVPlayerItem(url:playURL!)
        playerItem.addObserver(self, forKeyPath: "timedMetadata", options: [], context: nil)
        playerItem.addObserver(self, forKeyPath: "presentationSize", options: [], context: nil)
        radioPlayer = AVPlayer(playerItem: playerItem)
        self.playPauseBtn.setImage(UIImage(named: "play.png"), for:.normal)
        radioPlayer.pause()
        isPlaying = false
    }
    
    func playPauseback(){
        if (isPlaying){
            radioPlayer.pause()
            isPlaying = false
        }else{
            radioPlayer.play()
            isPlaying = true
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
        } else {
            /*Radio Already play by other screen */
            if AppPlayer.radioURL != radioUrl {
                //.pauseRadio is in stationDidChange
                stationDidChange()
            }
            
            DispatchQueue.main.async {
                self.playPauseBtn.setImage(UIImage(named: "pause.png"), for: .normal)
            }
            player?.pause()
            radioPlayer.play()
            isPlaying = true
            setupNowPlaying()
            updateNowPlaying(isPause: false)
            update()
        }
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath != "timedMetadata" { return }
        if let data: AVPlayerItem = object as? AVPlayerItem
        {
            if let dataItem = data.timedMetadata
            {
                for item in dataItem
                {
                    let metaArray: Array<Any> = [playerItem?.timedMetadata as Any]
                    print("Total objects in array \(metaArray[0])")
                    let data = item.stringValue
                    if(data == nil){
                        radioTitle.text = "metadata not load"
                        self.trackName = "metadata not load"
                        self.findAppleMusic(name: "metadata not load")
                    } else {
                        radioTitle.text = data! as String
                        self.trackName = data! as String
                        self.findAppleMusic(name: data! as String)
                        self.setupNowPlaying()
                    }
                }
            }
        }
    }

    func findAppleMusic(name: String){
        
        let queryURL = String(format: "http://radiosrood.com/api/currentsongappv1.json", name)
        let escapedURL = queryURL.addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed)!
        
        Alamofire.request( escapedURL, method: .get, parameters: ["X-API-KEY":API_KEY])
            .responseJSON { [weak self] response in
                guard let self = self else { return }
                switch response.result {
                case .success( _):
                    let data = response.result.value as! NSDictionary
                    let countFind = data.value(forKey: "currentData") as! Int
                    if (countFind > 0) {
                        let resultArray = data.value(forKey: "currentTrack") as! NSArray
                        let result = resultArray[0] as! NSDictionary
                        let artwork = result.value(forKey: "artCover") as! String
                        let bigArtwork = artwork.replacingOccurrences(of: "100", with: "800")
                        let musicUrl  = result.value(forKey: "trackUrl")
                        self.appleMusicUrl = musicUrl as? String ?? ""
                        let url = URL(string:bigArtwork)
                        self.radioImage.af_setImage(withURL: url!)
                        self.appleBtn.isHidden = false
                        self.getDataFromUrl(url: url!, completion: { [self] (datax, responce, error) in
                            self.artImage = UIImage(data:datax!)
                            self.updateNowPlaying(isPause: true)
                            self.recordTimeline(tracksName: name, nameStationLine: (self.radioData.value(forKey: "name") as? String) ?? "", urlStationLine: (self.radioData.value(forKey: "radio_url") as? String ?? ""), imageTrackLine: musicUrl as? String ?? "", urlTrackInAppleMusic: musicUrl as? String ?? "", coverUrl: bigArtwork)
                        })
                    } else {
                        self.radioImage.image = UIImage(named: "Lav_Radio_Logo.png")
                        self.artImage = UIImage(named: "Lav_Radio_Logo.png")
                        self.appleBtn.isHidden = true
                        self.updateNowPlaying(isPause: true)
                    }
                case .failure(let error):
                    print("Request failed with error: \(error)")
                }
            }
    }
    
    func recordTimeline(tracksName:String, nameStationLine:String, urlStationLine:String, imageTrackLine:String, urlTrackInAppleMusic: String, coverUrl: String){
        let urlRequest = String(format: "%@%@",BASE_BACKEND_URL,ENDPOINT_APPLE_MUSIC_SEND)
        Alamofire.request( urlRequest,method: .post, parameters: ["X-API-KEY": API_KEY,"name_track":tracksName,"name_radio":nameStationLine, "track_url":urlTrackInAppleMusic, "cover_url":coverUrl, "is_found": "1" ])
            .responseJSON { response in
                
            }        
    }
    
    func setupRemoteTransportControls() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()
        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [unowned self] event in
            print("Play command - is playing: \(self.radioPlayer.isPlaying)")
            if !self.radioPlayer.isPlaying {
                self.radioPlayer.play()
                return .success
            }
            return .commandFailed
        }

        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            print("Pause command - is playing: \(self.radioPlayer.isPlaying)")
            if self.radioPlayer.isPlaying {
                self.radioPlayer.pause()
                return .success
            }
            return .commandFailed
        }
    }
    
    func updateNowPlaying(isPause: Bool) {
        // Define Now Playing Info
        if var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
        {
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPause ? 0 : 1
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
    
    func setupNowPlaying() {
        var nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyArtist] = self.trackName
        nowPlayingInfo[MPMediaItemPropertyTitle] = radioName.text
        nowPlayingInfo[MPMediaItemPropertyArtwork] = self.artImage

        if let image = self.artImage {
            if #available(iOS 10.0, *) {
                nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { size in
                    return image
                }
            } else {
                // Fallback on earlier versions
            }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

        if LOCAL_NOTIFICATION{
            let localNotification = UILocalNotification()
            localNotification.fireDate = NSDate(timeIntervalSinceNow: 5) as Date
            localNotification.alertBody = radioName.text!
            localNotification.timeZone = NSTimeZone.default
            localNotification.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber + 1
            UIApplication.shared.scheduleLocalNotification(localNotification)
        }
    }
    
    func getDataFromUrl(url: URL, completion: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> Void) {
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            completion(data, response, error)
        }.resume()
    }
    
    
    public func update() {
        if SHOW_BANNER_ADMOB {banners()}
    }
    
    @IBAction  func goToAppleMusic() {
        if let url = URL(string: self.appleMusicUrl)
        {
            if UIApplication.shared.canOpenURL(url) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, completionHandler: nil)
                } else {
                    // Fallback on earlier versions
                }
            }
        }
    }
    
    public func radioStop(){
        radioPlayer.pause()
    }
    
    @IBAction func share(_ sender:UIButton) {
        if (self.trackName.isEmpty){
            self.trackName = "Radio Srood"
        }
        let shareText = String (format: "I am listening to %@ on Radio Srood app! Download the app @ http://radiosrood.com/iOS", self.trackName)
        var imageArtShare :UIImage!
        
        if(self.artImage == nil){
            imageArtShare = UIImage(named:"no_image.jpg")
            
        } else {
            
            imageArtShare = self.artImage
        }
        
        let vc = UIActivityViewController(activityItems: [shareText, imageArtShare], applicationActivities: [])
        vc.modalPresentationStyle = .popover;
        if let wPPC = vc.popoverPresentationController {
            wPPC.sourceView = sender
        }
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func clickOn_btnBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
