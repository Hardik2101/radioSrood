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
    
    @IBOutlet var addTocoolectionImage: UIImageView!
    
    @IBOutlet var imgDownload: UIImageView!
    
    @IBOutlet var btnDownload: UIButton!
    
    @IBOutlet var imgAddToCollection: UIImageView!
    
    @IBOutlet var vwProgress: UIView!
    
    @IBOutlet var lblAddTocolletction: UILabel!
    
    weak var delegate: OptionsViewControllerDelegate? // Delegate to notify parent VC
    var circularProgressView: CircularProgressView!
    
    var track: Track? // Track passed from HomeViewController or MusicPlayerViewController
    var lyricsNew: String = "" // Synced lyrics for the track


    override func viewDidLoad() {
        super.viewDidLoad()
        addBlurBackground()
        updateButtonStates()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(updateButtonStates))
        imgDownload.isUserInteractionEnabled = true
        imgDownload.addGestureRecognizer(tapGesture)
        setupCircularProgressView()

    }
    override func viewWillAppear(_ animated: Bool) {
        let queue = PlaybackQueueManager.shared.getQueue()
            print("Initial queue: \(queue.map { $0.track ?? "unknown" })")
        
        print("ququeye count=====", queue.count)
    }
    
    private func setupCircularProgressView() {
        circularProgressView = CircularProgressView(frame: vwProgress.bounds)
        circularProgressView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        circularProgressView.isHidden = true
        vwProgress.addSubview(circularProgressView)
    }

    func updateDownloadIcon(isDownloaded: Bool) {
        guard let imgDownload = imgDownload else {
            print("Error: Download button not connected in storyboard")
            return
        }

        if isDownloaded {
            let image = UIImage(systemName: "checkmark.circle.fill")?.withRenderingMode(.alwaysTemplate)
            btnDownload.setImage(image, for: .normal)
            btnDownload.tintColor = .systemGreen

            btnDownload.layer.cornerRadius = 15
            btnDownload.layer.borderColor = UIColor.systemGreen.cgColor
            btnDownload.layer.borderWidth = 2
            btnDownload.clipsToBounds = true
            btnDownload.isUserInteractionEnabled = false
        } else {
            btnDownload.setImage(UIImage(named: "ic_download"), for: .normal)
            btnDownload.layer.cornerRadius = 0
            btnDownload.layer.borderWidth = 0
            btnDownload.layer.borderColor = nil
            btnDownload.clipsToBounds = false
            btnDownload.isUserInteractionEnabled = true

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
        
        self.addTocoolectionImage.image = UIImage(named: isBookmarked ? "" : "")
        if isBookmarked {
            self.lblAddTocolletction.text = "Remove from Colletion"
            self.addTocoolectionImage.image = UIImage(named: "ic_bookmark_fill")
        } else {
            self.lblAddTocolletction.text = "Add to Collection"
            self.addTocoolectionImage.image = UIImage(named: "ic_bookmark")

        }
        
        updateDownloadIcon(isDownloaded: isDownloaded)
        
        print("Updating button states for trackID: \(currentTrack.trackid), isBookmarked: \(isBookmarked), isDownloaded: \(isDownloaded)")
    }

    
    @IBAction func clickOn_btnAddToQueue(_ sender: UIButton) {
        guard let currentTrack = track else {
            showToast(message: "No track selected", font: .systemFont(ofSize: 12.0))
            return
        }
        
        PlaybackQueueManager.shared.addToQueue(track!)
        showToast(message: "Added to queue", font: .systemFont(ofSize: 12.0))

        print("Added to queue")

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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            self.dismiss(animated: true, completion: nil)
        })
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
//            sender.setImage(UIImage(named: savedTracks[trackIndex].isBookMarked ? "ic_bookmark_fill" : "ic_bookmark"), for: .normal)
            self.lblAddTocolletction.text = savedTracks[trackIndex].isBookMarked ? "Remove from Collection" : "Add to Collection"
            self.imgAddToCollection.image = savedTracks[trackIndex].isBookMarked ? UIImage(named: "ic_bookmark_fill") :  UIImage(named: "ic_bookmark")
            
        } else {
            let newItem = currentTrack.convertToSongModel()
            newItem.isBookMarked = true
            savedTracks.append(newItem)
            print("New track \(currentTrack.trackid) added to collection")
            showToast(message: "Added to My Collection", font: .systemFont(ofSize: 12.0))
            self.lblAddTocolletction.text =  "Remove from Collection"
            self.imgAddToCollection.image =  UIImage(named: "ic_bookmark_fill")
//            sender.setImage(UIImage(named: "ic_bookmark_fill"), for: .normal)
        }
        
        UserDefaultsManager.shared.localTracksData = savedTracks
        delegate?.didUpdateTrackMetadata()
