/// Add Tabbar View 4

//
//  AllMusicViewController.swift
//  Radio Srood
//
//  Created by Tech on 25/05/2023.
//  Copyright © 2023 Appteve. All rights reserved.
//

import UIKit

class AllMusicViewController: UI_VC {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var vwAds: UIView!
    @IBOutlet weak var lbl1: UILabel!
    @IBOutlet weak var lbl2: UILabel!
    @IBOutlet weak var heightOfAdsView: NSLayoutConstraint!
    @IBOutlet var vwPlayList: UIView!
    @IBOutlet var vwCollectionPlayList: UIView!
    @IBOutlet weak var heightOfPlaylistView: NSLayoutConstraint!
    @IBOutlet var heighrOfPlayListLbl: NSLayoutConstraint!

    var recenltPlayed = [SongModel]()
    var playList = [PlayListModel]()
    private var isPurchaseSuccess: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        checkInternetForTabbar()
        vwAds.isHidden = true
        heightOfAdsView.constant = 0
        navigationController?.setNavigationBarHidden(true, animated: false)
        updateTableHeaderHeight()

        // Long press for recently played table rows
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleTableLongPress(_:)))
        longPress.minimumPressDuration = 0.4
        tableView.addGestureRecognizer(longPress)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkInternetForTabbar()
        self.fetchRecentlyPlayed()
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setUpUI()
        updateMyPlaylist()
    }

    // MARK: - Offline handling / refresh
    
    override func refreshAfterReconnect() {
        // Refresh local + any network-backed data for My Music when connection is back.
        fetchRecentlyPlayed()
        updateMyPlaylist()
        tableView.reloadData()
        collectionView.reloadData()
    }

    private func setUpUI() {
        vwAds.isHidden = true
        heightOfAdsView.constant = 0

        let isPurchase = IAPHandler.shared.isGetPurchase()
        if isPurchase || isPurchaseSuccess {
            vwAds.isHidden = true
            heightOfAdsView.constant = 0
        } else {
            vwAds.isHidden = false
            heightOfAdsView.constant = 60
            lbl1.text = "Music without ads!"
            lbl2.text = "Get Premium for Srood Plus"
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(vwAdsTapped))
        vwAds.addGestureRecognizer(tapGesture)
        vwAds.isUserInteractionEnabled = true
        updateTableHeaderHeight()
    }

    func updateTableHeaderHeight() {
        guard let headerView = tableView.tableHeaderView else { return }
        headerView.frame.size.height = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        tableView.tableHeaderView = headerView
        UIView.animate(withDuration: 0.3) {
            self.tableView.layoutIfNeeded()
        }
    }

    @objc private func handleIAPPurchase() {
        isPurchaseSuccess = true
        vwAds.isHidden = true
        heightOfAdsView.constant = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.isPurchaseSuccess = false
        }
        updateTableHeaderHeight()
    }

    @objc private func vwAdsTapped() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "IAPVC") as! IAPVC
        vc.isshowbackButton = true
        let navVC = UINavigationController(rootViewController: vc)
        navVC.navigationBar.isHidden = true
        navVC.modalPresentationStyle = .fullScreen
        self.present(navVC, animated: true)
        self.revealViewController()?.revealToggle(self)
        NotificationCenter.default.addObserver(self, selector: #selector(handleIAPPurchase), name: .PurchaseSuccess, object: nil)
    }

    func updateMyPlaylist() {
        self.playList = UserDefaultsManager.shared.playListsData
        self.collectionView.reloadData()

        let hasPlaylist = !playList.isEmpty
        vwCollectionPlayList.isHidden = !hasPlaylist
        heightOfPlaylistView.constant = hasPlaylist ? 180 : 0
        vwPlayList.isHidden = !hasPlaylist
        heighrOfPlayListLbl.constant = hasPlaylist ? 50 : 0
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
        updateTableHeaderHeight()
    }

    func fetchRecentlyPlayed() {
        let savedTracks = UserDefaultsManager.shared.localTracksData
        recenltPlayed = savedTracks.filter({ $0.isRecentlyPlayed })
        recenltPlayed = recenltPlayed.reversed()
        self.tableView.reloadData()
    }

    @IBAction func actionBack(_ sender: Any) {
        self.dismiss(animated: true)
    }

    @IBAction func actionMyMusic(_ sender: Any) {
        let savedTracks = UserDefaultsManager.shared.localTracksData
        let bookMarkedTracks = savedTracks.filter({ $0.isBookMarked })
        let bookmarkTracks = bookMarkedTracks.map { $0.convertToPodcastModel() }
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MyMusicViewController") as! MyMusicViewController
        vc.isForLikes = true
        vc.isFav = false
        vc.trackData = bookmarkTracks.reversed()
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func actionMyDownlaods(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MyMusicViewController") as! MyMusicViewController
        vc.isDownload = true
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func actionMyLikes(_ sender: Any) {
        let savedTracks = UserDefaultsManager.shared.localTracksData
        let likedTracks = savedTracks.filter({ $0.isFav })
        let likesTracks = likedTracks.map { $0.convertToPodcastModel() }
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MyMusicViewController") as! MyMusicViewController
        vc.isForLikes = true
        vc.isFav = true
        vc.trackData = likesTracks.reversed()
        self.navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Recently Played Table Long Press → OptionsViewController
    @objc private func handleTableLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let point = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point),
              indexPath.row < recenltPlayed.count else { return }

        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()

        if let cell = tableView.cellForRow(at: indexPath) {
            cell.isUserInteractionEnabled = false
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                cell.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
            }) { _ in
                UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                    cell.transform = .identity
                    cell.isUserInteractionEnabled = true
                })
            }
        }

        let track = recenltPlayed[indexPath.row].convertToPodcastModel().convertToTrackModel()
        presentOptionsViewController(for: track)
    }

    // MARK: - Playlist Collection Long Press → Delete
    @objc func longPressed(sender: UILongPressGestureRecognizer) {
        // Only fire once on began to avoid multiple alerts
        guard sender.state == .began else { return }
        let index = sender.view?.tag ?? 0
        guard index < playList.count else { return }

        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()

        let alert = UIAlertController(
            title: "Delete My Playlist",
            message: "Are you sure you want to delete \"\(playList[index].name)\" playlist?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.playList.remove(at: index)
                UserDefaultsManager.shared.playListsData = self.playList
                self.collectionView.reloadData()
                self.updateMyPlaylist()
            }
        })
        self.present(alert, animated: true)
    }

    // MARK: - Present OptionsViewController
    private func presentOptionsViewController(for track: Track) {
        guard let optionsVC = storyboard?.instantiateViewController(withIdentifier: "OptionsViewController") as? OptionsViewController else {
            print("Error: Could not instantiate OptionsViewController")
            return
        }
        optionsVC.track = track
        optionsVC.delegate = self
        optionsVC.modalPresentationStyle = .overFullScreen
        present(optionsVC, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension AllMusicViewController: UITableViewDelegate, UITableViewDataSource {

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
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension AllMusicViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.playList.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyAllPlaylistCollectionViewCell", for: indexPath) as! MyAllPlaylistCollectionViewCell
        cell.configureTrackView(track: self.playList[indexPath.row])
        cell.tag = indexPath.row

        // Remove old gesture recognizers to avoid stacking on reuse
        cell.gestureRecognizers?.filter { $0 is UILongPressGestureRecognizer }.forEach {
            cell.removeGestureRecognizer($0)
        }
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        longPressRecognizer.minimumPressDuration = 0.4
        cell.addGestureRecognizer(longPressRecognizer)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 128, height: 168)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let playListSongs = self.playList[indexPath.row].songs.map { $0.convertToPodcastModel() }
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MyMusicViewController") as! MyMusicViewController
        vc.isForLikes = true
        vc.trackData = playListSongs
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - OptionsViewControllerDelegate
extension AllMusicViewController: OptionsViewControllerDelegate {
    func didUpdateTrackMetadata() {
        DispatchQueue.main.async {
            self.fetchRecentlyPlayed()
        }
    }
}
