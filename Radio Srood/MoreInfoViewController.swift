
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
            if let artCoverURLString = currentTrackInfo.value(forKey: "currentArtCoverInfo") as? String,
               let url = URL(string: artCoverURLString) {
                artCoverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            }

            if let trackTitle = currentTrackInfo.value(forKey: "currentTrackInfo") as? String {
                lblSongTitle.text = trackTitle
            }

            if let artist = currentTrackInfo.value(forKey: "currentArtistInfo") as? String {
                lblArtist.text = artist
            }

            updateTextAndVisibility(label: lblDateAdded,
                                    view: dateAddedView,
                                    constraint: dateAddedHeightConstraint,
                                    prefix: "Date Added: ",
                                    value: currentTrackInfo.value(forKey: "DateTrackAddedInfo") as? String)

            updateTextAndVisibility(label: lblLastPlayed,
                                    view: dateLastPlayedView,
                                    constraint: dateLastPlayedHeightConstraint,
                                    prefix: "Last Played: ",
                                    value: currentTrackInfo.value(forKey: "SongLastPlayedInfo") as? String)

            updateTextAndVisibility(label: lblRecentPlayed,
                                    view: artistResentPlayedView,
                                    constraint: artistResentPlayedHeightConstraint,
                                    prefix: "Artist: ",
                                    value: currentTrackInfo.value(forKey: "currentArtistInfo") as? String)
            
            updateTextAndVisibility(label: lblMusic,
                                    view: musicView,
                                    constraint: musicHeightConstraint,
                                    prefix: "Music: ",
                                    value: currentTrackInfo.value(forKey: "ArtistMusicComposerInfo") as? String)
            
            updateTextAndVisibility(label: lblLyrics,
                                    view: lyricsView,
                                    constraint: lyricsHeightConstraint,
                                    prefix: "Lyrics: ",
                                    value: currentTrackInfo.value(forKey: "ArtistLyricWriterInfo") as? String)

            updateTextAndVisibility(label: lblFacebook,
                                    view: fbView,
                                    constraint: fbHeightConstraint,
                                    prefix: "",
                                    value: currentTrackInfo.value(forKey: "SocialMediaLinkInfo1") as? String)

            updateTextAndVisibility(label: lblInstagram,
                                    view: instagramView,
                                    constraint: instagramHeightConstraint,
                                    prefix: "",
                                    value: currentTrackInfo.value(forKey: "SocialMediaLinkInfo2") as? String)

            updateTextAndVisibility(label: lblUpcomingEvents,
                                    view: upcomingView,
                                    constraint: upcomingHeightConstraint,
                                    prefix: "Upcoming Events: ",
                                    value: currentTrackInfo.value(forKey: "UpComingConcertInfo") as? String)

            if let playCount = currentTrackInfo.value(forKey: "currentPlayCountsInfo") as? Int {
                lblPlaysCount.text = "Plays: \(playCount)"
                playsView.isHidden = false
                playsHeightConstraint.constant = 32
            } else {
                playsView.isHidden = true
                playsHeightConstraint.constant = 0
            }

            let likes = currentTrackInfo.value(forKey: "currentSongLikes") as? Int ?? 0
            lblLikesCount.text = "Likes: \(likes)"
            
            ytView.isHidden = true
            ytHeightConstraint.constant = 0
        }

        if let track = track {
            if let url = URL(string: track.artcover ?? "") {
                artCoverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            }

            lblSongTitle.text = track.track
            lblArtist.text = track.artist

            updateTextAndVisibility(label: lblDateAdded,
                                    view: dateAddedView,
                                    constraint: dateAddedHeightConstraint,
                                    prefix: "Date Added: ",
                                    value: track.dateAdded)

            dateLastPlayedView.isHidden = true
            dateLastPlayedHeightConstraint.constant = 0

            artistResentPlayedView.isHidden = true
            artistResentPlayedHeightConstraint.constant = 0

            updateTextAndVisibility(label: lblMusic,
                                    view: musicView,
                                    constraint: musicHeightConstraint,
                                    prefix: "Music: ",
                                    value: track.music)

            updateTextAndVisibility(label: lblLyrics,
                                    view: lyricsView,
                                    constraint: lyricsHeightConstraint,
                                    prefix: "Lyrics: ",
                                    value: track.lyricWriter)

            updateTextAndVisibility(label: lblYoutube,
                                    view: ytView,
                                    constraint: ytHeightConstraint,
                                    prefix: "",
                                    value: track.ytLink)

            updateTextAndVisibility(label: lblFacebook,
                                    view: fbView,
                                    constraint: fbHeightConstraint,
                                    prefix: "",
                                    value: track.fbLink)

            updateTextAndVisibility(label: lblInstagram,
                                    view: instagramView,
                                    constraint: instagramHeightConstraint,
                                    prefix: "",
                                    value: track.igLink)

            updateTextAndVisibility(label: lblUpcomingEvents,
                                    view: upcomingView,
                                    constraint: upcomingHeightConstraint,
                                    prefix: "Composer: ",
                                    value: track.composer)

            updateTextAndVisibility(label: lblPlaysCount,
                                    view: playsView,
                                    constraint: playsHeightConstraint,
                                    prefix: "Plays: ",
                                    value: track.playcounts)

            updateTextAndVisibility(label: lblLikesCount,
                                    view: likesView,
                                    constraint: likesHeightConstraint,
                                    prefix: "Likes: ",
                                    value: track.likes)
        }
    }
    
    private func updateTextAndVisibility(label: UILabel, view: UIView, constraint: NSLayoutConstraint, prefix: String, value: String?) {
        let text = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !text.isEmpty {
            label.text = prefix + text
            view.isHidden = false
            constraint.constant = 32
        } else {
            view.isHidden = true
            constraint.constant = 0
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
