

import UIKit
import SWRevealViewController
import GoogleMobileAds

class OfflineTableViewController: UITableViewController {
    
    @IBOutlet weak var menuBtn :UIBarButtonItem!
    
    
    var dataHelper: DataHelper!
    var trackData  = [PodcastObject]()
    var bannerView: GADBannerView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        menuBtn.target = self.revealViewController()
//        menuBtn.action = #selector(SWRevealViewController.revealToggle(_:))
//        self.view!.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        
        let uiback = UIImageView(image: UIImage(named: "b1.png"))
        uiback.contentMode = UIView.ContentMode.scaleAspectFill
        tableView.backgroundView = uiback
        
        dataHelper = DataHelper()
        dataHelper.fetchMp3 { (data) in
            
           self.trackData = data
            
        }
        
        createBanner()

       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.titleTextAttributes =  [NSAttributedString.Key.foregroundColor: UIColor.white]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.trackData.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "podcast", for: indexPath) as! PodcastTableViewCell
        
        let item = self.trackData[indexPath.row]
        let str = item.trackName
        let newString1 = str?.replacingOccurrences(of: "_", with: " ", options: .literal, range: nil)
        cell.titleTrackLabel.text = newString1
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let vc = self.storyboard!.instantiateViewController(withIdentifier: "player") as! PlayerViewController
        vc.podcastData = self.trackData
        vc.indexPlayerz = indexPath.row
        navigationController?.pushViewController(vc, animated: true )
    }
   
    
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
           
            let file = self.trackData[indexPath.row]
            let helper = DataHelper()
            helper.removeFile(fileURL: file.file! as NSURL, error: nil)
            self.trackData.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
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
