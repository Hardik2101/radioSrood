import UIKit


class TabbarVC: UITabBarController, UITabBarControllerDelegate {
    static var cacheVC: TabbarVC?
    static var available: TabbarVC? {
        CustomAlertController().topMostController() as? TabbarVC ?? cacheVC
    }
    
    static var isMiniPlayerVisible: Bool {
        !(available?.miniPlayer.isHidden ?? true)
    }
    
    var miniPlayer: MiniPlayerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black
        tabBar.backgroundColor = .clear

        TabbarVC.cacheVC = self
        delegate = self

        setVCs()
        setupTabbar()
        addMiniPlayer()
    }

    
    func setVCs() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let homeViewController = storyboard.vc(HomeViewController.self)
        let browseViewController = storyboard.vc(BrowseTabVC.self)
        let radioViewController = storyboard.vc(RadioWithRecentViewController.self)
        let searchViewController = storyboard.vc(SearchViewController.self)
        let allMusicViewController = storyboard.vc(AllMusicViewController.self)
        
        // Embed each view controller in a UINavigationController
        let homeViewControllerNav = UINavigationController(rootViewController: homeViewController)
        let browseViewControllerNav = UINavigationController(rootViewController: browseViewController)
        let radioiewControllerNav = UINavigationController(rootViewController: radioViewController)
        let searchViewControllerNav = UINavigationController(rootViewController: searchViewController)
        let allMusicViewControllerNav = UINavigationController(rootViewController: allMusicViewController)
        
        // Set tab bar items
        homeViewControllerNav.tabBarItem = UITabBarItem(title: "Home", image: UIImage(named: "ic_home"), tag: 0)
        browseViewControllerNav.tabBarItem = UITabBarItem(title: "Browse", image: UIImage(named: "ic_browse"), tag: 1)
        radioiewControllerNav.tabBarItem = UITabBarItem(title: "Radio", image: UIImage(named: "ic_radio"), tag: 2)
        searchViewControllerNav.tabBarItem = UITabBarItem(title: "Search", image: UIImage(systemName: "magnifyingglass"), tag: 3)
        allMusicViewControllerNav.tabBarItem = UITabBarItem(title: "My Music", image: UIImage(named: "ic_mymusic"), tag: 4)
        
        // Add view controllers to the tab bar
        viewControllers = [homeViewControllerNav, browseViewControllerNav, radioiewControllerNav, searchViewControllerNav, allMusicViewControllerNav]
    }
    
    func setupTabbar() {
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()

            // ✅ REAL liquid glass
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)

            // ❌ DO NOT use white or default colors
            appearance.backgroundColor = UIColor.clear

            // Icons & text
            appearance.stackedLayoutAppearance.normal.iconColor =
                UIColor.white.withAlphaComponent(0.55)

            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.white.withAlphaComponent(0.55)
            ]

            appearance.stackedLayoutAppearance.selected.iconColor = .white
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor.white
            ]

            // ❌ Remove shadow line (causes white edge sometimes)
            appearance.shadowColor = nil
            appearance.shadowImage = nil

            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance

            tabBar.isTranslucent = true
            tabBar.backgroundImage = UIImage()
        }
    }


    
    func addMiniPlayer() {
        miniPlayer = MiniPlayerView()
        miniPlayer.miniplayer(hide: true)
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
