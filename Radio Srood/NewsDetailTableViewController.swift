

import UIKit
import GoogleMobileAds
import AlamofireImage
class NewsDetailTableViewController: UITableViewController {
    
    @IBOutlet weak var newsTitleLAbel: UILabel!
    @IBOutlet weak var newsImagesCover: UIImageView!
    @IBOutlet weak var textCell: UITableViewCell!
    @IBOutlet weak var  bannerView: GADBannerView!
    
    var newsTitle: String!
    var newsImage: String!
    var newsText: String!
    var imageSare: UIImage!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        let uiback = UIImageView(image: UIImage(named: "b1.png"))
        uiback.contentMode = UIView.ContentMode.scaleAspectFill
        tableView.backgroundView = uiback
        
        let image = String(format: "%@%@%@", BASE_BACKEND_URL,UPLOAD_IMAGE,newsImage!)
        let urla = URL(string:image)
        self.newsImagesCover.af_setImage(withURL: urla!)
        self.newsTitleLAbel.text = newsTitle
        self.textCell.textLabel?.text = newsText
        
        
            
           if SHOW_BANNER_ADMOB {makeBanner()}
       
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.titleTextAttributes =  [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationController?.navigationBar.tintColor = .white
        
        
    }
    
    func makeBanner(){
        guard !IAPHandler.shared.isGetPurchase() else {
            // Skip loading the ad if the purchase is made
            return
        }

        bannerView.adUnitID = GOOGLE_ADMOB_KEY
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
    }
    
   
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.row == 3 {
            
            tableView.rowHeight = UITableView.automaticDimension
            
            let contentSize = self.textCell.textLabel!.sizeThatFits(self.textCell.textLabel!.bounds.size)
            
            let labelSize: CGSize =  (self.newsText ).size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0)])
            
            self.textCell.frame.size = labelSize
            
            return contentSize.height
        }
        
        if indexPath.row == 1{
            
            return 300
        }
        
        if indexPath.row == 2{
            
          
                
                return 50
            
            
            
        }
        return 100
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 5
    }
    
    @IBAction func shareNews(){
        
        let shareTexts = String(format: "%@ send from Radio Srood app. Download: http://radiosrood.com/iOS ",newsTitle)
        let image = String(format: "%@%@%@", BASE_BACKEND_URL,UPLOAD_IMAGE,newsImage!)
        let urla = URL(string:image)
        
        getDataFromUrl(url: urla!) { (data, response, error)  in
            guard let data = data, error == nil else { return }
           
            DispatchQueue.main.async() { () -> Void in
                self.imageSare = UIImage(data: data)
                
                let vc = UIActivityViewController(activityItems: [shareTexts, self.imageSare], applicationActivities: [])
                self.present(vc, animated: true, completion: nil)
            }
        }
        
       
        
       
        
    }
    
    func getDataFromUrl(url: URL, completion: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> Void) {
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            completion(data, response, error)
            }.resume()
    }
    
    


}