//        dismiss(animated: true, completion: nil)
    }
    
//    @IBAction func clickOn_imgDownload(_ sender: UIButton) {
//        guard let currentTrack = track else {
//            showToast(message: "No track selected", font: .systemFont(ofSize: 12.0))
//            return
//        }
//        
//        let purchase = IAPHandler.shared.isGetPurchase()
//        if purchase {
//            guard let urlString = currentTrack.mediaPath?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
//                  let url = URL(string: songPath + urlString) else {
//                showToast(message: "Invalid track URL", font: .systemFont(ofSize: 12.0))
//                return
//            }
//            
//            let name = url.lastPathComponent
//            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//            let destinationURL = documentsURL.appendingPathComponent(name)
//            
//            // UI: Show progress view
//            let progressView = UIProgressView(frame: CGRect(x: sender.frame.origin.x, y: sender.frame.origin.y + sender.frame.height + 5, width: sender.frame.width, height: 10))
//            progressView.progress = 0.0
//            view.addSubview(progressView)
//            sender.isHidden = true
//            
//            // Start download
//            AF.download(url, to: { _, _ in
//                (destinationURL, [.removePreviousFile, .createIntermediateDirectories])
//            })
//            .downloadProgress { progress in
//                DispatchQueue.main.async {
//                    progressView.setProgress(Float(progress.fractionCompleted), animated: true)
//                }
//                if progress.fractionCompleted == 1.0 {
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                        progressView.removeFromSuperview()
//                        sender.isHidden = false
//                        let image = UIImage(systemName: "checkmark.circle.fill")?.withRenderingMode(.alwaysTemplate)
//                        sender.setImage(image, for: .normal)
//                        sender.tintColor = .systemGreen
//                        sender.layer.cornerRadius = 15
//                        sender.layer.borderColor = UIColor.systemGreen.cgColor
//                        sender.layer.borderWidth = 2
//                        sender.clipsToBounds = true
//                        sender.isUserInteractionEnabled = false
//                        
//                        // Update UserDefaults
//                        var savedTracks = UserDefaultsManager.shared.localTracksData
//                        if let trackIndex = savedTracks.firstIndex(where: { $0.trackid == currentTrack.trackid }) {
//                            savedTracks[trackIndex].isDownload = true
//                        } else {
//                            let newItem = currentTrack.convertToSongModel()
//                            newItem.isDownload = true
//                            savedTracks.append(newItem)
//                        }
//                        UserDefaultsManager.shared.localTracksData = savedTracks
//                        self.delegate?.didUpdateTrackMetadata()
//                        self.showToast(message: "Download completed", font: .systemFont(ofSize: 12.0))
//                    }
//                }
//            }
//            .response { response in
//                if let destinationURL = response.fileURL {
//                    print("File downloaded to: \(destinationURL)")
//                    UserDefaults.standard.set(currentTrack.artcover, forKey: "\(url.deletingPathExtension().lastPathComponent)")
//                }
//            }
//        } else {
//            let vc = storyboard?.instantiateViewController(withIdentifier: "IAPVC") as! IAPVC
//            vc.isshowbackButton = true
//            let navVC = UINavigationController(rootViewController: vc)
//            navVC.navigationBar.isHidden = true
//            navVC.modalPresentationStyle = .fullScreen
//            present(navVC, animated: true)
//        }
//    }
    
    @IBAction func clickOn_btnDownload(_ sender: UIButton) {
        guard let currentTrack = track else {
            showToast(message: "No track selected", font: .systemFont(ofSize: 12.0))
            return
        }

        let purchase = IAPHandler.shared.isGetPurchase()
        if !purchase {
            let vc = storyboard?.instantiateViewController(withIdentifier: "IAPVC") as! IAPVC
            vc.isshowbackButton = true
            let navVC = UINavigationController(rootViewController: vc)
            navVC.navigationBar.isHidden = true
            navVC.modalPresentationStyle = .fullScreen
            present(navVC, animated: true)
            return
        }

        guard let urlString = currentTrack.mediaPath?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: songPath + urlString) else {
            showToast(message: "Invalid track URL", font: .systemFont(ofSize: 12.0))
            return
        }

        let name = url.lastPathComponent
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsURL.appendingPathComponent(name)

        btnDownload.isHidden = true
        vwProgress.isHidden = false
        circularProgressView.setProgress(0)
        circularProgressView.isHidden = false

        AF.download(url, to: { _, _ in
            (destinationURL, [.removePreviousFile, .createIntermediateDirectories])
        })
        .downloadProgress { progress in
            DispatchQueue.main.async {
                self.circularProgressView.setProgress(Float(progress.fractionCompleted))
            }

            if progress.fractionCompleted == 1.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.circularProgressView.setProgress(1.0)
                    self.circularProgressView.lineWidth = 2

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.vwProgress.isHidden = true
                        self.btnDownload.isHidden = false
                        self.circularProgressView.resetProgress()

                        let image = UIImage(systemName: "checkmark.circle.fill")?.withRenderingMode(.alwaysTemplate)
                        self.btnDownload.setImage(image, for: .normal)
                        self.btnDownload.tintColor = .systemGreen
                        self.btnDownload.layer.cornerRadius = 15
                        self.btnDownload.layer.borderColor = UIColor.systemGreen.cgColor
                        self.btnDownload.layer.borderWidth = 2
                        self.btnDownload.clipsToBounds = true
                        self.btnDownload.isUserInteractionEnabled = false
                    }

                    // Update UserDefaults
                    var savedTracks = UserDefaultsManager.shared.localTracksData
                    if let index = savedTracks.firstIndex(where: { $0.trackid == currentTrack.trackid }) {
                        var track = savedTracks[index]
                        track.isDownload = true
                        savedTracks[index] = track
                    } else {
                        var newItem = currentTrack.convertToSongModel()
                        newItem.isDownload = true
                        savedTracks.append(newItem)
                    }

                    UserDefaultsManager.shared.localTracksData = savedTracks

                    self.showToast(message: "Download completed", font: .systemFont(ofSize: 12.0))
                    self.delegate?.didUpdateTrackMetadata()

                }
            }
        }
        .response { response in
            if let destinationURL = response.fileURL {
                print("File downloaded to: \(destinationURL)")
                UserDefaults.standard.set(currentTrack.artcover, forKey: "\(url.deletingPathExtension().lastPathComponent)")
            }
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


import Foundation

import Foundation

class PlaybackQueueManager {
    static let shared = PlaybackQueueManager()
    private var queue: [Track] = []
    private let queueKey = "PlaybackQueue"
    
    private init() {
        loadQueue()
    }
    
    func addToQueue(_ track: Track) {
        queue.append(track)
        print("Added to queue: \(track.track ?? "unknown") by \(track.artist ?? "unknown")")
        saveQueue()
        NotificationCenter.default.post(name: .queueUpdated, object: nil)
    }
    
    func getQueue() -> [Track] {
        return queue
    }
    
    func removeFromQueue(at index: Int) {
        guard index >= 0 && index < queue.count else {
            print("Error: Invalid queue index \(index)")
            return
        }
        let removedTrack = queue.remove(at: index)
        print("Removed from queue: \(removedTrack.track ?? "unknown")")
        saveQueue()
        NotificationCenter.default.post(name: .queueUpdated, object: nil)
    }
    
    func clearQueue() {
        queue.removeAll()
        saveQueue()
        NotificationCenter.default.post(name: .queueUpdated, object: nil)
    }
    
    // New method to get the next track to play
    func getNextTrack(currentIndex: Int, tracks: [Track]?) -> (track: Track, isFromQueue: Bool, index: Int)? {
        // Check queue first
        if !queue.isEmpty {
            let nextTrack = queue[0]
            return (nextTrack, true, 0)
        }
        // If queue is empty, check tracks array
        if let tracks = tracks, currentIndex < tracks.count - 1 {
            let nextIndex = currentIndex + 1
            return (tracks[nextIndex], false, nextIndex)
        }
        // No next track available
        return nil
    }
    
    private func saveQueue() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(queue)
            UserDefaults.standard.set(data, forKey: queueKey)
            print("Saved queue to UserDefaults, count: \(queue.count)")
        } catch {
            print("Error saving queue to UserDefaults: \(error)")
        }
    }
    
    private func loadQueue() {
        if let data = UserDefaults.standard.data(forKey: queueKey) {
            do {
                let decoder = JSONDecoder()
                queue = try decoder.decode([Track].self, from: data)
                print("Loaded queue from UserDefaults, count: \(queue.count)")
            } catch {
                print("Error loading queue from UserDefaults: \(error)")
                queue = []
            }
        } else {
            print("No queue found in UserDefaults")
            queue = []
        }
    }
}

// Notification name for queue updates
extension Notification.Name {
    static let queueUpdated = Notification.Name("QueueUpdated")
}
