/// Add Tabbar View 4


//
//  AllMusicViewController.swift
//  Radio Srood
//
//  Created by Tech on 25/05/2023.
//  Copyright © 2023 Appteve. All rights reserved.
//revealViewController().panGestureRecognizer()

import UIKit

class AllMusicViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var vwAds: UIView!
    
    @IBOutlet weak var lbl1: UILabel!
    @IBOutlet weak var lbl2: UILabel!
    
    @IBOutlet weak var heightOfAdsView: NSLayoutConstraint!
    
    var recenltPlayed = [SongModel]()
    var playList = [PlayListModel]()
    var playListsongsList = [SongModel]()
    
    private var isPurchaseSuccess: Bool = false

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.playList = UserDefaultsManager.shared.playListsData
//        for each in self.playList{
//            for eachtrack in each.songs{
//                playListsongsList.append(eachtrack)
//            }
//        }
        self.collectionView.reloadData()
        self.fetchRecentlyPlayed()
        
        vwAds.isHidden = true
        heightOfAdsView.constant = 0
        navigationController?.setNavigationBarHidden(true, animated: false)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        setUpUI()
    }
        
    private func setUpUI() {
        vwAds.isHidden = true
        heightOfAdsView.constant = 0
        
        let isPurchase = IAPHandler.shared.isGetPurchase()

        if isPurchase || isPurchaseSuccess {
            vwAds.isHidden = true
            heightOfAdsView.constant = 0
//            isPurchaseSuccess = false
        } else {
            vwAds.isHidden = false
            heightOfAdsView.constant = 60
            lbl1.text = "Music without ads!"
            lbl2.text = "Get Premium for Srood Plus"
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(vwAdsTapped))
        vwAds.addGestureRecognizer(tapGesture)
        vwAds.isUserInteractionEnabled = true
    }
    
    @objc private func handleIAPPurchase() {
        
        isPurchaseSuccess = true
        vwAds.isHidden = true
        heightOfAdsView.constant = 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: {
            self.isPurchaseSuccess = false
        })
    }

    @objc private func vwAdsTapped() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "IAPVC") as! IAPVC
        vc.isshowbackButton = true
        let navVC = UINavigationController(rootViewController: vc)
        navVC.navigationBar.isHidden = true
        navVC.modalPresentationStyle = .popover
        
        self.present(navVC, animated: true)
        self.revealViewController()?.revealToggle(self)
        NotificationCenter.default.addObserver(self, selector: #selector(handleIAPPurchase), name: .PurchaseSuccess, object: nil)

    }

    
    func fetchRecentlyPlayed(){
        let savedTracks = UserDefaultsManager.shared.localTracksData
        recenltPlayed = savedTracks.filter({$0.isRecentlyPlayed})
        recenltPlayed = recenltPlayed.reversed()
        self.tableView.reloadData()
    }
    
    @IBAction func actionBack(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func actionMyMusic(_ sender: Any) {
        let savedTracks = UserDefaultsManager.shared.localTracksData
        let bookMarkedTracks = savedTracks.filter({$0.isBookMarked})
        let bookmarkTracks = bookMarkedTracks.map { $0.convertToPodcastModel() }
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MyMusicViewController") as! MyMusicViewController
        vc.isForLikes = true
        vc.isFav = false
        vc.trackData = bookmarkTracks.reversed()
        self.navigationController?.present(vc, animated: true)
    }
   
    @IBAction func actionMyDownlaods(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MyMusicViewController") as! MyMusicViewController
        vc.isDownload = true
        self.navigationController?.present(vc, animated: true)
    }
    
    @IBAction func actionMyLikes(_ sender: Any) {
        let savedTracks = UserDefaultsManager.shared.localTracksData
        let likedTracks = savedTracks.filter({$0.isFav})
        let likesTracks = likedTracks.map { $0.convertToPodcastModel() }
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MyMusicViewController") as! MyMusicViewController
        vc.isForLikes = true
        vc.isFav = true
        vc.trackData = likesTracks.reversed()
        self.navigationController?.present(vc, animated: true)
    }
    
    @objc func longPressed(sender: UILongPressGestureRecognizer) {
        let alert = UIAlertController(title: "Delete My Playlist", message: "Are you sure you want to delete \(playList[sender.view?.tag ?? 0].name) playlist", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in  })
        alert.addAction(UIAlertAction(title: "Delete", style: .default) { [weak self] action in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.playList.remove(at: sender.view?.tag ?? 0)
                UserDefaultsManager.shared.playListsData = self.playList
                self.collectionView.reloadData()
            }
        })
        self.present(alert, animated: true)
    }
}

extension AllMusicViewController : UITableViewDelegate , UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recenltPlayed.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecentlyPlayedTableViewCell", for: indexPath) as! RecentlyPlayedTableViewCell
        cell.configureView(track: self.recenltPlayed[indexPath.row])
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
  
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let recentTracks = self.recenltPlayed.map { $0.convertToPodcastModel() }
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MyMusicPlayerViewController") as! MyMusicPlayerViewController
        vc.selectedIndex = indexPath.row
        vc.track = recentTracks
        vc.tempTrack = recentTracks
        //vc.modalPresentationStyle = .overCurrentContext
        self.present(vc, animated: true)
    }
    
}

extension AllMusicViewController : UICollectionViewDelegate , UICollectionViewDataSource , UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.playList.count//self.playListsongsList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyAllPlaylistCollectionViewCell", for: indexPath) as! MyAllPlaylistCollectionViewCell
        cell.configureTrackView(track: self.playList[indexPath.row])//configureView(track: self.playListsongsList[indexPath.row])
        cell.tag = indexPath.row
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        cell.addGestureRecognizer(longPressRecognizer)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 128, height: 168)
    }
  
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PlayListViewController") as! PlayListViewController
//        vc.isFromMyMusic = true
//        vc.modalPresentationStyle = .fullScreen
//        self.present(vc, animated: true)
        let playListSongs = self.playList[indexPath.row].songs.map { $0.convertToPodcastModel() }
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MyMusicViewController") as! MyMusicViewController
        vc.isForLikes = true
        vc.trackData = playListSongs
        self.present(vc, animated: true)
    }
}
