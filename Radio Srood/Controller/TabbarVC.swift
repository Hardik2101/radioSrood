import UIKit

class TabbarVC: UITabBarController {
    static var available: TabbarVC? {
        CustomAlertController().topMostController() as? TabbarVC
    }
    
    static var isMiniPlayerVisible: Bool {
        !(available?.miniPlayer.viewCurrentSong.isHidden ?? true)
    }
    
    var miniPlayer: MiniPlayerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setVCs()
        setupTabbar()
        addMiniPlayer()
    }
    
    func setVCs() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let homeViewController = storyboard.vc(HomeViewController.self)
        let browseViewController = storyboard.vc(BrowseTabVC.self)
        let radioViewController = storyboard.vc(RadioWithRecentViewController.self)
        let allMusicViewController = storyboard.vc(AllMusicViewController.self)
        let iAPVC = storyboard.vc(IAPVC.self)
        
        // Embed each view controller in a UINavigationController
        let homeViewControllerNav = UINavigationController(rootViewController: homeViewController)
        let browseViewControllerNav = UINavigationController(rootViewController: browseViewController)
        let radioiewControllerNav = UINavigationController(rootViewController: radioViewController)
        let allMusicViewControllerNav = UINavigationController(rootViewController: allMusicViewController)
        let iAPVCNav = UINavigationController(rootViewController: iAPVC)
        
        // Set tab bar items
        homeViewControllerNav.tabBarItem = UITabBarItem(title: "Home", image: UIImage(named: "ic_home"), tag: 0)
        browseViewControllerNav.tabBarItem = UITabBarItem(title: "Browse", image: UIImage(named: "ic_browse"), tag: 1)
        radioiewControllerNav.tabBarItem = UITabBarItem(title: "Radio", image: UIImage(named: "ic_radio"), tag: 2)
        allMusicViewControllerNav.tabBarItem = UITabBarItem(title: "My Music", image: UIImage(named: "ic_mymusic"), tag: 3)
        iAPVCNav.tabBarItem = UITabBarItem(title: "Plus", image: UIImage(named: "ic_srood_plus"), tag: 4) // Changed title to avoid duplication
        
        // Add view controllers to the tab bar
        viewControllers = [homeViewControllerNav, browseViewControllerNav, radioiewControllerNav, allMusicViewControllerNav, iAPVCNav]
    }
    
    func setupTabbar() {
        if #available(iOS 13.0, *) {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.backgroundColor = UIColor.black
            
            tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
            tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.gray]
            
            tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
            tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            
            tabBar.standardAppearance = tabBarAppearance
            
            if #available(iOS 15.0, *) {
                tabBar.scrollEdgeAppearance = tabBarAppearance
            }
        } else {
            tabBar.barTintColor = UIColor.black
            tabBar.tintColor = UIColor.white
            tabBar.unselectedItemTintColor = UIColor.gray
        }
        
        tabBar.layer.shadowOffset = CGSize(width: 0, height: -2)
        tabBar.layer.shadowRadius = 4
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOpacity = 0.25
    }
    
    func addMiniPlayer() {
        miniPlayer = MiniPlayerView()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            let tabBarFrame = strongSelf.tabBar.frame
            let customHeight: CGFloat = 60 // Height of your custom view
            strongSelf.miniPlayer.frame = CGRect(
                x: 0,
                y: tabBarFrame.origin.y - customHeight, // Position above tabBar
                width: strongSelf.view.bounds.width,
                height: customHeight
            )
        }
        
        // Adjust autoresizing to match the tabBar's resizing behavior
        miniPlayer.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        
        // Add the custom view to the UITabBarController's view
        view.addSubview(miniPlayer)
        //miniPlayer.refreshMiniplayer()
    }
}
