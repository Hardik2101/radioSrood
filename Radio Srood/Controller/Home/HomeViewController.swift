/// Add Tabbar View 1
import UIKit
import GoogleMobileAds
//import SWRevealViewController
import CoreMedia
import StoreKit

class HomeViewController: UI_VC {
    @IBOutlet private weak var radiosroodTableView: UITableView!
    @IBOutlet weak var pageView: UIPageControl!
    
    @IBOutlet weak var vwAds: UIView!
    @IBOutlet weak var heightOfAdsView: NSLayoutConstraint!
    @IBOutlet weak var imgAdClose: UIImageView!
    
    var interstitial: GADInterstitial!
    var isInterstitialPresent = false
    //    var nativeAd: [GADUnifiedNativeAd] = []
    var adLoader: GADAdLoader!
    var dataHelper: DataHelper!
    var homeMusic: HomeMusicModles?
    var currentLyricData: CurrentLyricDataModle?
    var homeHeader: HomeHeader = .hotTrackes
    var groupID: Int?
    var timeObserver: Any?
    var playList: [PlayListModel] = []
    var recenltPlayed: [SongModel] = []
    var recenltPlayedindex: Int?
    var myPlayListindex: Int?
    var homeHeaderArray: [String] = HomeHeader.allCases.map({ $0.title })
    var bannerView: GADBannerView!
    
    private var isPurchaseSuccess: Bool = false
    var bannerAdViews: [GADBannerView] = []
    
    var timer = Timer()
    var counter = 0
    var featuredTop: [FeaturedTop]?
    var todayTopPic: [RadioSuroodTodayPickItem]? = nil
    var recenltyAdded: [RecentlyAdded]? = nil
    var isTodayTopPicLoaded = false
    var isRecentlyAddedLoaded = false


    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareView()
        self.vwAds.isHidden = true
        self.imgAdClose.isHidden = true
        self.heightOfAdsView.constant = 0
        radiosroodTableView.register(UINib(nibName: "BannerAdCell", bundle: nil), forCellReuseIdentifier: "BannerAdCell")
        loadBannerAds()
        
        pageView.numberOfPages = featuredTop?.count ?? 0
        pageView.currentPage = 0
//        DispatchQueue.main.async {
//            self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.changeImage), userInfo: nil, repeats: true)
//        }
        self.loadFeaturedArtistData()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        radiosroodTableView.reloadData()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureCurrentPlayingSong()
        loadCurrentLyricData()
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        let font = UIFont.systemFont(ofSize: 23) // Adjust the font size as needed
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: font ]
        navigationController?.navigationBar.titleTextAttributes = attributes
        self.navigationController?.navigationBar.topItem?.title = "RADIO SROOD"
        self.navigationController?.navigationBar.backItem?.title = "RADIO SROOD"
        navigationController?.navigationBar.isTranslucent = true
        if let interstitial = interstitial {
            if !interstitial.isReady {
                loadInterstitial()
            }
        }
        handleTableView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleIAPPurchase), name: .PurchaseSuccess, object: nil)
        
        let purchase = IAPHandler.shared.isGetPurchase()
        
        if purchase || isPurchaseSuccess {
            self.vwAds.isHidden = true
            self.imgAdClose.isHidden = true
            self.heightOfAdsView.constant = 0
//            isPurchaseSuccess = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
            if purchase || self.isPurchaseSuccess {
                self.vwAds.isHidden = true
                self.imgAdClose.isHidden = true
                self.heightOfAdsView.constant = 0
//            isPurchaseSuccess = false
            }
        })
        getTodayTopPicData()
        getRecentlyAddedData()


    }
    private func loadFeaturedArtistData() {
        dataHelper.getFeaturedArtistSponserdData { [weak self] resp in
            guard let self = self else { return }
            if let resp = resp {
                self.featuredTop = resp.featuredTop
                
//                DispatchQueue.main.async {
//                    self.startImageChangeTimer()
//                }
            }
        }
    }
    
    private func handleTableView() {
        playList = UserDefaultsManager.shared.playListsData
        fetchRecentlyPlayed()
        handleHomeHeaderArrayValue()
    }
    
    private func handleHomeHeaderArrayValue() {
        homeHeaderArray = HomeHeader.allCases.map({ $0.title })
        if recenltPlayed.count <= 0 {
            homeHeaderArray.remove(at: 9)
        }
        if playList.count <= 0 {
            homeHeaderArray.remove(at: 8)
        }
//        if nativeAd.count > 0 {
            homeHeaderArray.insert("Native Ad First", at: 5)
//            if nativeAd.count >= 2 {
                homeHeaderArray.insert("Native Ad Second", at: homeHeaderArray.count-1)
//            }
//        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isInterstitialPresent {
            isInterstitialPresent = false
        }
    }
    
    
    private func prepareView() {
        radiosroodTableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: Common.screenSize.width, height: 0.1))
        radiosroodTableView.tableFooterView = nil
        if #available(iOS 15.0, *) {
            radiosroodTableView.sectionHeaderTopPadding = 0
        }
        loadInterstitial()
        loadRedioHomeData()
        loadBannerAd()
        vwAds.isHidden = true
        imgAdClose.isHidden = true
        heightOfAdsView.constant = 0
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(vwAdsTapped))
        imgAdClose.addGestureRecognizer(tapGesture)
        imgAdClose.isUserInteractionEnabled = true
        
