
import UIKit

class MoreInfoViewController: UIViewController {

    @IBOutlet private weak var artCoverImage: UIImageView!
    @IBOutlet private weak var lblSongTitle: UILabel!
    @IBOutlet private weak var lblArtist: UILabel!
    @IBOutlet private weak var lblDateAdded: UILabel!
    @IBOutlet private weak var lblLastPlayed: UILabel!
    @IBOutlet private weak var lblRecentPlayed: UILabel!
    @IBOutlet private weak var lblMusic: UILabel!
    @IBOutlet private weak var lblLyrics: UILabel!
    @IBOutlet private weak var lblYoutube: UILabel!
    @IBOutlet private weak var lblFacebook: UILabel!
    @IBOutlet private weak var lblInstagram: UILabel!
    @IBOutlet private weak var lblUpcomingEvents: UILabel!
    @IBOutlet private weak var lblPlaysCount: UILabel!
    @IBOutlet private weak var lblLikesCount: UILabel!
    @IBOutlet private weak var backView: UIView!
    @IBOutlet private weak var musicView: UIView!
    @IBOutlet private weak var musicHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var upcomingView: UIView!
    @IBOutlet private weak var upcomingHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var lyricsView: UIView!
    @IBOutlet private weak var lyricsHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var artistResentPlayedView: UIView!
    @IBOutlet private weak var artistResentPlayedHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var playsView: UIView!
    @IBOutlet private weak var likesView: UIView!
    @IBOutlet private weak var playsHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var likesHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var dateAddedView: UIView!
    @IBOutlet private weak var dateAddedHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var dateLastPlayedView: UIView!
    @IBOutlet private weak var dateLastPlayedHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var ytView: UIView!
    @IBOutlet private weak var ytHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var fbView: UIView!
    @IBOutlet private weak var fbHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var instagramView: UIView!
    @IBOutlet private weak var instagramHeightConstraint: NSLayoutConstraint!

