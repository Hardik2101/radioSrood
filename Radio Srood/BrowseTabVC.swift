////////////////
////////////////  BrowseTabVC.swift
////////////////  Radio Srood
////////////////
////////////////  Created by Hardik on 04/10/24.
////////////////  Copyright © 2024 Radio Srood Inc. All rights reserved.
////////////////

import UIKit
import GoogleMobileAds
import CoreMedia
import StoreKit
import AVKit


class BrowseTabVC: UIViewController {
    
    @IBOutlet weak var tblBrowse: UITableView! {
        didSet {
            self.tblBrowse.delegate = self
            self.tblBrowse.dataSource = self
        }
    }
    
    
    var interstitial: GADInterstitial!
    var isInterstitialPresent = false
////////////////    var nativeAd: [GADUnifiedNativeAd] = []
    var adLoader: GADAdLoader!
    var dataHelper: DataHelper!
    var homeMusic: HomeMusicModles?
    var currentLyricData: CurrentLyricDataModle?
//    var Browseheader: Browseheader = .newReleases
    var browseheader: Browseheader = .playlist // Use the global Browseheader
    var groupID: Int?
    var timeObserver: Any?
    var playList: [PlayListModel] = []
    var recenltPlayed: [SongModel] = []
    var recenltPlayedindex: Int?
    var myPlayListindex: Int?
    var BrowseheaderArray: [String] = Browseheader.allCases.map({ $0.title })
    var bannerView: GADBannerView!

    private var isPurchaseSuccess: Bool = false
    var bannerAdViews: [GADBannerView] = []
    var radioModel: [RadioModelData] = []

    
    var timer = Timer()
    var counter = 0
    var featuredTop: [FeaturedTop]?

        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareView()
//        self.vwAds.isHidden = true
//        self.imgAdClose.isHidden = true
//        self.heightOfAdsView.constant = 0
        tblBrowse.register(UINib(nibName: "BannerAdCell", bundle: nil), forCellReuseIdentifier: "BannerAdCell")
        tblBrowse.register(UINib(nibName: "RJTVTableViewCell", bundle: nil), forCellReuseIdentifier: "RJTVTableViewCell")
//        loadBannerAds()
//        
//        pageView.numberOfPages = featuredTop?.count ?? 0
//        pageView.currentPage = 0
////////////////        DispatchQueue.main.async {
////////////////            self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.changeImage), userInfo: nil, repeats: true)
////////////////        }
        loadFeaturedRadioData()
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tblBrowse.reloadData()
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureCurrentPlayingSong()
        loadCurrentLyricData()
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        let font = UIFont.systemFont(ofSize: 23) //////////////// Adjust the font size as needed
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
//            self.vwAds.isHidden = true
//            self.imgAdClose.isHidden = true
//            self.heightOfAdsView.constant = 0
////////////////            isPurchaseSuccess = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
            if purchase || self.isPurchaseSuccess {
//                self.vwAds.isHidden = true
//                self.imgAdClose.isHidden = true
//                self.heightOfAdsView.constant = 0
    ////////////////            isPurchaseSuccess = false
            }
        })
    }
    

    private func handleTableView() {
        playList = UserDefaultsManager.shared.playListsData
        fetchRecentlyPlayed()
        handleBrowseheaderArrayValue()
    }
    
    private func handleBrowseheaderArrayValue() {
        BrowseheaderArray = Browseheader.allCases.map({ $0.title })
        if recenltPlayed.count <= 0 {
            BrowseheaderArray.remove(at: 4)
        }
//        if playList.count <= 0 {
//            BrowseheaderArray.remove(at: 0)
//        }
////////////////        if nativeAd.count > 0 {
            //BrowseheaderArray.insert("Native Ad First", at: 4)
////////////////            if nativeAd.count >= 2 {
                //BrowseheaderArray.insert("Native Ad Second", at: BrowseheaderArray.count-1)
////////////////            }
////////////////        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if isInterstitialPresent {
            isInterstitialPresent = false
        }
    }
        
    private func prepareView() {

        tblBrowse.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: Common.screenSize.width, height: 0.1))
        tblBrowse.tableFooterView = nil
        if #available(iOS 15.0, *) {
            tblBrowse.sectionHeaderTopPadding = 0
        }
        loadInterstitial()
        loadRedioHomeData()
        loadBannerAd()
