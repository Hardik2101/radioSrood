//
//  SplashViewController.swift
//  Radio Srood
//
//  Created by Hardik on 11/03/26.
//  Copyright © 2026 Radio Srood Inc. All rights reserved.
//

/// Splash screen that plays `radio_srood.gif` while the app initialises in the background.
/// Drop this file into your project, then wire it up in `AppDelegate` / `SceneDelegate`
/// (see `AppDelegate+Splash.swift` for the integration code).
import UIKit
import ImageIO

final class SplashViewController: UIViewController {
    
    // MARK: - Configuration
    
    private let gifName = "radio_srood"
    private let minimumDisplayDuration: TimeInterval = 2.5
    
    // MARK: - State
    
    var onReady: (() -> Void)?
    
    private var gifFinished = false
    private var appReady    = false
    private var splashStart = Date()
    
    // MARK: - UI
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white  // ← change .black to .white (or your GIF bg color)
        buildUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Start the clock AFTER the view is actually on screen
        splashStart = Date()
        // Decode GIF on background thread — never blocks the main thread
        decodeGIFAsync()
    }
    
    override var prefersStatusBarHidden: Bool { true }
    
    // MARK: - UI
    
    private func buildUI() {
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
    // MARK: - GIF Decoding (background thread)
    
    private func decodeGIFAsync() {
        // ✅ Show first frame instantly on main thread — eliminates black flash
        if let url = Bundle.main.url(forResource: gifName, withExtension: "gif"),
           let source = CGImageSourceCreateWithURL(url as CFURL, nil),
           let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) {
            self.imageView.image = UIImage(cgImage: cgImage)
        }

        // Full GIF decode on background thread
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }

            guard
                let url    = Bundle.main.url(forResource: self.gifName, withExtension: "gif"),
                let source = CGImageSourceCreateWithURL(url as CFURL, nil)
            else {
                print("⚠️  SplashViewController: '\(self.gifName).gif' not found in bundle.")
                DispatchQueue.main.async { self.markGIFFinished() }
                return
            }

            let (frames, totalDuration) = self.extractFrames(from: source)

            guard !frames.isEmpty else {
                DispatchQueue.main.async { self.markGIFFinished() }
                return
            }

            let animation = UIImage.animatedImage(with: frames, duration: totalDuration)

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.imageView.image = animation  // ✅ Replace static frame with full animation

                let elapsed   = Date().timeIntervalSince(self.splashStart)
                let remaining = max(totalDuration, self.minimumDisplayDuration) - elapsed
                DispatchQueue.main.asyncAfter(deadline: .now() + max(remaining, 0)) { [weak self] in
                    self?.markGIFFinished()
                }
            }
        }
    }
    
    private func extractFrames(from source: CGImageSource) -> ([UIImage], TimeInterval) {
        let count = CGImageSourceGetCount(source)
        var frames: [UIImage]     = []
        var totalDuration: Double = 0
        
        for i in 0 ..< count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            let delay = frameDuration(at: i, source: source)
            totalDuration += delay
            let repeatCount = max(Int(delay * 60), 1)
            for _ in 0 ..< repeatCount {
                frames.append(UIImage(cgImage: cgImage))
            }
        }
        return (frames, totalDuration)
    }
    
    private func frameDuration(at index: Int, source: CGImageSource) -> TimeInterval {
        let defaultDelay: TimeInterval = 0.1
        guard
            let props    = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
            let gifProps = props[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        else { return defaultDelay }
        
        let delay = (gifProps[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval)
        ?? (gifProps[kCGImagePropertyGIFDelayTime]          as? TimeInterval)
        ?? defaultDelay
        return delay < 0.02 ? 0.1 : delay
    }
    
    // MARK: - Completion
    
    func markAppReady() {
        DispatchQueue.main.async { [weak self] in
            self?.appReady = true
            self?.checkIfReady()
        }
    }
    
    private func markGIFFinished() {
        gifFinished = true
        checkIfReady()
    }
    
    private func checkIfReady() {
        guard gifFinished, appReady else { return }
        onReady?()
    }
}