//        self.view!.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
    }
    
    @objc private func vwAdsTapped() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "IAPVC") as! IAPVC
        vc.isshowbackButton = true
        let navVC = UINavigationController(rootViewController: vc)
        navVC.navigationBar.isHidden = true
        navVC.modalPresentationStyle = .fullScreen
        self.present(navVC, animated: true)
    }
    
    func fetchRecentlyPlayed() {
        let savedTracks = UserDefaultsManager.shared.localTracksData
        recenltPlayed = savedTracks.filter({$0.isRecentlyPlayed})
        recenltPlayed = recenltPlayed.reversed()
        radiosroodTableView.reloadData()
    }
    
    func loadBannerAds() {
        guard !IAPHandler.shared.isGetPurchase() else {
            return
        }
        
        let adView1 = GADBannerView(adSize: kGADAdSizeBanner)
        adView1.adUnitID = GOOGLE_ADMOB_ForMusicPlayer
        adView1.rootViewController = self
        adView1.delegate = self
        adView1.load(GADRequest())
        
        let adView2 = GADBannerView(adSize: kGADAdSizeBanner)
        adView2.adUnitID = GOOGLE_ADMOB_ForMiniPlayer
        adView2.rootViewController = self
        adView2.delegate = self
        adView2.load(GADRequest())
        
        bannerAdViews = [adView1, adView2]
    }
    
    
    private func loadCurrentLyricData() {
        dataHelper = DataHelper()
        dataHelper.getCurrentLyricDataInModle { [weak self] resp in
            guard let self = self else { return }
            if let resp = resp {
                self.currentLyricData = resp
                self.radiosroodTableView.reloadData()
            }
        }
    }
    
    private func loadRedioHomeData() {
        dataHelper = DataHelper()
        dataHelper.getRedioHomeData { [weak self] resp in
            guard let self = self else { return }
            if let resp = resp {
                self.homeMusic = resp
                self.radiosroodTableView.reloadData()
            }
        }
    }
    
    private func getTodayTopPicData() {
        dataHelper = DataHelper()
        dataHelper.getTodayTopPicData { [weak self] resp in
            guard let self = self else { return }
            if let resp = resp {
                self.todayTopPic = resp.items
                self.isTodayTopPicLoaded = true
                DispatchQueue.main.async {
                    self.radiosroodTableView.reloadData()
                }
            }
        }
    }

    
    private func getRecentlyAddedData() {
        
        dataHelper = DataHelper()
        
        dataHelper.getRecentlyAddedData { [weak self] resp in
            guard let self = self else { return }
            if let resp = resp {
                self.recenltyAdded = resp.items
                self.isRecentlyAddedLoaded = true
                DispatchQueue.main.async {
                    self.radiosroodTableView.reloadData()
                }
            }
        }
    }

    
    private func setHeaderData(headerTitle: String, isShowShowAll: Bool = false) -> UIView {
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: 20))
        let lblTitle = UILabel(frame: CGRect(x: 15, y: 3, width: screenSize.width - 30, height: 20))
        lblTitle.text = headerTitle
        lblTitle.textColor = .white.withAlphaComponent(0.8)
        lblTitle.font = UIFont(name: "Kohinoor Telugu Light", size: 17)
        containerView.addSubview(lblTitle)
        
        let showAllBtn = CustomButton(frame: CGRect(x: screenSize.width - 100, y: -4, width: 100, height: 35))
        showAllBtn.setTitle(isShowShowAll ? "Show All" : "", for: .normal)
        showAllBtn.setTitleColor(.white, for: .normal)
        showAllBtn.titleLabel?.font = UIFont(name: "Kohinoor Telugu Medium", size: 17)
        showAllBtn.setFuncFor(event: .touchUpInside) { btn in self.onClickShowAll(type: headerTitle) }
        containerView.addSubview(showAllBtn)
        
        containerView.backgroundColor = .primaryDark
        return containerView
    }
    
    func onClickShowAll(type: String) {
        switch type {
            
        case HomeHeader.playlists.title: popularTracksShowAll()
//        case Browseheader.playlist.title:       playlistsShowAll()
//        case Browseheader.newMusic.title:       newReleasesShowAll()
//        case Browseheader.popularMusic.title:   popularTracksShowAll()
//        case Browseheader.radio.title:          browseRadioShowAll()
//        case Browseheader.recentlyPlay.title:   recentlyPlayedShowAll()
        default:
            let vc = self.storyboard.vc(RadioWithRecentViewController.self)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
    func popularTracksShowAll() {
        let showAllVC = storyboard.vc(BrowseShowAllVC.self)
        showAllVC.parentVC1 = self
        showAllVC.popularTracks = homeMusic?.popularTracks ?? []
        self.navigationController?.pushViewController(showAllVC, animated: true)
    }
    
    func configureCurrentPlayingSong() {
        if !(player?.isPlaying ?? false){
            //self.heightMiniPlayer.constant = 0
            self.heightOfAdsView.constant = 0
            self.vwAds.isHidden = true
            self.imgAdClose.isHidden = true
            
        } else {
            //self.heightMiniPlayer.constant = 60
            let purchase = IAPHandler.shared.isGetPurchase()
            
            if !purchase {
                self.heightOfAdsView.constant = 40
                self.vwAds.isHidden = false
                self.imgAdClose.isHidden = false
            } else {
                if purchase || self.isPurchaseSuccess {
                    self.heightOfAdsView.constant = 0
                    self.vwAds.isHidden = true
                    self.imgAdClose.isHidden = true
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                if purchase || self.isPurchaseSuccess {
                    self.heightOfAdsView.constant = 0
                    self.vwAds.isHidden = true
                    self.imgAdClose.isHidden = true
                }
            })
        }
        //(self.tabBarController as? TabbarVC)?.miniPlayer.refreshMiniplayer()
    }
    
    func newFeaturedCell(with tableView: UITableView) -> UITableViewCell {
        if let cell = tableView.registerAndGet(cell: NewFeaturedCell.self) {
            cell.selectionStyle = .none
            if let newReleases = featuredTop {
                cell.presentView = self
                cell.featuredTop = newReleases
                cell.newFeaturedsCollectionView.reloadData()
            }
            return cell
        }
        return UITableViewCell()
    }
    
    
    func newRecentlyAddedCell(with tableView: UITableView) -> UITableViewCell {
        if let cell = tableView.registerAndGet(cell: NewReleasesCell.self),
           let recentlyAdded = recenltyAdded,
           isRecentlyAddedLoaded {
            cell.selectionStyle = .none
            cell.configureCell(withRecentlyAdded: recentlyAdded, presenter: self)
            return cell
        }
        return UITableViewCell()
    }

    func newReleasesCell(with tableView: UITableView) -> UITableViewCell {
        if let cell = tableView.registerAndGet(cell: NewReleasesCell.self),
           let newReleases = homeMusic?.newReleases {
            cell.selectionStyle = .none
            cell.configureCell(withNewReleases: newReleases, presenter: self)
            return cell
        }
        return UITableViewCell()
    }

    func currentRadioCell(with tableView: UITableView) -> UITableViewCell {
        if let cell = tableView.registerAndGet(cell: CurrentRadioCell.self) {
            cell.selectionStyle = .none
            if let currentLyricData = self.currentLyricData {
                cell.currentTrackInfo = currentLyricData.currentTrackInfo
            }
            return cell
        }
        return UITableViewCell()
    }
    
    func trendingCell(with tableView: UITableView) -> UITableViewCell {
        if let cell = tableView.registerAndGet(cell: TrackCell.self) {
            cell.selectionStyle = .none
            if let trendingTracks = homeMusic?.trendingTracks {
                cell.presentView = self
                cell.trendingTracks = trendingTracks
                cell.reloadCollectionView()
            }
            return cell
        }
        return UITableViewCell()
    }
    
    func popularTracksCell(with tableView: UITableView) -> UITableViewCell {
        if let cell = tableView.registerAndGet(cell: TrackCell.self) {
            cell.selectionStyle = .none
            if let popularTracks = homeMusic?.popularTracks {
                cell.presentView = self
                cell.trendingTracks.removeAll()
                cell.popularTracks = popularTracks
                cell.reloadCollectionView()
            }
            return cell
        }
        return UITableViewCell()
    }
    
    func playlistsCell(with tableView: UITableView) -> UITableViewCell {
        if let cell = tableView.registerAndGet(cell: PlaylistCell.self) {
            cell.selectionStyle = .none
            if let playlists = homeMusic?.playlists {
                cell.presentView = self
                cell.playlist = playlists
                cell.reloadCollectionView()
            }
            return cell
        }
        return UITableViewCell()
    }
    
    func recentlyPlayedCell(with tableView: UITableView) -> UITableViewCell {
        let recentTracks = self.recenltPlayed.map { $0.convertToPodcastModel() }
        if let cell = tableView.registerAndGet(cell: RecentlyPlayedCell.self), recentTracks.count > 0 {
            cell.selectionStyle = .none
            cell.presentView = self
            cell.trackData = recentTracks
            cell.reloadCollectionView()
            return cell
        }
        return UITableViewCell()
    }
    
    func myPlaylistCell(with tableView: UITableView) -> UITableViewCell {
        if let cell = tableView.registerAndGet(cell: MyPlaylistCell.self), playList.count > 0 {
            cell.selectionStyle = .none
            cell.presentView = self
            cell.playList = playList
            cell.reloadCollectionView()
            return cell
        }
        return UITableViewCell()
    }
    
    func featuredArtistCell(with tableView: UITableView) -> UITableViewCell {
        if let cell = tableView.registerAndGet(cell: ArtistCell.self) {
            cell.selectionStyle = .none
            if let featuredArtist = homeMusic?.featuredArtist {
                cell.presentView = self
                cell.featuredArtist = featuredArtist
                cell.reloadCollectionView()
            }
            return cell
        }
        return UITableViewCell()
    }
    
    func todayTopPicCell(with tableView: UITableView) -> UITableViewCell {
        if let cell = tableView.registerAndGet(cell: BrowsePopularTableCell.self) {
            cell.selectionStyle = .none
            if let todayTopPica = todayTopPic, isTodayTopPicLoaded {
                cell.presentViewBrowse1 = self
                cell.todayTopPic = todayTopPica
                cell.reloadCollectionView()
            }
            return cell
        }
        return UITableViewCell()
    }
    
    func bannerAdCell(with tableView: UITableView, index: Int) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "BannerAdCell", for: IndexPath(row: 0, section: index)) as? BannerAdCell {
            
            // Remove any existing subviews from vwMain
            for subview in cell.vwMain.subviews {
                subview.removeFromSuperview()
            }
            
            // Configure the cell based on conditions
            if IAPHandler.shared.isGetPurchase() || isPurchaseSuccess {
                cell.vwMain.isHidden = true
                cell.heightOfVw.constant = 0
            } else {
                cell.vwMain.isHidden = false
                cell.heightOfVw.constant = 65
                
                if bannerAdViews.indices.contains(index) {
                    let bannerView = bannerAdViews[index]
                    cell.vwMain.addSubview(bannerView)
                    
                    // Set the banner view frame using constraints or autoresizing mask
                    bannerView.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        bannerView.leadingAnchor.constraint(equalTo: cell.vwMain.leadingAnchor),
                        bannerView.trailingAnchor.constraint(equalTo: cell.vwMain.trailingAnchor),
                        bannerView.topAnchor.constraint(equalTo: cell.vwMain.topAnchor),
                        bannerView.bottomAnchor.constraint(equalTo: cell.vwMain.bottomAnchor)
                    ])
                }
            }
            
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    func openRadioWithRecentViewController() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "RadioWithRecentViewController") as! RadioWithRecentViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func openMusicPlayerViewController() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MusicPlayerViewController") as! MusicPlayerViewController
        print("*-*-*-* \(groupID ?? -1) \(homeHeader) \(#function)")
        vc.groupID = groupID
        groupID = nil
        vc.homeHeader = homeHeader
        vc.modalPresentationStyle = .overCurrentContext
        
        self.present(vc, animated: true)//navigationController?.pushViewController(vc, animated: true)