//        vwAds.isHidden = true
//        imgAdClose.isHidden = true
//        heightOfAdsView.constant = 0
        
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(vwAdsTapped))
//        imgAdClose.addGestureRecognizer(tapGesture)
//        imgAdClose.isUserInteractionEnabled = true

////////////////        self.view!.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
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
        tblBrowse.reloadData()
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
                self.tblBrowse.reloadData()
            }
        }
    }
    
    private func loadRedioHomeData() {
        dataHelper = DataHelper()
        dataHelper.getRedioHomeData { [weak self] resp in
            guard let self = self else { return }
            if let resp = resp {
                self.homeMusic = resp
                self.tblBrowse.reloadData()
            }
        }
    }
    
    func playlistsShowAll() {
        let showAllVC = storyboard.vc(BrowseShowAllVC.self)
        showAllVC.parentVC = self
        showAllVC.playlist = homeMusic?.playlists ?? []
        self.navigationController?.pushViewController(showAllVC, animated: true)
    }
    
    func newReleasesShowAll() {
        let showAllVC = storyboard.vc(BrowseShowAllVC.self)
        showAllVC.parentVC = self
        showAllVC.newReleases = homeMusic?.newReleases ?? []
        self.navigationController?.pushViewController(showAllVC, animated: true)
    }
    
    func popularTracksShowAll() {
        let showAllVC = storyboard.vc(BrowseShowAllVC.self)
        showAllVC.parentVC = self
        showAllVC.popularTracks = homeMusic?.popularTracks ?? []
        self.navigationController?.pushViewController(showAllVC, animated: true)
    }
    
    func browseRadioShowAll() {
        let showAllVC = storyboard.vc(BrowseShowAllVC.self)
        showAllVC.parentVC = self
        showAllVC.radioModels = radioModel
        self.navigationController?.pushViewController(showAllVC, animated: true)
    }
    
    func recentlyPlayedShowAll() {
        let showAllVC = storyboard.vc(BrowseShowAllVC.self)
        showAllVC.parentVC = self
        showAllVC.recenltPlayed = self.recenltPlayed
        self.navigationController?.pushViewController(showAllVC, animated: true)
    }
    
    func onClickShowAll(type: String) {
        switch type {
        case Browseheader.playlist.title:       playlistsShowAll()
        case Browseheader.newMusic.title:       newReleasesShowAll()
        case Browseheader.popularMusic.title:   popularTracksShowAll()
        case Browseheader.radio.title:          browseRadioShowAll()
        case Browseheader.recentlyPlay.title:   recentlyPlayedShowAll()
        default:
            let vc = self.storyboard.vc(RadioWithRecentViewController.self)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func setHeaderData(headerTitle: String, isShowShowAll: Bool = true) -> UIView {
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: 35))
        let lblTitle = UILabel(frame: CGRect(x: 15, y: 0, width: screenSize.width - 100, height: 35))
        lblTitle.text = headerTitle
        lblTitle.textColor = .white.withAlphaComponent(0.8)
        lblTitle.font = UIFont(name: "Kohinoor Telugu Light", size: 23)
        containerView.addSubview(lblTitle)
        
        let showAllBtn = CustomButton(frame: CGRect(x: screenSize.width - 100, y: 0, width: 100, height: 35))
        showAllBtn.setTitle(isShowShowAll ? "Show All" : "", for: .normal)
        showAllBtn.setTitleColor(.white, for: .normal)
        showAllBtn.titleLabel?.font = UIFont(name: "Kohinoor Telugu Medium", size: 17)
        showAllBtn.setFuncFor(event: .touchUpInside) { btn in self.onClickShowAll(type: headerTitle) }
        containerView.addSubview(showAllBtn)
        
        containerView.backgroundColor = .primaryDark
        return containerView
    }
    
