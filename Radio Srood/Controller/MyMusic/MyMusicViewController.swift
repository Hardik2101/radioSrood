
import UIKit
import GoogleMobileAds
import SWRevealViewController

class MyMusicViewController: UIViewController {
    
    @IBOutlet private weak var myMusicCollectionView: UICollectionView!
    @IBOutlet private weak var menuBtn: UIBarButtonItem!
    
    var radioData: NSDictionary?
    var bannerView: GADBannerView!
    var dataHelper: DataHelper!
    var trackData: [PodcastObject] = []
    var isForLikes = false
    var isFav = false
    var isMyPlaylist = false
    var isDownload = false
    var selectedIndex: Int?
    
    let activityIndicator = UIActivityIndicatorView(style: .white)
    
    //Controller Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
       
        
        
        prepareView()
        if !isForLikes{
            activityIndicator.center = view.center
            view.addSubview(activityIndicator)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.titleTextAttributes =  [NSAttributedString.Key.foregroundColor: UIColor.white]
        self.navigationController?.navigationBar.topItem?.title = "My Music"
        self.navigationController?.navigationBar.backItem?.title = "My Music"
        navigationController?.navigationBar.isTranslucent = true
    }
    
    // MARK: - Private Methods
    private func prepareView() {
        navigationController?.navigationBar.titleTextAttributes =  [NSAttributedString.Key.foregroundColor: UIColor.white]
        menuBtn.target = revealViewController()
        menuBtn.action = #selector(SWRevealViewController.revealToggle(_:))
        if let view = view , let reveal = revealViewController(){
            view.addGestureRecognizer(reveal.panGestureRecognizer())
        }
        if !isForLikes{
            dataHelper = DataHelper()
            activityIndicator.startAnimating()
            dataHelper.getRecentListData(completion: { [weak self] resp in
                guard let self = self else { return }
                self.radioData = resp
                self.dataHelper.fetchMp3 { [weak self] (data) in
                    guard let self = self else { return }
                    self.trackData = data
                    self.mapArtCoverURL()
                }
            })
        }
        createBanner()
    }
    
    private func mapArtCoverURL() {
        for songData in trackData {
            if let url = getArtCover(track: songData.trackName, artist: songData.artistName) {
                    songData.imageURL = url
            }
        }
        self.myMusicCollectionView.reloadData()
        activityIndicator.stopAnimating()
    }
    
    private func getArtCover(track: String, artist: String) -> URL? {
        var artCoverURL: URL?
        if let currentSong = radioData?.value(forKey: "currentTrack") as? NSDictionary,
           let recentHistory = currentSong.value(forKey: "recentHistory") as? NSArray {
            recentHistory.forEach({
                guard let currentTrack = ($0 as AnyObject).value(forKey: "recentTrack") as? String,
                      let currentArtist = ($0 as AnyObject).value(forKey: "recentArtist") as? String,
                      let currentArtCover = ($0 as AnyObject).value(forKey: "recentArtCover") as? String,
                      let url = URL(string: currentArtCover)
                else {
                    return
                }
                if currentTrack.lowercased().trim().contains(track.lowercased().trim()) &&
                    currentArtist.lowercased().trim().contains(artist.lowercased().trim()) {
                    artCoverURL = url
                    return
                }
            })
        }
        return artCoverURL
    }
    
    private func createBanner() {
        guard !IAPHandler.shared.isGetPurchase() else {
            // Skip loading the ad if the purchase is made
            return
        }

        bannerView = GADBannerView(frame:CGRect(x: 0, y: 0, width:  Common.screenSize.width, height: 50))
        bannerView.adUnitID = GOOGLE_ADMOB_KEY
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        if SHOW_BANNER_ADMOB {
            bannerView.frame.origin.y = self.view.frame.size.height - 50 + myMusicCollectionView.contentOffset.y
            self.view.addSubview(bannerView)
            myMusicCollectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        }
    }
    
    @objc func longPressed(sender: UILongPressGestureRecognizer) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MusicOptionViewController") as! MusicOptionViewController
        vc.trackData = trackData[sender.view?.tag ?? 0]
        selectedIndex = sender.view?.tag ?? 0
        vc.isFav = self.isFav
        vc.isMyPlaylist = self.isMyPlaylist
        vc.isDownload = self.isDownload
        vc.myMusicViewController = self
        self.present(vc, animated: true)
    }
    
    func reloadDataOfMusic() {
        if isMyPlaylist {
        } else if isDownload {
            if let selectedIndex = selectedIndex {
                do {
                    if let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        try FileManager.default.removeItem(atPath: documentsUrl.path + "/" + self.trackData[selectedIndex].file.lastPathComponent)
                        self.trackData.remove(at: selectedIndex)
                        myMusicCollectionView.reloadData()
                    }
                } catch {
                    print("Not removed")
                }
            }
        } else {
            if isFav {
                let savedTracks = UserDefaultsManager.shared.localTracksData
                let bookMarkedTracks = savedTracks.filter({$0.isFav})
                let bookmarkTracks = bookMarkedTracks.map { $0.convertToPodcastModel() }
                trackData = bookmarkTracks.reversed()
                myMusicCollectionView.reloadData()
            } else {
                let savedTracks = UserDefaultsManager.shared.localTracksData
                let bookMarkedTracks = savedTracks.filter({$0.isBookMarked})
                let bookmarkTracks = bookMarkedTracks.map { $0.convertToPodcastModel() }
                trackData = bookmarkTracks.reversed()
                myMusicCollectionView.reloadData()
            }
        }
    }
    
}

//MARK: - Collectionview delegate methods
extension MyMusicViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return trackData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.registerAndGet(MusicCell.self, indexPath: indexPath) {
            cell.podcastObject = trackData[indexPath.row]
            cell.tag = indexPath.row
            let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
            cell.addGestureRecognizer(longPressRecognizer)
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MyMusicPlayerViewController") as! MyMusicPlayerViewController
        vc.selectedIndex = indexPath.row
        vc.tempTrack = trackData
        vc.track = trackData
        self.present(vc, animated: true)//navigationController?.pushViewController(vc, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSpace = (collectionViewLayout as? UICollectionViewFlowLayout)?.minimumInteritemSpacing ?? 0
        let leftInset = (collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset.left ?? 0
        let rightInset = (collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset.right ?? 0
        let space = cellSpace * 2
        let totalInset = leftInset + rightInset + space
        let width = (Common.screenSize.width - totalInset) / 3
        let height = width.rounded(toPlaces: 2) + 37
        return CGSize(width: width.rounded(toPlaces: 2), height: height)
    }

}

extension CGFloat {
    func rounded(toPlaces places: Int) -> CGFloat {
        let divisor = pow(10.0, CGFloat(places))
        return floor(self * divisor) / divisor
    }
}