//        AppPlayer.miniPlayerInfo = BasicDetail(
//            musicVC: vc
//        )
//        vc.prepareView()
        
        
        
    }
    
    func openMyMusicPlayerViewController(index: Int) {
        let recentTracks = self.recenltPlayed.map { $0.convertToPodcastModel() }
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MyMusicPlayerViewController") as! MyMusicPlayerViewController
        vc.selectedIndex = index
        vc.tempTrack = recentTracks
        vc.track = recentTracks
        self.present(vc, animated: true)
        //navigationController?.pushViewController(vc, animated: true)
    }
    
    func openMyPlayList(index: Int) {
        let playListSongs = self.playList[index].songs.map { $0.convertToPodcastModel() }
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MyMusicViewController") as! MyMusicViewController
        vc.isForLikes = true
        vc.isMyPlaylist = true
        vc.trackData = playListSongs
        self.present(vc, animated: true)
    }
    
    func handleMyPlayListItemEvent(_ index: Int) {
        let alert = UIAlertController(title: "Delete My Playlist", message: "Are you sure you want to delete \(playList[index].name) playlist", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in  })
        alert.addAction(UIAlertAction(title: "Delete", style: .default) { [weak self] action in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.playList.remove(at: index)
                UserDefaultsManager.shared.playListsData = self.playList
                self.handleHomeHeaderArrayValue()
                self.radiosroodTableView.reloadData()
            }
        })
        self.present(alert, animated: true)
    }
    
    @objc private func handleIAPPurchase() {
        self.isPurchaseSuccess = true
        vwAds.isHidden = true
        imgAdClose.isHidden = true
        heightOfAdsView.constant = 0
        radiosroodTableView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 50, execute: {
            self.isPurchaseSuccess = false
        })
    }
    
    // Update the loadBannerAd function to add the banner to vwAds
    func loadBannerAd() {
        guard !IAPHandler.shared.isGetPurchase() else {
            // Skip loading the ad if the purchase is made
            return
        }
        
        // Create the banner view
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        bannerView.adUnitID = GOOGLE_ADMOB_ForMiniPlayer
        bannerView.rootViewController = self
        bannerView.delegate = self
        bannerView.load(GADRequest())
        
        // Set the banner view frame
        bannerView.frame =  self.vwAds.bounds        // Remove any existing subviews from vwAds
        for subview in vwAds.subviews {
            subview.removeFromSuperview()
        }
        
        // Add the banner to vwAds
        vwAds.addSubview(bannerView)
        
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bannerView.leadingAnchor.constraint(equalTo: vwAds.leadingAnchor),
            bannerView.trailingAnchor.constraint(equalTo: vwAds.trailingAnchor),
            bannerView.topAnchor.constraint(equalTo: vwAds.topAnchor),
            bannerView.bottomAnchor.constraint(equalTo: vwAds.bottomAnchor)
        ])
    }
    
    deinit {
        print("Remove HomeViewController from memory")
    }
}