//    @IBAction func actionPlayPause(_ sender: Any) {
//        if (player?.isPlaying ?? false){
//            player?.pause()
//            self.btnPlayPause.setImage(UIImage(named: "ic_play"), for: .normal)
//           
//        } else {
//            player?.play()
//            self.btnPlayPause.setImage(UIImage(named: "ic_pause"), for: .normal)
//        }
//    }
//    @IBAction func actionOpenSong(_ sender: Any) {
//        guard let vc = songController else {
//            print("songController is nil")
//            return
//        }
//
//        if presentedViewController == nil && !vc.isBeingPresented {
//            self.present(vc, animated: true, completion: nil)
//        } else {
//            print("A view controller is already being presented or songController is already presented")
//        }
//    }
    
    func configureCurrentPlayingSong() {
        //(self.tabBarController as? TabbarVC)?.miniPlayer.refreshMiniplayer()
    }
    
    @objc func playerDidFinishPlaying(sender: Notification) {
//        viewSongProgress.progress = 0.0
        player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    func newReleasesCell(with tableView: UITableView) -> UITableViewCell {//
        if let cell = tableView.registerAndGet(cell: BrowseTableCell.self) {
            cell.selectionStyle = .none
            if let newReleases = homeMusic?.newReleases {
                cell.presentViewBrowse = self
                cell.playlist.removeAll()
                cell.newReleases = newReleases
                cell.reloadCollectionView()
            }
            return cell
        }
        return UITableViewCell()
    }
    
    func popularTracksCell(with tableView: UITableView) -> UITableViewCell {//
        if let cell = tableView.registerAndGet(cell: BrowsePopularTableCell.self) {
            cell.selectionStyle = .none
            if let popularTracks = homeMusic?.popularTracks {
                cell.presentViewBrowse = self
                cell.trendingTracks.removeAll()
                cell.popularTracks = popularTracks
                cell.reloadCollectionView()
            }
            return cell
        }
        return UITableViewCell()
    }
    
    func playlistsCell(with tableView: UITableView) -> UITableViewCell {//
        if let cell = tableView.registerAndGet(cell: BrowseTableCell.self) {
            cell.selectionStyle = .none
            if let playlists = homeMusic?.playlists {
                cell.presentViewBrowse = self
                cell.playlist = playlists
                cell.newReleases.removeAll()
                cell.reloadCollectionView()
            }
            return cell
        }
        return UITableViewCell()
    }
    
    
    func browseRadioCell(with tableView: UITableView) -> UITableViewCell {
        if let cell = tableView.registerAndGet(cell: BrowseRadioTableCell.self) {
            cell.selectionStyle = .none
            cell.presentViewBrowse = self
            cell.radioModel = self.radioModel
            cell.reloadCollectionView()
            return cell
        }
        return UITableViewCell()
    }

    func recentlyPlayedCell(with tableView: UITableView) -> UITableViewCell {//
        let recentTracks = self.recenltPlayed.map { $0.convertToPodcastModel() }
        if let cell = tableView.registerAndGet(cell: RecentlyPlayedCell.self), recentTracks.count > 0 {
            cell.selectionStyle = .none
            cell.presentViewBrowse = self
            cell.trackData = recentTracks
            cell.reloadCollectionView()
            return cell
        }
        return UITableViewCell()
    }
    
    func rjTvCell(with tableView: UITableView) -> UITableViewCell {
        if let cell = tableView.registerAndGet(cell: RJTVTableViewCell.self) {
            cell.selectionStyle = .none
            
            print("aaaaa====")
            return cell
        }
        return UITableViewCell()
    }


    private func loadFeaturedRadioData() {
        dataHelper = DataHelper()
        dataHelper.getFeaturedRadioData { [weak self] resp in
            guard let self = self else { return }
            if let resp = resp {
                self.radioModel = resp.radio//+resp.radio+resp.radio+resp.radio+resp.radio
                self.tblBrowse.reloadData()
            }
        }
    }
    
    func bannerAdCell(with tableView: UITableView, index: Int) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "BannerAdCell", for: IndexPath(row: 0, section: index)) as? BannerAdCell {
            
            //////////////// Remove any existing subviews from vwMain
            for subview in cell.vwMain.subviews {
                subview.removeFromSuperview()
            }

            //////////////// Configure the cell based on conditions
            if IAPHandler.shared.isGetPurchase() || isPurchaseSuccess {
                cell.vwMain.isHidden = true
                cell.heightOfVw.constant = 0
            } else {
                cell.vwMain.isHidden = false
                cell.heightOfVw.constant = 65
                
                if bannerAdViews.indices.contains(index) {
                    let bannerView = bannerAdViews[index]
                    cell.vwMain.addSubview(bannerView)
                    
                    //////////////// Set the banner view frame using constraints or autoresizing mask
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
        print("*-* \(groupID ?? -1) \(browseheader) \(#function)")
        vc.groupID = groupID
        groupID = nil
        vc.delegate = self
        vc.homeHeader = browseheader.toHomeHeader!
        vc.modalPresentationStyle = .overCurrentContext
        self.present(vc, animated: true)
    }

    func openMyMusicPlayerViewController(index: Int) {
        let recentTracks = self.recenltPlayed.map { $0.convertToPodcastModel() }
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MyMusicPlayerViewController") as! MyMusicPlayerViewController
        vc.selectedIndex = index
        vc.tempTrack = recentTracks
        vc.track = recentTracks
        self.present(vc, animated: true)////////////////navigationController?.pushViewController(vc, animated: true)
    }
    
    let avPlayerViewController = AVPlayerViewController()
    var avPlayer: AVPlayer?
    var vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).vc(RadioViewController.self)
    func onClickRadio(at index: Int) {
        let data_obj  = self.radioModel[index]
        let movieURL = data_obj.radioStreamLink
        if data_obj.radioTitle == "PAMIR TV" {
            guard let url = URL(string: movieURL) else { return }
            let asset = AVAsset(url: url)
            let playerItem = AVPlayerItem(asset: asset)
            self.avPlayer = AVPlayer(playerItem: playerItem)
            self.avPlayerViewController.player = self.avPlayer
            self.present(self.avPlayerViewController, animated: true) { [weak self] in
                self?.avPlayerViewController.player?.play()
            }
            
        } else {
            //NotificationCenter.default.post(name: .pauseRadio, object: nil, userInfo: nil)
            let dict = NSMutableDictionary()
            dict["tv_name"] = data_obj.radioTitle
            dict["image"] = data_obj.radioImage
            dict["tv_stream"] = data_obj.radioStreamLink
            dict["???"] = data_obj.radioID
            
            UserDefaults.standard.setValue(dict, forKey: "NowPlayData2")
            vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).vc(RadioViewController.self)
            self.navigationController?.pushViewController(vc, animated: true)
        }
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
                self.handleBrowseheaderArrayValue()
                self.tblBrowse.reloadData()
            }
        })
        self.present(alert, animated: true)
    }

    @objc private func handleIAPPurchase() {
        self.isPurchaseSuccess = true
//        vwAds.isHidden = true
//        imgAdClose.isHidden = true
//        heightOfAdsView.constant = 0
        tblBrowse.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 50, execute: {
        self.isPurchaseSuccess = false
        })
    }

    //////////////// Update the loadBannerAd function to add the banner to vwAds
    func loadBannerAd() {
        guard !IAPHandler.shared.isGetPurchase() else {
            //////////////// Skip loading the ad if the purchase is made
            return
        }

        //////////////// Create the banner view
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        bannerView.adUnitID = GOOGLE_ADMOB_ForMiniPlayer
        bannerView.rootViewController = self
        bannerView.delegate = self
        bannerView.load(GADRequest())

        //////////////// Set the banner view frame
//        bannerView.frame =  self.vwAds.bounds        //////////////// Remove any existing subviews from vwAds
//        for subview in vwAds.subviews {
//            subview.removeFromSuperview()
//        }
//
        //////////////// Add the banner to vwAds
//        vwAds.addSubview(bannerView)
        
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
//            bannerView.leadingAnchor.constraint(equalTo: vwAds.leadingAnchor),
//            bannerView.trailingAnchor.constraint(equalTo: vwAds.trailingAnchor),
//            bannerView.topAnchor.constraint(equalTo: vwAds.topAnchor),
//            bannerView.bottomAnchor.constraint(equalTo: vwAds.bottomAnchor)
        ])

    }

    deinit {
        print("Remove BrowseTabVC from memory")
    }
    
}

