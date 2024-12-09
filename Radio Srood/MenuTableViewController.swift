
import UIKit
import SWRevealViewController
import AVKit

class MenuTableViewController: UITableViewController , SWRevealViewControllerDelegate{
    
    @IBOutlet weak var radioIcon: UIImageView!
    @IBOutlet weak var radioLabel: UILabel!
    
    @IBOutlet weak var timelineIcon: UIImageView!
    @IBOutlet weak var timelineLabel: UILabel!
    
    @IBOutlet weak var tvIcon: UIImageView!
    @IBOutlet weak var tvLabel: UILabel!
    
    @IBOutlet weak var newsIcon: UIImageView!
    @IBOutlet weak var newsLabel: UILabel!
    
    @IBOutlet weak var podcastIcon: UIImageView!
    @IBOutlet weak var podcastLabel: UILabel!
    
    @IBOutlet weak var podcastIconOffline: UIImageView!
    @IBOutlet weak var podcastLabelOffline: UILabel!
    
    @IBOutlet weak var aboutIcon: UIImageView!
    @IBOutlet weak var aboutLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let uiback = UIImageView(image: UIImage(named: "b1.png"))
        uiback.contentMode = UIView.ContentMode.scaleAspectFill
        tableView.backgroundView = uiback
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.menuAnimation()
        self.radioLabel.text = NSLocalizedString("radio_menu_label", comment: "")
        self.tvLabel.text = NSLocalizedString("tv_menu_label", comment: "")
        self.timelineLabel.text = NSLocalizedString("timeline_menu_label", comment: "")
        self.newsLabel.text = NSLocalizedString("news_menu_label", comment: "")
        self.podcastLabel.text = NSLocalizedString("podcast_menu_label", comment: "")
        self.podcastLabelOffline.text = NSLocalizedString("offline_menu_label", comment: "")
        if IAPHandler.shared.isGetPurchase() {
            self.aboutLabel.text = NSLocalizedString("", comment: "")
            self.aboutIcon.image = UIImage(named: "")
        } else {
            self.aboutLabel.text = NSLocalizedString("about_menu_label", comment: "")
            self.aboutIcon.image = UIImage(named: "ic_purchase")
        }
        
        print("isPurchase", IAPHandler.shared.isGetPurchase())
    }
    
    func menuAnimation() {
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == 2 {
            print("Radio Srood")
            UserDefaults.standard.removeObject(forKey: "NowPlayData")
        }
        if indexPath.row == 4 {
            guard let url = URL(string: "http://live.pamirtv.com/stream/ptv.m3u8") else { return }
            NotificationCenter.default.post(name: .pauseRadio, object: nil, userInfo: nil)
            player = PlayObserver() //killing player before stream
            let asset = AVAsset(url: url)
            let playerItem = AVPlayerItem(asset: asset)
            let avPlayer = AVPlayer(playerItem: playerItem)
            let avPlayerViewController = AVPlayerViewController()
            avPlayerViewController.player = avPlayer
            self.present(avPlayerViewController, animated: true) {
                avPlayerViewController.player?.play()
            }
            self.revealViewController()?.revealToggle(self)
        }
        if indexPath.row == 6{
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "AllMusicViewController") as! AllMusicViewController
            let navVC = UINavigationController(rootViewController: vc)
            navVC.navigationBar.isHidden = true
            navVC.modalPresentationStyle = .fullScreen
            self.present(navVC, animated: true)
            self.revealViewController()?.revealToggle(self)
            
        }
        
        if indexPath.row == 7 {
            if !IAPHandler.shared.isGetPurchase() {
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "IAPVC") as! IAPVC
                vc.isshowbackButton = true
                let navVC = UINavigationController(rootViewController: vc)
                navVC.navigationBar.isHidden = true
                navVC.modalPresentationStyle = .fullScreen
                self.present(navVC, animated: true)
                self.revealViewController()?.revealToggle(self)
            } else {
//                let vc = self.storyboard?.instantiateViewController(withIdentifier: "AdsAPIView") as! AdsAPIView
//                let navVC = UINavigationController(rootViewController: vc)
//                navVC.navigationBar.isHidden = true
//                navVC.modalPresentationStyle = .fullScreen
//                self.present(navVC, animated: true)
//                self.revealViewController()?.revealToggle(self)

            }

        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 8
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if (indexPath.row == 0) {
            return 268
        }
        
        if (indexPath.row == 2){  // timeline
            
            if SHOW_TIMELINE {
                return 60
            } else {
                return 0
            }
        }
        
        if (indexPath.row == 3){  // news
            
            if SHOW_NEWS {
                return 60
            } else {
                return 0
            }
        }
        
        if (indexPath.row == 4){  // podcast
            
            if SHOW_PODCAST {
                return 60
            } else {
                return 0
            }
        }
        
        if (indexPath.row == 5){  //  offline
            
            if DOWNLOAD_PODCAST && SHOW_PODCAST {
                return 60
            } else {
                return 0
            }
        }
        
        if (indexPath.row == 6){  // about
            
            if SHOW_ABOUT {
                return 60
            } else {
                return 0
            }
        }
         return 50
    }

}
