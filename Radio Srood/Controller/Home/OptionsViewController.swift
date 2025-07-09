//
//  OptionsViewController.swift
//  Radio Srood
//
//  Created by Hardik on 08/07/25.
//  Copyright © 2025 Radio Srood Inc. All rights reserved.
//

import UIKit
import Alamofire
import AVKit
import Foundation
protocol OptionsViewControllerDelegate: AnyObject {
    func didUpdateTrackMetadata()
}

class OptionsViewController: UIViewController {
    
    // MARK: - Properties
    var track: Track? // Track passed from HomeViewController or MusicPlayerViewController
    var lyricsNew: String = "" // Synced lyrics for the track
    
    @IBOutlet var addTocoolectionImage: UIImageView!
    @IBOutlet var btnDownload: UIImageView!
    
    weak var delegate: OptionsViewControllerDelegate? // Delegate to notify parent VC
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addBlurBackground()
        updateButtonStates()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(updateButtonStates))
        btnDownload.isUserInteractionEnabled = true
        btnDownload.addGestureRecognizer(tapGesture)

    }
    func updateDownloadIcon(isDownloaded: Bool) {
        guard let btnDownload = btnDownload else {
            print("Error: Download button not connected in storyboard")
            return
        }

        if isDownloaded {
            let image = UIImage(systemName: "checkmark.circle.fill")?.withRenderingMode(.alwaysTemplate)
            btnDownload.image = image
            btnDownload.tintColor = UIColor.systemGreen

            btnDownload.layer.cornerRadius = 15
            btnDownload.layer.borderColor = UIColor.systemGreen.cgColor
            btnDownload.layer.borderWidth = 2
            btnDownload.clipsToBounds = true

            btnDownload.isUserInteractionEnabled = false // prevent further taps
        } else {
            btnDownload.image = UIImage(named: "ic_download")
            btnDownload.tintColor = UIColor.white

            btnDownload.layer.cornerRadius = 0
            btnDownload.layer.borderWidth = 0
            btnDownload.clipsToBounds = false

            btnDownload.isUserInteractionEnabled = true // allow tap
        }
    }

    func addBlurBackground() {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(blurView, at: 0)
    }
    
    @objc private func updateButtonStates() {
        guard let currentTrack = track else {
            print("Error: No track provided to update button states")
            return
        }
        
        let savedTracks = UserDefaultsManager.shared.localTracksData
        let isBookmarked = savedTracks.contains { $0.trackid == currentTrack.trackid && $0.isBookMarked }
        let isDownloaded = savedTracks.contains { $0.trackid == currentTrack.trackid && $0.isDownload }
        
        self.addTocoolectionImage.image = UIImage(named: isBookmarked ? "ic_bookmark_fill" : "ic_bookmark")
        updateDownloadIcon(isDownloaded: isDownloaded)
        
        print("Updating button states for trackID: \(currentTrack.trackid), isBookmarked: \(isBookmarked), isDownloaded: \(isDownloaded)")
    }

    
    @IBAction func clickOn_btnAddToQueue(_ sender: UIButton) {
        guard let currentTrack = track else {
            showToast(message: "No track selected", font: .systemFont(ofSize: 12.0))
            return
        }
        
        // Add track to MusicPlayerViewController's track list
//        if let musicVC = AppPlayer.miniPlayerInfo.musicVC {
//            musicVC.track?.append(currentTrack)
//            musicVC.tempTrack = musicVC.track
//            musicVC.manageTableViewScroll()
//            showToast(message: "Added to queue", font: .systemFont(ofSize: 12.0))
//        } else {
//            // Fallback: Notify user if queue is not available
//            showToast(message: "Queue not available", font: .systemFont(ofSize: 12.0))
//        }
//        
        delegate?.didUpdateTrackMetadata()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func clickOn_btnAddToCollection(_ sender: UIButton) {
        guard let currentTrack = track else {
            showToast(message: "No track selected", font: .systemFont(ofSize: 12.0))
            return
        }
        
        print("Adding to collection for trackID: \(currentTrack.trackid)")
        
        var savedTracks = UserDefaultsManager.shared.localTracksData
        if let trackIndex = savedTracks.firstIndex(where: { $0.trackid == currentTrack.trackid }) {
            savedTracks[trackIndex].isBookMarked = !savedTracks[trackIndex].isBookMarked
            let message = savedTracks[trackIndex].isBookMarked ? "Added to My Collection" : "Removed from My Collection"
            print("Track \(currentTrack.trackid) bookmark status updated to: \(savedTracks[trackIndex].isBookMarked)")
            showToast(message: message, font: .systemFont(ofSize: 12.0))
            sender.setImage(UIImage(named: savedTracks[trackIndex].isBookMarked ? "ic_bookmark_fill" : "ic_bookmark"), for: .normal)
        } else {
            let newItem = currentTrack.convertToSongModel()
            newItem.isBookMarked = true
            savedTracks.append(newItem)
            print("New track \(currentTrack.trackid) added to collection")
            showToast(message: "Added to My Collection", font: .systemFont(ofSize: 12.0))
            sender.setImage(UIImage(named: "ic_bookmark_fill"), for: .normal)
        }
        
        UserDefaultsManager.shared.localTracksData = savedTracks
        delegate?.didUpdateTrackMetadata()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func clickOn_btnDownload(_ sender: UIButton) {
        guard let currentTrack = track else {
            showToast(message: "No track selected", font: .systemFont(ofSize: 12.0))
            return
        }
        
        let purchase = IAPHandler.shared.isGetPurchase()
        if purchase {
            guard let urlString = currentTrack.mediaPath?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: songPath + urlString) else {
                showToast(message: "Invalid track URL", font: .systemFont(ofSize: 12.0))
                return
            }
            
            let name = url.lastPathComponent
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsURL.appendingPathComponent(name)
            
            // UI: Show progress view
            let progressView = UIProgressView(frame: CGRect(x: sender.frame.origin.x, y: sender.frame.origin.y + sender.frame.height + 5, width: sender.frame.width, height: 10))
            progressView.progress = 0.0
            view.addSubview(progressView)
            sender.isHidden = true
            
            // Start download
            AF.download(url, to: { _, _ in
                (destinationURL, [.removePreviousFile, .createIntermediateDirectories])
            })
            .downloadProgress { progress in
                DispatchQueue.main.async {
                    progressView.setProgress(Float(progress.fractionCompleted), animated: true)
                }
                if progress.fractionCompleted == 1.0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        progressView.removeFromSuperview()
                        sender.isHidden = false
                        let image = UIImage(systemName: "checkmark.circle.fill")?.withRenderingMode(.alwaysTemplate)
                        sender.setImage(image, for: .normal)
                        sender.tintColor = .systemGreen
                        sender.layer.cornerRadius = 15
                        sender.layer.borderColor = UIColor.systemGreen.cgColor
                        sender.layer.borderWidth = 2
                        sender.clipsToBounds = true
                        sender.isUserInteractionEnabled = false
                        
                        // Update UserDefaults
                        var savedTracks = UserDefaultsManager.shared.localTracksData
                        if let trackIndex = savedTracks.firstIndex(where: { $0.trackid == currentTrack.trackid }) {
                            savedTracks[trackIndex].isDownload = true
                        } else {
                            let newItem = currentTrack.convertToSongModel()
                            newItem.isDownload = true
                            savedTracks.append(newItem)
                        }
                        UserDefaultsManager.shared.localTracksData = savedTracks
                        self.delegate?.didUpdateTrackMetadata()
                        self.showToast(message: "Download completed", font: .systemFont(ofSize: 12.0))
                    }
                }
            }
            .response { response in
                if let destinationURL = response.fileURL {
                    print("File downloaded to: \(destinationURL)")
                    UserDefaults.standard.set(currentTrack.artcover, forKey: "\(url.deletingPathExtension().lastPathComponent)")
                }
            }
        } else {
            let vc = storyboard?.instantiateViewController(withIdentifier: "IAPVC") as! IAPVC
            vc.isshowbackButton = true
            let navVC = UINavigationController(rootViewController: vc)
            navVC.navigationBar.isHidden = true
            navVC.modalPresentationStyle = .fullScreen
            present(navVC, animated: true)
        }
    }
    
    @IBAction func clickOn_btnViewInfo(_ sender: UIButton) {
        guard let currentTrack = track else {
            showToast(message: "No track selected", font: .systemFont(ofSize: 12.0))
            return
        }
        
        let vc = storyboard?.instantiateViewController(withIdentifier: "MoreInfoViewController") as! MoreInfoViewController
        vc.track = currentTrack
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func clickOn_btnViewLyrics(_ sender: UIButton) {
        guard let currentTrack = track else {
            showToast(message: "No track selected", font: .systemFont(ofSize: 12.0))
            return
        }
        
        let vc = storyboard?.instantiateViewController(withIdentifier: "LyricPlayViewController") as! LyricPlayViewController
        vc.currentSong = currentTrack.convertToSongModel()
        vc.imageURl = URL(string: currentTrack.artcover ?? "")
        vc.lyricnew = lyricsNew
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func clickOn_btnShare(_ sender: UIButton) {
        guard let currentTrack = track,
              let urlString = currentTrack.mediaPath?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: songPath + urlString) else {
            showToast(message: "No track selected", font: .systemFont(ofSize: 12.0))
            return
        }
        
        let shareText = "Check out \(currentTrack.track ?? "this track") by \(currentTrack.artist ?? "unknown artist") on Radio Srood!"
        let activityVC = UIActivityViewController(activityItems: [shareText, url], applicationActivities: nil)
        activityVC.modalPresentationStyle = .popover
        if let ppc = activityVC.popoverPresentationController {
            ppc.sourceView = sender
            ppc.sourceRect = sender.bounds
        }
        present(activityVC, animated: true, completion: nil)
    }
    
    @IBAction func clickOn_btnCancel(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
}