extension BrowseTabVC : MusicPlayerViewControllerDelegate{
    func dismissMusicPlayer() {
        self.configureCurrentPlayingSong()
        handleTableView()
        tblBrowse.reloadData()
    }
}

////////////////MARK: - tableview delegates methods
extension BrowseTabVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return BrowseheaderArray.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch BrowseheaderArray[indexPath.section] {
        case Browseheader.playlist.title:     return playlistsCell(with: tableView)
        case Browseheader.newMusic.title:     return newReleasesCell(with: tableView)
        case Browseheader.popularMusic.title: return popularTracksCell(with: tableView)
        case Browseheader.rjtv.title:         return rjTvCell(with: tableView)
        case Browseheader.radio.title:        return browseRadioCell(with: tableView) // need Radio api call
        case Browseheader.recentlyPlay.title: return recentlyPlayedCell(with: tableView)
        default:
            //"Native Ad First" & "Native Ad Second"
            let cell = UITableViewCell()
            cell.selectionStyle = .none
            cell.textLabel?.text = BrowseheaderArray[indexPath.section]
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = .white
            cell.backgroundColor = .clear
            return cell
        }
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        switch indexPath.section {
//        case 0:
//            browseheader = .playlist
//            if interstitial != nil {
//                interstitial.present(fromRootViewController: self)
//            } else {
//                openRadioWithRecentViewController()
//            }
//        default:
//            break
//        }
//    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch BrowseheaderArray[section] {
        case Browseheader.playlist.title:     return setHeaderData(headerTitle: Browseheader.playlist.title)
        case Browseheader.newMusic.title:     return setHeaderData(headerTitle: Browseheader.newMusic.title)
        case Browseheader.popularMusic.title: return setHeaderData(headerTitle: Browseheader.popularMusic.title)
        case Browseheader.rjtv.title:         return setHeaderData(headerTitle: Browseheader.rjtv.title, isShowShowAll: false)
        case Browseheader.radio.title:        return setHeaderData(headerTitle: Browseheader.radio.title)
        case Browseheader.recentlyPlay.title: return setHeaderData(headerTitle: Browseheader.recentlyPlay.title)
        default:                              return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch BrowseheaderArray[section] {
        case Browseheader.playlist.title:       return 35
        case Browseheader.newMusic.title:       return 35
        case Browseheader.popularMusic.title:   return 35
        case Browseheader.rjtv.title:           return 35
        case Browseheader.radio.title:          return 35
        case Browseheader.recentlyPlay.title:   return 35
        default:                                return 0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 { //indexPath.section == 3
            guard let url = URL(string: "https://live.pamirtv.com/stream/ptv.m3u8") else { return }
            NotificationCenter.default.post(name: .pauseRadio, object: nil, userInfo: nil)
            player = PlayObserver() //killing player before stream
            let asset = AVAsset(url: url)
            let playerItem = AVPlayerItem(asset: asset)
            self.avPlayer = AVPlayer(playerItem: playerItem)
            self.avPlayerViewController.player = self.avPlayer
            self.present(self.avPlayerViewController, animated: true) { [weak self] in
                self?.avPlayerViewController.player?.play()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
      return CGFloat.leastNonzeroMagnitude
    }
}

////////////////extension BrowseTabVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
////////////////    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
////////////////        return self.featuredTop?.count ?? 0
////////////////    }
////////////////
////////////////    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
////////////////        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewHomeCollectionViewCell", for: indexPath) as! NewHomeCollectionViewCell
////////////////
////////////////        let featuredItem = self.featuredTop?[indexPath.row]
////////////////        print("aaaaaaa==1", featuredItem?.featuredImage)
////////////////        if let url = URL(string: featuredItem?.featuredImage ?? "") {
////////////////            cell.imgView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
////////////////        }
////////////////
////////////////        return cell
////////////////    }
////////////////    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
////////////////        let featuredItem = self.featuredTop?[indexPath.row]
////////////////
////////////////        //////////////// Check if the item is sponsored and print the appropriate message
////////////////        if featuredItem?.sponsored == true {
////////////////            if let url = URL(string: featuredItem?.externalLink ?? "https:////////////////instagram.com/RadioSrood") {
////////////////                UIApplication.shared.open(url, options: [:], completionHandler: nil)
////////////////            }
////////////////        } else {
////////////////            let vc = self.storyboard?.instantiateViewController(withIdentifier: "MusicPlayerViewController") as! MusicPlayerViewController
////////////////            vc.groupID = featuredItem?.featuredSongID
////////////////            groupID = nil
////////////////            vc.delegate = self
////////////////            vc.Browseheader = Browseheader
////////////////            vc.isSponser = true
////////////////            vc.modalPresentationStyle = .overCurrentContext
////////////////            self.present(vc, animated: true)
////////////////        }
////////////////
////////////////////////////////        openMusicPlayerViewController()
////////////////////////////////        print(indexPath.row)
////////////////    }
////////////////
////////////////    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
////////////////        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
////////////////    }
////////////////
////////////////    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
////////////////        let size = sliderCollectionView.frame.size
////////////////        return CGSize(width: size.width, height: size.height)
////////////////    }
////////////////
////////////////    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
////////////////        return 0.0
////////////////    }
////////////////
////////////////    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
////////////////        return 0.0
////////////////    }
////////////////
////////////////}

extension BrowseTabVC: GADInterstitialDelegate {
    
    private func loadInterstitial() {
        guard !IAPHandler.shared.isGetPurchase() else {
            //////////////// Skip loading the ad if the purchase is made
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
        switch browseheader {
        case .playlist, .newMusic, .popularMusic:
            openMusicPlayerViewController()
        case .radio:
            openRadioWithRecentViewController()
        case .recentlyPlay:
            if let recenltPlayedindex = recenltPlayedindex {
                openMyMusicPlayerViewController(index: recenltPlayedindex)
            }
//        case .myPlaylist:
//            if let myPlayListindex = myPlayListindex {
//                openMyPlayList(index: myPlayListindex)
//            }
        case .rjtv:
            openRadioWithRecentViewController()

        }
    }
    
    func openrjTv() {
        print("aaaa===")
        
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

/*extension BrowseTabVC: GADAdLoaderDelegate, GADUnifiedNativeAdLoaderDelegate {
    
    func loadNativeAd() {
        guard !IAPHandler.shared.isGetPurchase() else {
            //////////////// Skip loading the ad if the purchase is made
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
        handleBrowseheaderArrayValue()
        tblBrowse.reloadData()
    }
    
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: GADRequestError) {
        print("\(adLoader) failed with error: \(error.localizedDescription)")
    }
    
} */

extension BrowseTabVC: GADBannerViewDelegate {

    //////////////// MARK: - GADBannerViewDelegate

    //////////////// Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("Ad received successfully")
    }

    //////////////// Tells the delegate an ad request failed.
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        print("Ad failed to load: \(error.localizedDescription)")
    }

    //////////////// Tells the delegate that a full-screen view will be presented in response to the user clicking on an ad.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("Ad will present a full-screen view")
    }

    //////////////// Tells the delegate that the full-screen view will be dismissed.
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("Full-screen view will be dismissed")
    }

    //////////////// Tells the delegate that the full-screen view has been dismissed.
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("Full-screen view has been dismissed")
    }

    //////////////// Tells the delegate that a user click will open another app (such as the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        print("User click will leave the application")
        
    }
}