extension HomeViewController : MusicPlayerViewControllerDelegate{
    func dismissMusicPlayer() {
        self.configureCurrentPlayingSong()
        handleTableView()
        radiosroodTableView.reloadData()
        fixMiniplayerSpace()
    }
}

//MARK: - tableview delegates methods
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return homeHeaderArray.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch homeHeaderArray[indexPath.section] {
        case "Featured":
            return newFeaturedCell(with: tableView)
        case "Recently Added":
            return newRecentlyAddedCell(with: tableView)
        case "Today Top Picks":
            return todayTopPicCell(with: tableView)
        case "Hot Tracks":
            return newReleasesCell(with: tableView)
        case "Currently Playing on Radio srood":
            return currentRadioCell(with: tableView)
        case "Trending":
            return trendingCell(with: tableView)
        case "Popular Tracks":
            return popularTracksCell(with: tableView)
        case "Playlists":
            return playlistsCell(with: tableView)
        case "My Playlist":
            return myPlaylistCell(with: tableView)
        case "Recently Played":
            return recentlyPlayedCell(with: tableView)
        case "Featured Artist":
            return featuredArtistCell(with: tableView)
        case "Native Ad First":
            return bannerAdCell(with: tableView, index: 0)
        default:
            return bannerAdCell(with: tableView, index: 1)
        }
    }
    
    func  tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sectionTitle = homeHeaderArray[indexPath.section]

        switch sectionTitle {
        case "Currently Playing on Radio srood":
            homeHeader = .currentRadio
            if interstitial != nil {
                interstitial.present(fromRootViewController: self)
            } else {
                openRadioWithRecentViewController()
            }

        case "Today Top Picks":
            homeHeader = .todayTopPic
            if interstitial != nil {
                interstitial.present(fromRootViewController: self)
            } else {
                openMusicPlayerViewController()
            }

        // You can add more cases here if needed
        default:
            break
        }
    }

    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch homeHeaderArray[section] {
        case "Featured":
            return setHeaderData(headerTitle: HomeHeader.featured.title)
        case "Recently Added":
            return setHeaderData(headerTitle: HomeHeader.recentlyAdded.title)
            case "Today Top Picks":
            return setHeaderData(headerTitle: HomeHeader.todayTopPic.title)
        case "Hot Tracks":
            return setHeaderData(headerTitle: HomeHeader.hotTrackes.title)
        case "Currently Playing on Radio srood":
            return setHeaderData(headerTitle: "")
        case "Trending":
            return setHeaderData(headerTitle: HomeHeader.trending.title)
        case "Popular Tracks":
            return setHeaderData(headerTitle: HomeHeader.popularTracks.title)
        case "Playlists":
            return setHeaderData(headerTitle: HomeHeader.playlists.title)
        case "My Playlist":
            return setHeaderData(headerTitle: HomeHeader.myPlaylist.title)
        case "Recently Played":
            return setHeaderData(headerTitle: HomeHeader.recentlyPlayed.title)
        case "Featured Artist":
            return setHeaderData(headerTitle: HomeHeader.featuredArtist.title)
        case "Native Ad First":
            return nil
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch homeHeaderArray[section] {
        case "Featured":
            return 27
        case "Recently Added":
            return 27
        case "Today Top Picks":
            return 27
        case "Hot Tracks":
            return 27
        case "Currently Playing on Radio srood":
            return 0
        case "Trending":
            return 27
        case "Popular Tracks":
            return 27
        case "Playlists":
            return 27
        case "My Playlist":
            return 27
        case "Recently Played":
            return 27
        case "Featured Artist":
            return 27
        case "Native Ad First":
            return 0
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sectionTitle = homeHeaderArray[indexPath.section]
        
        if sectionTitle == "Currently Playing on Radio srood" {
            return 0 // 🔒 Hide this row completely
        }

        // Return normal heights for other sections
        return UITableView.automaticDimension
    }

}

//extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return self.featuredTop?.count ?? 0
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewHomeCollectionViewCell", for: indexPath) as! NewHomeCollectionViewCell
//
//        let featuredItem = self.featuredTop?[indexPath.row]
//        print("aaaaaaa==1", featuredItem?.featuredImage)
//        if let url = URL(string: featuredItem?.featuredImage ?? "") {
//            cell.imgView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
//        }
//
//        return cell
//    }
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let featuredItem = self.featuredTop?[indexPath.row]
//
//        // Check if the item is sponsored and print the appropriate message
//        if featuredItem?.sponsored == true {
//            if let url = URL(string: featuredItem?.externalLink ?? "https://instagram.com/RadioSrood") {
//                UIApplication.shared.open(url, options: [:], completionHandler: nil)
//            }
//        } else {
//            let vc = self.storyboard?.instantiateViewController(withIdentifier: "MusicPlayerViewController") as! MusicPlayerViewController
//            vc.groupID = featuredItem?.featuredSongID
//            groupID = nil
//            vc.delegate = self
//            vc.homeHeader = homeHeader
//            vc.isSponser = true
//            vc.modalPresentationStyle = .overCurrentContext
//            self.present(vc, animated: true)
//        }
//
////        openMusicPlayerViewController()
////        print(indexPath.row)
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
//        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let size = sliderCollectionView.frame.size
//        return CGSize(width: size.width, height: size.height)
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
//        return 0.0
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
//        return 0.0
//    }
//
//}

