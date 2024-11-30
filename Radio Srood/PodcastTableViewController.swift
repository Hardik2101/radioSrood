

import UIKit
import SWRevealViewController
import GoogleMobileAds

class PodcastTableViewController: UITableViewController {
    
    @IBOutlet weak var menuBtn :UIBarButtonItem!
    
    var dataHelper: DataHelper!
    var podcastData = [PodcastObject]()
    var bannerView: GADBannerView!

    override func viewDidLoad() {
        super.viewDidLoad()

        menuBtn.target = self.revealViewController()
//        menuBtn.action = #selector(SWRevealViewController.revealToggle(_:))
//        self.view!.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        let uiback = UIImageView(image: UIImage(named: "b1.png"))
        uiback.contentMode = UIView.ContentMode.scaleAspectFill
        tableView.backgroundView = uiback
        
        createBanner()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.podcastData.removeAll()
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.titleTextAttributes =  [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        self.dataHelper = DataHelper()
        self.dataHelper.gePodcastData { (data) in
            
            for item in data{
                let track = item as! NSDictionary
                let trackFile = track.value(forKey: "file")  as! String
                let trackNames = track.value(forKey: "track_name") as! String
                let urlTracks = String(format:"%@%@%@",BASE_BACKEND_URL,UPLOAD_MUSIC,trackFile as CVarArg)
                let urlpath = urlTracks.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                let url = URL(string: urlpath!)
                self.podcastData.append(PodcastObject(file: url!, trackName: trackNames, artistName: ""))
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
            
        }
        
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        return self.podcastData.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "podcast", for: indexPath) as! PodcastTableViewCell
        
        let item = self.podcastData[indexPath.row]
        
        cell.titleTrackLabel.text = item.trackName

       

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let vc = self.storyboard!.instantiateViewController(withIdentifier: "player") as! PlayerViewController
        vc.podcastData = self.podcastData
        vc.indexPlayerz = indexPath.row
        
        navigationController?.pushViewController(vc, animated: true )
    }
    
    func createBanner(){
        guard !IAPHandler.shared.isGetPurchase() else {
            // Skip loading the ad if the purchase is made
            return
        }

        
        bannerView = GADBannerView(frame:CGRect(x: 0, y: 0, width:  tableView.frame.size.width, height: 50))
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0);
        
        bannerView.adUnitID = GOOGLE_ADMOB_KEY
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        
       
            if SHOW_BANNER_ADMOB {self.view.addSubview(bannerView)}
        
        
        
    }
    
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !IAPHandler.shared.isGetPurchase() else {
            // Skip loading the ad if the purchase is made
            return
        }

        var bannerFrame: CGRect = self.bannerView.frame
        bannerFrame.origin.y = self.view.frame.size.height - 50 + self.tableView.contentOffset.y
        self.bannerView.frame = bannerFrame
    }
    

   
}
