
import UIKit
import SpotlightLyrics

class LyricsViewController: UIViewController {

    @IBOutlet private weak var artCoverImage: UIImageView!
    @IBOutlet private weak var lblSongTitle: UILabel!
    @IBOutlet private weak var btnDone: UIButton!
    @IBOutlet private weak var lblSongLyric: UILabel!
    @IBOutlet private weak var lblNoSongLyric: UILabel!
    @IBOutlet weak var lyricsView: LyricsView!

    var currentLyricData: NSDictionary?
    var recentLyricData: NSDictionary?
    var track: Track?
    var isSyncedLyrics = false

    var ArtistInfo: String = ""
    var TrackInfo: String = ""

    private var resolvedCurrentTrackInfo: NSDictionary? {
        if let payload = currentLyricData,
           let trackInfo = payload.value(forKey: "currentTrackInfo") as? NSDictionary {
            return trackInfo
        }
        if let currentTrack = currentLyricData?.value(forKey: "currentTrack") as? NSDictionary {
            return RadioCurrentSongMapper.legacyCurrentTrackInfo(from: currentTrack)
        }
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        configureLyricsAppearance()
        lyricsView.lyricTextColor = UIColor.white.withAlphaComponent(0.55)
        lyricsView.lyricHighlightedTextColor = UIColor.white

        if let currentTrackInfo = resolvedCurrentTrackInfo {
                if let currentArtCoverInfo = currentTrackInfo.value(forKey: "currentArtCoverInfo") as? String, let url = URL(string: currentArtCoverInfo ) {
                    artCoverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                }
                if let currentTrackInfo = currentTrackInfo.value(forKey: "currentTrackInfo") as? String {
                    lblSongTitle.text = currentTrackInfo
                }
                
                if let currentArtistInfo = currentTrackInfo.value(forKey: "currentArtistInfo") as? String {
                    self.ArtistInfo  = currentArtistInfo
                }
                
                if let currentTrackInfo = currentTrackInfo.value(forKey: "currentTrackInfo") as? String {
                    self.TrackInfo  = currentTrackInfo
                }


                lblSongLyric.text = ""
                lblNoSongLyric.text = ""

                // Fetch lyrics from API
                DataHelper.getLyricsData(
                    artist: self.ArtistInfo,
                    track: self.TrackInfo
                ) { lyricItem in

                    DispatchQueue.main.async {

                        if let synced = lyricItem?.syncedLyrics, !synced.isEmpty {
                            // ✅ Prefer synced lyrics
                            self.lyricsView.lyrics = synced
                            self.lyricsView.isSyncedLyrics = true

                        } else if let plain = lyricItem?.plainLyrics, !plain.isEmpty {
                            // 🟡 Fallback to plain lyrics
                            self.lyricsView.lyrics = plain
                            self.lyricsView.isSyncedLyrics  = false

                        } else {
                            // ❌ Nothing available
                            self.lyricsView.lyrics =
                            """
                            Lyric Not Available

                            Please send lyrics to lyric@radiosrood.com
                            """
                        }
                        self.configureLyricsAppearance()
                    }
                }

//                
//                if let currentLyricInfo = currentTrackInfo.value(forKey: "currentLyricInfo") as? String {
//                    if currentLyricInfo == "" {
//                        lblNoSongLyric.text = "Lyric Not Available \n\n Please send lyric to lyric@radiosrood.com"
//                    } else {
//                        lblSongLyric.text = currentLyricInfo
//                    }
//                }
        }
        if let recentLyricData = recentLyricData {
            if let currentArtCoverInfo = recentLyricData.value(forKey: "recentArtCover") as? String, let url = URL(string: currentArtCoverInfo) {
                artCoverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            }
            if let currentTrackInfo = recentLyricData.value(forKey: "recentTrack") as? String {
                lblSongTitle.text = currentTrackInfo
            }
            
            
            if let currentArtistInfo = recentLyricData.value(forKey: "recentArtist") as? String {
                self.ArtistInfo  = currentArtistInfo
            }
            
            if let currentTrackInfo = recentLyricData.value(forKey: "recentTrack") as? String {
                self.TrackInfo  = currentTrackInfo
            }


            lblSongLyric.text = ""
            lblNoSongLyric.text = ""

            // Fetch lyrics from API
            DataHelper.getLyricsData(
                artist: self.ArtistInfo,
                track: self.TrackInfo
            ) { lyricItem in

                DispatchQueue.main.async {

                    if let synced = lyricItem?.syncedLyrics, !synced.isEmpty {
                        // ✅ Synced lyrics
                        self.lyricsView.lyrics = synced
                        self.lyricsView.isSyncedLyrics = true


                    } else if let plain = lyricItem?.plainLyrics, !plain.isEmpty {
                        // 🟡 Plain lyrics fallback
                        self.lyricsView.lyrics = plain
                        self.lyricsView.isSyncedLyrics = false


                    } else {
                        // ❌ No lyrics at all
                        self.lyricsView.lyrics =
                        """
                        Lyric Not Available

                        Please send lyrics to lyric@radiosrood.com
                        """
                    }
                    self.configureLyricsAppearance()
                }
            }

//            if let currentLyricInfo = recentLyricData.value(forKey: "recentLyric") as? String {
//                if currentLyricInfo == "" {
//                    lblNoSongLyric.text = "Lyric Not Available \n\n Please send lyric to lyric@radiosrood.com"
//                } else {
//                    lblSongLyric.text = currentLyricInfo
//                }
//            }
        }
        if let track = track {
            if let url = track.thumbnailArtCoverURL {
                artCoverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            }
            lblSongTitle.text = track.track
            if track.lyric == "" {
                lblNoSongLyric.text = "Lyric Not Available \n\n Please send lyric to lyric@radiosrood.com"
            } else {
                lblSongLyric.text = track.lyric
            }
        }
        
        configureLyricsAppearance()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configureLyricsAppearance()
    }

    private func configureLyricsAppearance() {
        lyricsView.backgroundColor = .clear
        lyricsView.isOpaque = false
        lyricsView.backgroundView = nil
        lyricsView.separatorColor = .clear
        if #available(iOS 15.0, *) {
            lyricsView.sectionHeaderTopPadding = 0
        }
        lyricsView.visibleCells.forEach { cell in
            cell.backgroundColor = .clear
            cell.contentView.backgroundColor = .clear
            cell.isOpaque = false
        }
    }

    @IBAction func doneClieckedEvent(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

}