    var currentLyricData: NSDictionary?
    var track: Track?
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareView()
        if let currentTrackInfo = currentLyricData?.value(forKey: "currentTrackInfo") as? NSDictionary {
            if let currentArtCoverInfo = currentTrackInfo.value(forKey: "currentArtCoverInfo") as? String, let url = URL(string: currentArtCoverInfo) {
                artCoverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            }
            if let currentTrackInfo = currentTrackInfo.value(forKey: "currentTrackInfo") as? String {
                lblSongTitle.text = currentTrackInfo
            }
            if let currentArtistInfo = currentTrackInfo.value(forKey: "currentArtistInfo") as? String {
                lblArtist.text = "\(currentArtistInfo)"
            }
            if let dateTrackAddedInfo = currentTrackInfo.value(forKey: "DateTrackAddedInfo") as? String, dateTrackAddedInfo != "" {
                lblDateAdded.text = "Date Added: \(dateTrackAddedInfo)"
            } else {
                dateAddedView.isHidden = true
                dateAddedHeightConstraint.constant = 0
            }
            if let songLastPlayedInfo = currentTrackInfo.value(forKey: "SongLastPlayedInfo") as? String, songLastPlayedInfo != "" {
                lblLastPlayed.text = "Last Played: \(songLastPlayedInfo)"
            } else {
                dateLastPlayedView.isHidden = true
                dateLastPlayedHeightConstraint.constant = 0
            }
            if let artistRecentPlayedInfo = currentTrackInfo.value(forKey: "currentArtistInfo") as? String, artistRecentPlayedInfo != "" {
                lblRecentPlayed.text = "Artist: \(artistRecentPlayedInfo)"
            } else {
                artistResentPlayedView.isHidden = true
                artistResentPlayedHeightConstraint.constant = 0
            }
            lblMusic.text = "Music: \((currentTrackInfo.value(forKey: "ArtistMusicComposerInfo") as? String) ?? "")"
            lblLyrics.text = "Lyrics: \((currentTrackInfo.value(forKey: "ArtistLyricWriterInfo") as? String) ?? "")"
          
            if let socialMediaLinkInfo1 = currentTrackInfo.value(forKey: "SocialMediaLinkInfo1") as? String, socialMediaLinkInfo1 != "" {
                lblFacebook.text = "\(socialMediaLinkInfo1)"
            } else {
                fbView.isHidden = true
                fbHeightConstraint.constant = 0
            }
            if let socialMediaLinkInfo2 = currentTrackInfo.value(forKey: "SocialMediaLinkInfo2") as? String, socialMediaLinkInfo2 != "" {
                lblInstagram.text = "\(socialMediaLinkInfo2)"
            } else {
                instagramView.isHidden = true
                instagramHeightConstraint.constant = 0
            }
            if let upComingConcertInfo = currentTrackInfo.value(forKey: "UpComingConcertInfo") as? String, upComingConcertInfo != "" {
                lblUpcomingEvents.text = "Upcoming Events: \(upComingConcertInfo)"
            } else {
                upcomingView.isHidden = true
                upcomingHeightConstraint.constant = 0
            }
            if let currentPlayCountsInfo = currentTrackInfo.value(forKey: "currentPlayCountsInfo") as? Int {
                lblPlaysCount.text = "Plays: \(currentPlayCountsInfo)"
            } else {
                playsView.isHidden = true
                playsHeightConstraint.constant = 0
            }
            let currentSongLikes = currentTrackInfo.value(forKey: "currentSongLikes") as? Int
            lblLikesCount.text = "Likes: \(currentSongLikes ?? 0)"
            ytView.isHidden = true
            ytHeightConstraint.constant = 0
        }
        if let track = track {
            if let url = URL(string: track.artcover) {
                artCoverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            }
            lblSongTitle.text = track.track
            lblArtist.text = track.artist
            if track.dateAdded != "" {
                lblDateAdded.text = "Date Added: \(track.dateAdded)"
            } else {
                dateAddedView.isHidden = true
                dateAddedHeightConstraint.constant = 0
            }
            dateLastPlayedView.isHidden = true
            dateLastPlayedHeightConstraint.constant = 0
            artistResentPlayedView.isHidden = true
            artistResentPlayedHeightConstraint.constant = 0
            if track.music != "" {
                lblMusic.text = "Music: \(track.music)"
            } else {
                musicView.isHidden = true
                musicHeightConstraint.constant = 0
            }
            if track.lyricWriter != "" {
                lblLyrics.text = "Lyrics: \(track.lyricWriter)"
            } else {
                lyricsView.isHidden = true
                lyricsHeightConstraint.constant = 0
            }
            if let ytLink = track.ytLink {
                lblYoutube.text = ytLink
            } else {
                ytView.isHidden = true
                ytHeightConstraint.constant = 0
            }
            if let socialMediaLinkInfo1 = track.fbLink {
                lblFacebook.text = socialMediaLinkInfo1
            } else {
                fbView.isHidden = true
                fbHeightConstraint.constant = 0
            }
            if let socialMediaLinkInfo2 = track.igLink {
                lblInstagram.text = socialMediaLinkInfo2
            } else {
                instagramView.isHidden = true
                instagramHeightConstraint.constant = 0
            }
            lblUpcomingEvents.text = "Composer: \(track.composer)"
            lblPlaysCount.text = "Plays: \(track.playcounts)"
            lblLikesCount.text = "Likes: \(track.likes)"
        }
    }
    
    private func prepareView() {
        backView.clipsToBounds = true
        if #available(iOS 11.0, *) {
            backView.layer.cornerRadius = 20
            backView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        } else {
            backView.roundCorners(corners: [.topLeft, .topRight], radius: 20)
        }
        artCoverImage.clipsToBounds = true
        artCoverImage.layer.cornerRadius = 92/2
    }

    @IBAction func doneClieckedEvent(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnDismissedEvent(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnOpenYTEvent(_ sender: Any) {
        if let appURL = URL(string: lblYoutube.text ?? "") {
            if UIApplication.shared.canOpenURL(appURL) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(appURL)
                } else {
                    UIApplication.shared.openURL(appURL)
                }
            }
        }
    }
    
    @IBAction func btnOpenFBEvent(_ sender: Any) {
        if let appURL = URL(string: lblFacebook.text ?? "") {
            if UIApplication.shared.canOpenURL(appURL) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(appURL)
                } else {
                    UIApplication.shared.openURL(appURL)
                }
            }
        }
    }
    
    @IBAction func btnOpenInstagram(_ sender: Any) {
        if let appURL = URL(string: lblInstagram.text ?? "") {
            if UIApplication.shared.canOpenURL(appURL) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(appURL)
                } else {
                    UIApplication.shared.openURL(appURL)
                }
            }
        }
    }
    
}
