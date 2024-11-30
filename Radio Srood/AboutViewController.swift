
import UIKit
import SWRevealViewController

class AboutViewController: UIViewController {
    
    @IBOutlet weak var menuBtn :UIBarButtonItem!
    @IBOutlet weak var aboutLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        menuBtn.target = self.revealViewController()
//        menuBtn.action = #selector(SWRevealViewController.revealToggle(_:))
//        self.view!.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        self.aboutLabel.text = NSLocalizedString("about_text", comment: "")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.titleTextAttributes =  [NSAttributedString.Key.foregroundColor: UIColor.white]
       
    }
    
    @IBAction func fb(){
        
        UIApplication.shared.openURL(NSURL(string: FACEBOOK_URL)! as URL)
        
        
    }
    
    @IBAction func google(){
        
        UIApplication.shared.openURL(NSURL(string: GOOGLE_URL)! as URL)
        
        
    }
    
    @IBAction func tw(){
        
        UIApplication.shared.openURL(NSURL(string: TWITTER_URL)! as URL)
        
        
    }
    


}
