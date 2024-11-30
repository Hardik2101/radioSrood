
import UIKit
 
class MusicOptionViewController: UIViewController, PlayListViewControllerDelegate {
    
    @IBOutlet weak var lblPlayedSongtitle: UILabel!
    @IBOutlet weak var lblPlayedSongName: UILabel!
    @IBOutlet weak var imgPlayedSong: UIImageView!
    @IBOutlet weak var removeView: UIView!
    @IBOutlet weak var playListView: UIView!
    @IBOutlet weak var playListHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var removeHeightConstraint: NSLayoutConstraint!
    
    var trackData: PodcastObject?
    var isFav = false
    var isMyPlaylist = false
    var isDownload = false
    weak var myMusicViewController: MyMusicViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if isMyPlaylist {
            playListView.isHidden = true
            removeView.isHidden = true
            playListHeightConstraint.constant = 0
            removeHeightConstraint.constant = 0
        }
        if let trackData = trackData {
            lblPlayedSongName.text = trackData.artistName
            lblPlayedSongtitle.text = trackData.trackName
            if let url = trackData.imageURL {
                self.imgPlayedSong.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            }
        }
        // Do any additional setup after loading the view.
    }
    
    @IBAction func actionCancel(_ sender: Any) {
        self.dismiss(animated: true)
        
    }
    
    @IBAction func actionRemove(_ sender: Any) {
        if isMyPlaylist {
        } else if isDownload {
            if let myMusicViewController = myMusicViewController {
                myMusicViewController.reloadDataOfMusic()
                self.dismiss(animated: true)
            }
        } else {
            if isFav {
                var savedTracks = UserDefaultsManager.shared.localTracksData
                let bookMarkedTracks = savedTracks.filter({$0.isFav})
                if let bookMark = bookMarkedTracks.first(where: { $0.track == trackData?.trackName }) {
                    if let index = savedTracks.firstIndex(where: { $0.trackid == bookMark.trackid }) {
                        savedTracks.remove(at: index)
                    }
                }
                UserDefaultsManager.shared.localTracksData = savedTracks
            } else {
                var savedTracks = UserDefaultsManager.shared.localTracksData
                let bookMarkedTracks = savedTracks.filter({$0.isBookMarked})
                if let bookMark = bookMarkedTracks.first(where: { $0.track == trackData?.trackName }) {
                    if let index = savedTracks.firstIndex(where: { $0.trackid == bookMark.trackid }) {
                        savedTracks.remove(at: index)
                    }
                }
                UserDefaultsManager.shared.localTracksData = savedTracks
            }
            if let myMusicViewController = myMusicViewController {
                myMusicViewController.reloadDataOfMusic()
                self.dismiss(animated: true)
            }
        }
    }
    
    @IBAction func actionShare(_ sender: Any) {
        var trackName = "Radio Srood"
        var artistName = "Radio Srood"
        if let trackData = trackData {
            trackName = trackData.trackName
            artistName = trackData.artistName
        }
        let shareText = String (format: "%@ - %@ on Radio Srood app! Download the app @ https://radiosrood.com/app", artistName, trackName)
        var imageArtShare: UIImage!
        if (imgPlayedSong.image == nil) {
            imageArtShare = UIImage(named: "no_image.jpg")
        } else {
            imageArtShare = imgPlayedSong.image
        }
        let vc = UIActivityViewController(activityItems: [shareText, imageArtShare], applicationActivities: [])
        vc.modalPresentationStyle = .popover
        if let wPPC = vc.popoverPresentationController {
            wPPC.sourceView = self.view
        }
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func actionAddPlayList(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PlayListViewController") as! PlayListViewController
        let currentSong = SongModel()
        if let trackData = trackData {
            currentSong.track = trackData.trackName
            currentSong.artist = trackData.artistName
            currentSong.artcover = trackData.imageURL?.absoluteString ?? ""
            currentSong.mediaPath = trackData.imageURL?.absoluteString ?? ""
        }
        vc.songToSave = currentSong
        vc.delegate = self
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
    
    func songSavedToList() {
        
    }
}
