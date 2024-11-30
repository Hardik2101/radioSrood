
import UIKit
import SWRevealViewController
import GoogleMobileAds
import AlamofireImage

class NewsTableViewController: UITableViewController {
    
    @IBOutlet weak var menuBtn :UIBarButtonItem!
    
    
    var dataHelper : DataHelper!
    var newsData = [NewsObject]()
    var bannerView: GADBannerView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        menuBtn.target = self.revealViewController()
        menuBtn.action = #selector(SWRevealViewController.revealToggle(_:))
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
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.titleTextAttributes =  [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        self.newsData.removeAll()
        
        self.dataHelper = DataHelper()
        self.dataHelper.getNewsData { (data) in
            
            for post in data{
                
                let postA = post as! NSDictionary
                let newsTitle = postA.value(forKey: "title") as! String
                let newsText = postA.value(forKey: "text") as! String
                let newsImage = postA.value(forKey: "image_file") as! String
                
                self.newsData.append(NewsObject(newsTitle: newsTitle, newsText: newsText, newsImage: newsImage))
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
        
        return self.newsData.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "news", for: indexPath) as! NewsTableViewCell

        let data = self.newsData[indexPath.row]
        
        let urlImage = data.newsImage
        
        let image = String(format: "%@%@%@", BASE_BACKEND_URL,UPLOAD_IMAGE,urlImage!)
        
        let urla = URL(string:image)! 
        
        cell.newsImage.af_setImage(withURL: urla)
        cell.newsImage.layer.cornerRadius = 10
        cell.newsImage.layer.masksToBounds = true
        cell.newsTitle.text = data.newsTitle

        return cell
    }
    
   override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let news = self.newsData[indexPath.row]
        let vc = self.storyboard!.instantiateViewController(withIdentifier: "newsdetail") as! NewsDetailTableViewController
        vc.newsTitle = news.newsTitle
        vc.newsImage = news.newsImage
        vc.newsText = news.newsText
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