extension HomeViewController: GADInterstitialDelegate {
    
    private func loadInterstitial() {
        guard !IAPHandler.shared.isGetPurchase() else {
            // Skip loading the ad if the purchase is made
            return
        }
        
        interstitial = GADInterstitial(adUnitID: GOOGLE_ADMOB_INTER)
        interstitial!.delegate = self
        interstitial!.load(GADRequest())
    }
    
    func interstitialDidFailToReceiveAdWithError (
        interstitial: GADInterstitial,
        error: GADRequestError) {
            print("interstitialDidFailToReceiveAdWithError: %@" + error.localizedDescription)
        }
    
    func interstitialDidDismissScreen (_ interstitial: GADInterstitial) {
        print("interstitialDidDismissScreen")
        switch homeHeader {
        case .hotTrackes, .trending, .popularTracks, .playlists, .featuredArtist, .featured:
            openMusicPlayerViewController()
        case .currentRadio:
            openRadioWithRecentViewController()
        case .recentlyPlayed:
            if let recenltPlayedindex = recenltPlayedindex {
                openMyMusicPlayerViewController(index: recenltPlayedindex)
            }
        case .myPlaylist:
            if let myPlayListindex = myPlayListindex {
                openMyPlayList(index: myPlayListindex)
            }
        case .todayTopPic:
            openMusicPlayerViewController()
        case .recentlyAdded:
            openMusicPlayerViewController()
        }
    }
    
