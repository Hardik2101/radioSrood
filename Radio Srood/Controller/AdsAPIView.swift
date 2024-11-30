import UIKit
import AlamofireImage
import AVFoundation

protocol AdsAPIViewDelegate: AnyObject {
    func adsPlaybackDidFinish()
}

class AdsAPIView: UIViewController {

    @IBOutlet weak var vwMain: UIView!
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var imgLogo: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblSubTitle: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var lblStartTime: UILabel!
    @IBOutlet weak var lblEndTime: UILabel!
    @IBOutlet weak var btnFollowus: UIButton!

    var adsCampaign: [AdsCampaign] = []
    var audioPlayer: AVPlayer?
    var sliderTimer: Timer?
    weak var delegate: AdsAPIViewDelegate?
    var randomIndex: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        apiCall()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        audioPlayer?.pause()
        sliderTimer?.invalidate()
    }

    private func setUpUI() {
        self.btnFollowus.backgroundColor = UIColor.cyan
        self.btnFollowus.setTitleColor(.black, for: .normal)
        self.btnFollowus.layer.cornerRadius = 10
        self.btnFollowus.layer.borderWidth = 2
        self.btnFollowus.layer.borderColor = UIColor.cyan.cgColor
        
        self.btnBack.isHidden = true
    }

    private func apiCall() {
        ApiManager.fetchSroodAds { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let sroodAds):
                self.adsCampaign = sroodAds.AdsCampaign
                DispatchQueue.main.async {
                    if !self.adsCampaign.isEmpty {
                        self.randomIndex = Int.random(in: 0..<self.adsCampaign.count)
                        if let randomIndex = self.randomIndex {
                            self.updateUI(for: randomIndex)
                            self.playAudio(for: randomIndex)
                        }
                    } else {
                        print("No ads available.")
                    }
                }
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    private func updateUI(for index: Int) {
        guard index >= 0 && index < adsCampaign.count else {
            print("Invalid index.")
            return
        }
        
        let ad = adsCampaign[index]
        DispatchQueue.main.async {
            self.lblTitle.text = ad.CampaignTitle
            self.lblSubTitle.text = ad.CampaignSubTitle
            
            if let campaignCoverURLString = ad.CampaignCover, let campaignCoverURL = URL(string: campaignCoverURLString) {
                self.imgLogo.af_setImage(withURL: campaignCoverURL, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            } else {
                print("Campaign cover URL is nil or invalid.")
            }
        }
    }

    private func playAudio(for index: Int) {
        guard index >= 0 && index < adsCampaign.count else {
            print("Invalid index.")
            return
        }

        guard let audioURLString = adsCampaign[index].CampaignAudio,
              let audioURL = URL(string: audioURLString) else {
            print("Invalid audio URL.")
            return
        }

        let playerItem = AVPlayerItem(url: audioURL)
        audioPlayer = AVPlayer(playerItem: playerItem)

        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)

        audioPlayer?.play()

        sliderTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if let duration = self.audioPlayer?.currentItem?.duration.seconds, duration > 0 {
                let progress = self.audioPlayer?.currentTime().seconds ?? 0
                let sliderValue = Float(progress / duration)
                DispatchQueue.main.async {
                    self.slider.value = sliderValue
                    self.lblStartTime.text = self.formatTime(seconds: progress)
                    self.lblEndTime.text = self.formatTime(seconds: duration)
                }
            }
        }
    }

    private func formatTime(seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    @objc private func playerDidFinishPlaying() {
        print("Song was ended.")
        self.dismiss(animated: true)
        delegate?.adsPlaybackDidFinish()
    }

    @IBAction func clickon_btnFollowUS(_ sender: Any) {
        guard let randomIndex = self.randomIndex,
              randomIndex >= 0 && randomIndex < adsCampaign.count else {
            print("Invalid random index.")
            return
        }
        
        let ad = adsCampaign[randomIndex]
        if let url = URL(string: ad.CampaignLink ?? "https://facebook.com/radiosrood") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    @IBAction func clickOn_btnBack(_ sender: Any) {
        // Handle back button click
    }
}
