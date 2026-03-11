//
//  NoInternetViewController.swift
//  Radio Srood
//
//  Created by Hardik on 11/03/26.
//  Copyright © 2026 Radio Srood Inc. All rights reserved.
//

import UIKit

/// A simple full-screen offline screen with two actions:
///  - Try Again: re-checks connectivity
///  - Go to downloads: opens the offline downloads screen
final class NoInternetViewController: UIViewController {
    
    // MARK: - Public callbacks
    
    /// Called after the view controller is dismissed when the user taps **Try Again**.
    var onRetry: (() -> Void)?
    
    /// Called after the view controller is dismissed when the user taps **Go to downloads**.
    var onGoToDownloads: (() -> Void)?
    
    // MARK: - UI Elements
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        // Replace "offline_icon" with your asset name that matches the design screenshot
        imageView.image = UIImage(named: "ic_offline")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "You're offline"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "With Music Premium, you can download songs so you're never left without music"
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Try Again", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let downloadsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Go to downloads", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .white
        button.layer.cornerRadius = 22
        button.layer.masksToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 24, bottom: 10, right: 24)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(iconImageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(downloadsButton)
        view.addSubview(retryButton)
        
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -80),
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            iconImageView.heightAnchor.constraint(equalToConstant: 80),
            
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            downloadsButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            downloadsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            downloadsButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
            downloadsButton.heightAnchor.constraint(equalToConstant: 44),
            
            retryButton.topAnchor.constraint(equalTo: downloadsButton.bottomAnchor, constant: 16),
            retryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        downloadsButton.addTarget(self, action: #selector(handleDownloads), for: .touchUpInside)
        retryButton.addTarget(self, action: #selector(handleRetry), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc private func handleRetry() {
        dismiss(animated: true) { [weak self] in
            self?.onRetry?()
        }
    }
    
    @objc private func handleDownloads() {
        dismiss(animated: true) { [weak self] in
            self?.onGoToDownloads?()
        }
    }
}

// MARK: - Helper for presentation

extension UIViewController {
    
    /// Presents the offline screen full-screen when there is no internet connection.
    /// - Parameters:
    ///   - onRetry: Called when the user taps **Try Again**.
    ///   - onGoToDownloads: Called when the user taps **Go to downloads**.
    func presentNoInternetScreen(onRetry: (() -> Void)? = nil,
                                 onGoToDownloads: (() -> Void)? = nil) {
        let offlineVC = NoInternetViewController()
        offlineVC.modalPresentationStyle = .fullScreen
        offlineVC.modalTransitionStyle = .crossDissolve
        offlineVC.onRetry = onRetry
        offlineVC.onGoToDownloads = onGoToDownloads
        
        if let presented = presentedViewController {
            presented.dismiss(animated: false) {
                self.present(offlineVC, animated: true, completion: nil)
            }
        } else {
            present(offlineVC, animated: true, completion: nil)
        }
    }
}