    public func update() {
        if SHOW_BANNER_ADMOB {banners()}
    }
    
    func banners(){
        guard !IAPHandler.shared.isGetPurchase() else {
            return
        }
        
        if (interstitial!.isReady) {
            isInterstitialPresent = true
            interstitial!.present(fromRootViewController: self)
        } else {
            loadInterstitial()
        }
    }
    
}

/*extension HomeViewController: GADAdLoaderDelegate, GADUnifiedNativeAdLoaderDelegate {
 
 func loadNativeAd() {
 guard !IAPHandler.shared.isGetPurchase() else {
 // Skip loading the ad if the purchase is made
 return
 }
 
 self.nativeAd.removeAll()
 let multipleAdsOptions = GADMultipleAdsAdLoaderOptions()
 multipleAdsOptions.numberOfAds = 2
 adLoader = GADAdLoader(adUnitID: GOOGLE_ADMOB_NATIVE,
 rootViewController: self,
 adTypes: [.unifiedNative],
 options: [multipleAdsOptions])
 adLoader.delegate = self
 adLoader.load(GADRequest())
 }
 
 func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADUnifiedNativeAd) {
 guard !IAPHandler.shared.isGetPurchase() else {
 return
 }
 
 self.nativeAd.append(nativeAd)
 handleHomeHeaderArrayValue()
 radiosroodTableView.reloadData()
 }
 
 func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: GADRequestError) {
 print("\(adLoader) failed with error: \(error.localizedDescription)")
 }
 
 } */

extension HomeViewController: GADBannerViewDelegate {
    
    // MARK: - GADBannerViewDelegate
    
    // Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("Ad received successfully")
    }
    
    // Tells the delegate an ad request failed.
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        print("Ad failed to load: \(error.localizedDescription)")
    }
    
    // Tells the delegate that a full-screen view will be presented in response to the user clicking on an ad.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("Ad will present a full-screen view")
    }
    
    // Tells the delegate that the full-screen view will be dismissed.
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("Full-screen view will be dismissed")
    }
    
    // Tells the delegate that the full-screen view has been dismissed.
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("Full-screen view has been dismissed")
    }
    
    // Tells the delegate that a user click will open another app (such as the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        print("User click will leave the application")
    }
}
