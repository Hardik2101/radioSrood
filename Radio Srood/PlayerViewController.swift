
import UIKit
import Alamofire
import StoreKit

class PlayerViewController: UIViewController, JukeboxDelegate {
    
    var podcastData = [PodcastObject]()
    var jukebox : Jukebox!
    var indexPlayerz: Int!
    var jukeboxItems = [JukeboxItem]()
    
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var replayButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var centerContainer: UIView!
    @IBOutlet weak var downloadBtn: UIBarButtonItem!
    
    override var canBecomeFirstResponder: Bool { return true }
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        configureUI()
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        if DOWNLOAD_PODCAST && SHOW_PODCAST{
            
        } else {
            self.navigationItem.rightBarButtonItem = nil ;
        }
    }
    
    func configureUI ()
    {
        resetUI()
        slider.setThumbImage(UIImage(named: "sliderThumb"), for: UIControl.State())
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if (self.isMovingFromParent){
            
            jukebox.stop()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.titleTextAttributes =  [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationController?.navigationBar.tintColor = .white
        
        jukeboxItems.removeAll()
        
        for i in 0..<self.podcastData.count {
            
            let mix = self.podcastData[i]
            print(mix.file)
            let trackUrl = mix.file
          
            jukeboxItems.append(JukeboxItem(URL: trackUrl!))
        }
        
        jukebox = Jukebox(delegate: self, items:jukeboxItems)!
        radio.pause()
        
        jukebox.play(atIndex: indexPlayerz)
        updateArtistLabel()
    }
    
    func updateArtistLabel(){
        
        let item = jukebox.currentItem
        let title = String(format:"%@",(item?.URL.lastPathComponent)!)
        let newString = title.replacingOccurrences(of: ".mp3", with: "", options: .literal, range: nil)
        let newString1 = newString.replacingOccurrences(of: "_", with: " ", options: .literal, range: nil)
        titleLabel.text = newString1
    }
    
    func jukeboxDidLoadItem(_ jukebox: Jukebox, item: JukeboxItem) {
        print("Jukebox did load: \(item.URL.lastPathComponent)")
        
    }
    
    func jukeboxPlaybackProgressDidChange(_ jukebox: Jukebox) {
        
        if let currentTime = jukebox.currentItem?.currentTime, let duration = jukebox.currentItem?.meta.duration {
            let value = Float(currentTime / duration)
            slider.value = value
            populateLabelWithTime(currentTimeLabel, time: currentTime)
            populateLabelWithTime(durationLabel, time: duration)
        } else {
            resetUI()
        }
        
    }
    
    func jukeboxStateDidChange(_ jukebox: Jukebox) {
        
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            
            self.playPauseButton.alpha = jukebox.state == .loading ? 0 : 1
            self.playPauseButton.isEnabled = jukebox.state == .loading ? false : true
        })
        
        if jukebox.state == .ready {
            playPauseButton.setImage(UIImage(named: "play-button.png"), for: UIControl.State())
        } else if jukebox.state == .loading  {
            playPauseButton.setImage(UIImage(named: "pause-button.png"), for: UIControl.State())
        } else {
            let imageName: String
            switch jukebox.state {
            case .playing, .loading:
                imageName = "pause-button.png"
            case .paused, .failed, .ready:
                imageName = "play-button.png"
            }
            playPauseButton.setImage(UIImage(named: imageName), for: UIControl.State())
        }
        
    }
    
    func jukeboxDidUpdateMetadata(_ jukebox: Jukebox, forItem: JukeboxItem) {
        print("Item updated:\n\(forItem)")
        
    }
    
    func populateLabelWithTime(_ label : UILabel, time: Double) {
        let minutes = Int(time / 60)
        let seconds = Int(time) - minutes * 60
        label.text = String(format: "%02d", minutes) + ":" + String(format: "%02d", seconds)
    }
    
    func resetUI()
    {
        durationLabel.text = "00:00"
        currentTimeLabel.text = "00:00"
        slider.value = 0
    }
    
    override func remoteControlReceived(with event: UIEvent?) {
        if event?.type == .remoteControl {
            switch event!.subtype {
            case .remoteControlPlay :
                jukebox.play()
            case .remoteControlPause :
                jukebox.pause()
            case .remoteControlNextTrack :
                jukebox.playNext()
            case .remoteControlPreviousTrack:
                jukebox.playPrevious()
            case .remoteControlTogglePlayPause:
                if jukebox.state == .playing {
                    jukebox.pause()
                } else {
                    jukebox.play()
                }
            default:
                break
            }
        }
    }
    
  
    
    @IBAction func progressSliderValueChanged() {
        if let duration = jukebox.currentItem?.meta.duration {
            jukebox.seek(toSecond: Int(Double(slider.value) * duration))
        }
    }
    
    @IBAction func prevAction() {
        
        if let time = jukebox.currentItem?.currentTime, time > 5.0 || jukebox.playIndex == 0 {
            jukebox.replayCurrentItem()
            updateArtistLabel()
        } else {
            jukebox.playPrevious()
            updateArtistLabel()
        }
    }
    
    @IBAction func nextAction() {
        jukebox.playNext()
        updateArtistLabel()
    }
    
    @IBAction func playPauseAction() {
        switch jukebox.state {
        case .ready :
            jukebox.play(atIndex: 0)
        case .playing :
            jukebox.pause()
        case .paused :
            jukebox.play()
        default:
            jukebox.stop()
        }
    }
    
    
    func playsPayse(){
        
        switch jukebox.state {
        case .ready :
            jukebox.play(atIndex: 0)
        case .playing :
            jukebox.pause()
        case .paused :
            jukebox.play()
        default:
            jukebox.stop()
        }
        
    }
    
    @IBAction func replayAction() {
        resetUI()
        jukebox.replay()
        
    }
    
    @IBAction func stopAction() {
        resetUI()
        jukebox.stop()
    }
    
    @IBAction func download() {
        guard let track = jukebox.currentItem?.URL else { return }
        let name = track.lastPathComponent

        let destination: DownloadRequest.Destination = { _, _ in
            var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            documentsURL.appendPathComponent(name)
            return (documentsURL, [.removePreviousFile, .createIntermediateDirectories])
        }

        AF.download(track, to: destination)
            .downloadProgress { progress in
                DispatchQueue.main.async {
                    self.navigationController?.setProgress(Float(progress.fractionCompleted), animated: true)
                }
                print("Download Progress: \(progress.fractionCompleted)")
                if progress.fractionCompleted == 1 {
                    self.navigationController?.finishProgress()
                }
            }
            .response { response in
                if let fileURL = response.fileURL {
                    print("Downloaded to: \(fileURL)")
                } else if let error = response.error {
                    print("Download failed: \(error.localizedDescription)")
                }
            }
    }

}
