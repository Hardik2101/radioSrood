
import UIKit

class LyricsViewController: UIViewController {

    @IBOutlet private weak var artCoverImage: UIImageView!
    @IBOutlet private weak var lblSongTitle: UILabel!
    @IBOutlet private weak var btnDone: UIButton!
    @IBOutlet private weak var lblSongLyric: UILabel!
    @IBOutlet private weak var lblNoSongLyric: UILabel!

    var currentLyricData: NSDictionary?
    var recentLyricData: NSDictionary?
    var track: Track?
    override func viewDidLoad() {
        super.viewDidLoad()
        if let currentLyricData = currentLyricData {
            if let currentTrackInfo = currentLyricData.value(forKey: "currentTrackInfo") as? NSDictionary {
                if let currentArtCoverInfo = currentTrackInfo.value(forKey: "currentArtCoverInfo") as? String, let url = URL(string: currentArtCoverInfo) {
                    artCoverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                }
                if let currentTrackInfo = currentTrackInfo.value(forKey: "currentTrackInfo") as? String {
                    lblSongTitle.text = currentTrackInfo
                }
                if let currentLyricInfo = currentTrackInfo.value(forKey: "currentLyricInfo") as? String {
                    if currentLyricInfo == "" {
                        lblNoSongLyric.text = "Lyric Not Available \n\n Please send lyric to lyric@radiosrood.com"
                    } else {
                        lblSongLyric.text = currentLyricInfo
                    }
                }
            }
        }
        if let recentLyricData = recentLyricData {
            if let currentArtCoverInfo = recentLyricData.value(forKey: "recentArtCover") as? String, let url = URL(string: currentArtCoverInfo) {
                artCoverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            }
            if let currentTrackInfo = recentLyricData.value(forKey: "recentTrack") as? String {
                lblSongTitle.text = currentTrackInfo
            }
            if let currentLyricInfo = recentLyricData.value(forKey: "recentLyric") as? String {
                if currentLyricInfo == "" {
                    lblNoSongLyric.text = "Lyric Not Available \n\n Please send lyric to lyric@radiosrood.com"
                } else {
                    lblSongLyric.text = currentLyricInfo
                }
            }
        }
        if let track = track {
            if let url = URL(string: track.artcover ?? "") {
                artCoverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            }
            lblSongTitle.text = track.track
            if track.lyric == "" {
                lblNoSongLyric.text = "Lyric Not Available \n\n Please send lyric to lyric@radiosrood.com"
            } else {
                lblSongLyric.text = track.lyric
            }
        }
    }

    @IBAction func doneClieckedEvent(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

}
