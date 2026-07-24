//
//  SmartMixPlaylistViewController.swift
//  Radio Srood
//

import UIKit
import Alamofire

final class SmartMixPlaylistViewController: UI_VC, OptionsViewControllerDelegate {
    var playlist: SmartMixPlaylist!
    /// Full artist catalog used by Add Songs (not only selected mix artists).
    var allArtists: [ArtistProfileSummary] = []

    private var tracks: [Track] = []
    private var isShuffle = false
    private var isMixSaved = false
    private var isDownloadingMix = false
    private var tableBottomConstraint: NSLayoutConstraint?
    private var headerTopSpacerHeightConstraint: NSLayoutConstraint?

    private let headerGradientLayer = CAGradientLayer()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    private lazy var downloadButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(white: 0.16, alpha: 1)
        button.layer.cornerRadius = 22
        button.clipsToBounds = true
        button.setImage(UIImage(named: "ic_download")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .white
        button.imageView?.contentMode = .scaleAspectFit
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.addTarget(self, action: #selector(downloadTapped), for: .touchUpInside)
        button.widthAnchor.constraint(equalToConstant: 44).isActive = true
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }()

    private lazy var downloadProgressHost: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0.16, alpha: 1)
        view.layer.cornerRadius = 22
        view.clipsToBounds = true
        view.isHidden = true
        view.widthAnchor.constraint(equalToConstant: 44).isActive = true
        view.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return view
    }()

    private var circularProgressView: CircularProgressView!

    private lazy var bookmarkButton: UIButton = {
        makeCircleAction(systemName: "bookmark", action: #selector(bookmarkTapped), size: 44)
    }()

    private lazy var downloadProgressLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private lazy var downloadOverlay: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        view.isHidden = true

        let spinner = UIActivityIndicatorView(style: .whiteLarge)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()

        view.addSubview(spinner)
        view.addSubview(downloadProgressLabel)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -16),
            downloadProgressLabel.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 12),
            downloadProgressLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            downloadProgressLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
        return view
    }()

    private lazy var downloadActionContainer: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(downloadButton)
        container.addSubview(downloadProgressHost)
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 44),
            container.heightAnchor.constraint(equalToConstant: 44),
            downloadButton.topAnchor.constraint(equalTo: container.topAnchor),
            downloadButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            downloadButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            downloadButton.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            downloadProgressHost.topAnchor.constraint(equalTo: container.topAnchor),
            downloadProgressHost.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            downloadProgressHost.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            downloadProgressHost.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return container
    }()

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .black
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.delegate = self
        table.dataSource = self
        table.contentInsetAdjustmentBehavior = .never
        table.rowHeight = 88
        table.register(UINib(nibName: "SearchSongCell", bundle: nil), forCellReuseIdentifier: "SearchSongCell")
        return table
    }()

    private lazy var headerView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 520))
        view.backgroundColor = .clear
        return view
    }()

    private let headerTopSpacer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        button.layer.cornerRadius = 20
        button.tintColor = .white
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        button.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        button.addTarget(self, action: #selector(popBack), for: .touchUpInside)
        return button
    }()

    private let coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = UIColor(white: 0.12, alpha: 1)
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 26, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()

    private lazy var editTitleButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        button.setImage(UIImage(systemName: "pencil", withConfiguration: config), for: .normal)
        button.addTarget(self, action: #selector(editTitleTapped), for: .touchUpInside)
        return button
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor(white: 0.65, alpha: 1)
        label.numberOfLines = 2
        return label
    }()

    private let statsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor(white: 0.5, alpha: 1)
        return label
    }()

    private lazy var actionStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            downloadActionContainer,
            bookmarkButton,
            makePlayButton(),
            makeCircleAction(systemName: "shuffle", action: #selector(shuffleTapped), size: 44),
            makeCircleAction(systemName: "plus", action: #selector(addSongsTapped), size: 44)
        ])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        return stack
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        tracks = playlist.tracks
        setupHeaderGradient()
        setupTableView()
        setupHeaderView()
        setupDownloadOverlay()
        setupCircularProgress()
        setupLongPress()
        configureHeaderContent()
        loadCollage()
        refreshActionButtonStates()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        updateBottomInset()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        headerTopSpacerHeightConstraint?.constant = view.safeAreaInsets.top
        resizeHeaderIfNeeded()
        headerGradientLayer.frame = headerView.bounds
    }

    override func fixMiniplayerSpace() {
        super.fixMiniplayerSpace()
        updateBottomInset()
    }

    func didUpdateTrackMetadata() {
        tableView.reloadData()
    }

    private var mainStoryboard: UIStoryboard {
        UIStoryboard(name: "Main", bundle: nil)
    }

    private func setupHeaderGradient() {
        headerGradientLayer.colors = [
            UIColor(red: 0.35, green: 0.16, blue: 0.14, alpha: 1).cgColor,
            UIColor.black.cgColor
        ]
        headerGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        headerGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        headerView.layer.insertSublayer(headerGradientLayer, at: 0)
    }

    private func setupTableView() {
        view.addSubview(tableView)
        view.addSubview(backButton)

        activityIndicator.color = .white
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)

        let tableBottom = tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        tableBottomConstraint = tableBottom

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableBottom,

            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        view.bringSubviewToFront(backButton)
    }

    private func setupHeaderView() {
        headerView.addSubview(headerTopSpacer)
        headerView.addSubview(coverImageView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(editTitleButton)
        headerView.addSubview(subtitleLabel)
        headerView.addSubview(statsLabel)
        headerView.addSubview(actionStack)

        let spacerHeight = headerTopSpacer.heightAnchor.constraint(equalToConstant: 0)
        headerTopSpacerHeightConstraint = spacerHeight

        NSLayoutConstraint.activate([
            headerTopSpacer.topAnchor.constraint(equalTo: headerView.topAnchor),
            headerTopSpacer.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            headerTopSpacer.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            spacerHeight,

            coverImageView.topAnchor.constraint(equalTo: headerTopSpacer.bottomAnchor, constant: 12),
            coverImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            coverImageView.widthAnchor.constraint(equalToConstant: 250),
            coverImageView.heightAnchor.constraint(equalToConstant: 250),

            titleLabel.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),

            editTitleButton.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            editTitleButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            editTitleButton.widthAnchor.constraint(equalToConstant: 28),
            editTitleButton.heightAnchor.constraint(equalToConstant: 28),
            editTitleButton.trailingAnchor.constraint(lessThanOrEqualTo: headerView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),

            statsLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 6),
            statsLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            statsLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),

            actionStack.topAnchor.constraint(equalTo: statsLabel.bottomAnchor, constant: 18),
            actionStack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 36),
            actionStack.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -36),
            actionStack.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -18),
            actionStack.heightAnchor.constraint(equalToConstant: 58)
        ])

        tableView.tableHeaderView = headerView
    }

    private func configureHeaderContent() {
        titleLabel.text = playlist.title
        subtitleLabel.text = playlist.subtitle
        statsLabel.text = playlist.songCountText
    }

    private func loadCollage() {
        SmartMixBuilder.collageImage(from: playlist.artistPhotoURLs, size: 500) { [weak self] image in
            self?.coverImageView.image = image ?? UIImage(named: "Lav_Radio_Logo.png")
        }
    }

    private func setupDownloadOverlay() {
        view.addSubview(downloadOverlay)
        NSLayoutConstraint.activate([
            downloadOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            downloadOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            downloadOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            downloadOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupCircularProgress() {
        let progress = CircularProgressView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.lineWidth = 3
        progress.isHidden = true
        downloadProgressHost.addSubview(progress)
        NSLayoutConstraint.activate([
            progress.topAnchor.constraint(equalTo: downloadProgressHost.topAnchor),
            progress.leadingAnchor.constraint(equalTo: downloadProgressHost.leadingAnchor),
            progress.trailingAnchor.constraint(equalTo: downloadProgressHost.trailingAnchor),
            progress.bottomAnchor.constraint(equalTo: downloadProgressHost.bottomAnchor)
        ])
        circularProgressView = progress
    }

    private func refreshActionButtonStates() {
        let playlists = UserDefaultsManager.shared.playListsData
        isMixSaved = playlists.contains { $0.name == playlist.title }
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let bookmarkIcon = isMixSaved ? "bookmark.fill" : "bookmark"
        bookmarkButton.setImage(UIImage(systemName: bookmarkIcon, withConfiguration: config), for: .normal)
        bookmarkButton.tintColor = isMixSaved ? UIColor(red: 0.90, green: 0.12, blue: 0.18, alpha: 1) : .white

        applyDownloadButtonAppearance(isDownloaded: areAllTracksDownloaded())
    }

    private func applyDownloadButtonAppearance(isDownloaded: Bool) {
        if isDownloaded {
            // Match Options / player finished look: green check + outer ring, no dark fill.
            let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
            let image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: config)?
                .withRenderingMode(.alwaysTemplate)
            downloadButton.setImage(image, for: .normal)
            downloadButton.tintColor = .systemGreen
            downloadButton.backgroundColor = .clear
            downloadButton.layer.cornerRadius = 22
            downloadButton.layer.borderWidth = 2
            downloadButton.layer.borderColor = UIColor.systemGreen.cgColor
            downloadButton.clipsToBounds = true
            downloadButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
            downloadButton.isUserInteractionEnabled = false
        } else {
            downloadButton.setImage(UIImage(named: "ic_download")?.withRenderingMode(.alwaysTemplate), for: .normal)
            downloadButton.tintColor = .white
            downloadButton.backgroundColor = UIColor(white: 0.16, alpha: 1)
            downloadButton.layer.cornerRadius = 22
            downloadButton.layer.borderWidth = 0
            downloadButton.layer.borderColor = nil
            downloadButton.clipsToBounds = true
            downloadButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            downloadButton.isUserInteractionEnabled = true
        }

        downloadButton.isHidden = false
        downloadProgressHost.isHidden = true
        circularProgressView?.isHidden = true
        circularProgressView?.resetProgress()
    }

    private func areAllTracksDownloaded() -> Bool {
        guard !tracks.isEmpty else { return false }
        let saved = UserDefaultsManager.shared.localTracksData
        for track in tracks {
            guard let id = track.trackid else { return false }
            let downloaded = saved.contains { $0.trackid == id && $0.isDownload }
            if !downloaded { return false }
        }
        return true
    }

    private func makeCircleAction(systemName: String, action: Selector, size: CGFloat) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.backgroundColor = UIColor(white: 0.16, alpha: 1)
        button.layer.cornerRadius = size / 2
        let config = UIImage.SymbolConfiguration(pointSize: size == 58 ? 22 : 16, weight: .medium)
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.widthAnchor.constraint(equalToConstant: size).isActive = true
        button.heightAnchor.constraint(equalToConstant: size).isActive = true
        return button
    }

    private func makePlayButton() -> UIButton {
        let button = makeCircleAction(systemName: "play.fill", action: #selector(playTapped), size: 58)
        button.backgroundColor = UIColor(red: 0.90, green: 0.12, blue: 0.18, alpha: 1)
        return button
    }

    private func setupLongPress() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.3
        longPress.cancelsTouchesInView = false
        tableView.addGestureRecognizer(longPress)
    }

    private func resizeHeaderIfNeeded() {
        guard let header = tableView.tableHeaderView else { return }
        let targetWidth = tableView.bounds.width
        guard targetWidth > 0 else { return }

        header.frame.size.width = targetWidth
        header.setNeedsLayout()
        header.layoutIfNeeded()

        let height = header.systemLayoutSizeFitting(
            CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        if abs(header.frame.height - height) > 1 {
            header.frame.size.height = height
            tableView.tableHeaderView = header
        }
    }

    private var podcastTracks: [PodcastObject] {
        tracks.map { $0.convertToPodcastModel() }
    }

    private func updateBottomInset() {
        let miniPlayerInset = TabbarVC.isMiniPlayerVisible ? 60.0 : 0.0
        tableBottomConstraint?.constant = -miniPlayerInset
        tableView.contentInset.bottom = miniPlayerInset
        view.layoutIfNeeded()
    }

    private func openPlayer(at index: Int) {
        guard index >= 0, index < podcastTracks.count else { return }
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "MyMusicPlayerViewController") as! MyMusicPlayerViewController
        vc.selectedIndex = index
        vc.tempTrack = podcastTracks
        vc.track = podcastTracks
        vc.isShuffle = isShuffle
        vc.isShowOptionList = true
        navigationController?.pushViewController(vc, animated: true)
    }

    private func presentOptions(for track: Track) {
        guard let optionsVC = mainStoryboard.instantiateViewController(withIdentifier: "OptionsViewController") as? OptionsViewController else {
            return
        }
        optionsVC.track = track
        optionsVC.delegate = self
        optionsVC.modalPresentationStyle = .overFullScreen
        present(optionsVC, animated: true)
    }

    private func refreshStats() {
        playlist.tracks = tracks
        statsLabel.text = playlist.songCountText
        tableView.reloadData()
    }

    @objc private func popBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func playTapped() {
        openPlayer(at: 0)
    }

    @objc private func shuffleTapped() {
        isShuffle.toggle()
        openPlayer(at: Int.random(in: 0..<max(tracks.count, 1)))
    }

    @objc private func downloadTapped() {
        guard !tracks.isEmpty else { return }
        guard !isDownloadingMix else { return }

        if areAllTracksDownloaded() {
            showToast(message: "All songs already downloaded", font: .systemFont(ofSize: 12))
            return
        }

        let purchase = IAPHandler.shared.isGetPurchase()
        if !purchase {
            let vc = mainStoryboard.instantiateViewController(withIdentifier: "IAPVC") as! IAPVC
            vc.isshowbackButton = true
            let navVC = UINavigationController(rootViewController: vc)
            navVC.navigationBar.isHidden = true
            navVC.modalPresentationStyle = .fullScreen
            present(navVC, animated: true)
            return
        }

        startDownloadingMix()
    }

    @objc private func bookmarkTapped() {
        guard !tracks.isEmpty else { return }

        var playlists = UserDefaultsManager.shared.playListsData

        if let index = playlists.firstIndex(where: { $0.name == playlist.title }) {
            // Toggle OFF — remove saved mix playlist.
            SmartMixBuilder.deleteCoverImage(at: playlists[index].coverImagePath)
            playlists.remove(at: index)
            UserDefaultsManager.shared.playListsData = playlists
            isMixSaved = false
            refreshActionButtonStates()
            showToast(message: "Removed from My Music", font: .systemFont(ofSize: 12))
            return
        }

        // Toggle ON — save mix as a playlist with artist collage cover (not first song art).
        let newPlayList = PlayListModel()
        newPlayList.name = playlist.title
        newPlayList.songs = tracks.map { $0.convertToSongModel() }
        if let collage = coverImageView.image {
            newPlayList.coverImagePath = SmartMixBuilder.saveCoverImage(collage, playlistName: playlist.title) ?? ""
        }
        if newPlayList.coverImagePath.isEmpty {
            SmartMixBuilder.collageImage(from: playlist.artistPhotoURLs, size: 400) { [weak self] image in
                guard let self = self, let image = image else { return }
                var updated = UserDefaultsManager.shared.playListsData
                if let idx = updated.firstIndex(where: { $0.name == self.playlist.title }) {
                    updated[idx].coverImagePath = SmartMixBuilder.saveCoverImage(image, playlistName: self.playlist.title) ?? ""
                    UserDefaultsManager.shared.playListsData = updated
                }
            }
        }
        playlists.append(newPlayList)
        UserDefaultsManager.shared.playListsData = playlists
        isMixSaved = true
        refreshActionButtonStates()
        showToast(message: "Playlist saved to My Music", font: .systemFont(ofSize: 12))
    }

    private func startDownloadingMix() {
        let pending = tracks.filter { track in
            guard let id = track.trackid else { return true }
            let saved = UserDefaultsManager.shared.localTracksData
            return !saved.contains { $0.trackid == id && $0.isDownload }
        }

        guard !pending.isEmpty else {
            refreshActionButtonStates()
            showToast(message: "All songs already downloaded", font: .systemFont(ofSize: 12))
            return
        }

        isDownloadingMix = true
        downloadOverlay.isHidden = false
        downloadProgressLabel.isHidden = false
        downloadProgressLabel.text = "Downloading 0/\(pending.count)"

        // Same progress UI pattern as Options / Music Player.
        downloadButton.isHidden = true
        downloadProgressHost.isHidden = false
        circularProgressView.isHidden = false
        circularProgressView.lineWidth = 3
        circularProgressView.resetProgress()
        circularProgressView.setProgress(0)

        downloadTracksSequentially(pending, index: 0, successCount: 0, totalCount: pending.count)
    }

    private func downloadTracksSequentially(_ pending: [Track], index: Int, successCount: Int, totalCount: Int) {
        if index >= pending.count {
            // Finish animation like OptionsViewController.
            circularProgressView.setProgress(1.0)
            circularProgressView.lineWidth = 3
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.isDownloadingMix = false
                    self.downloadOverlay.isHidden = true
                    self.downloadProgressLabel.isHidden = true
                    self.downloadProgressHost.isHidden = true
                    self.circularProgressView.resetProgress()
                    self.circularProgressView.isHidden = true
                    self.applyDownloadButtonAppearance(isDownloaded: self.areAllTracksDownloaded())
                    self.showToast(
                        message: "Downloaded \(successCount) of \(totalCount) songs",
                        font: .systemFont(ofSize: 12)
                    )
                }
            }
            return
        }

        let track = pending[index]
        downloadProgressLabel.text = "Downloading \(index + 1)/\(totalCount)"
        let overall = Float(index) / Float(max(totalCount, 1))
        circularProgressView.setProgress(overall)

        guard let mediaPath = track.mediaPath,
              let encoded = mediaPath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: songPath + encoded) else {
            downloadTracksSequentially(pending, index: index + 1, successCount: successCount, totalCount: totalCount)
            return
        }

        let name = url.lastPathComponent
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsURL.appendingPathComponent(name)

        AF.download(url, to: { _, _ in
            (destinationURL, [.removePreviousFile, .createIntermediateDirectories])
        })
        .downloadProgress { [weak self] progress in
            guard let self = self else { return }
            let base = Float(index) / Float(max(totalCount, 1))
            let slice = Float(progress.fractionCompleted) / Float(max(totalCount, 1))
            DispatchQueue.main.async {
                self.circularProgressView.setProgress(base + slice)
            }
        }
        .response { [weak self] response in
            guard let self = self else { return }
            var nextSuccess = successCount
            if response.error == nil {
                nextSuccess += 1
                self.markTrackDownloaded(track)
                if let artcover = track.artcover {
                    UserDefaults.standard.set(artcover, forKey: "\(url.deletingPathExtension().lastPathComponent)")
                }
            }
            self.downloadTracksSequentially(pending, index: index + 1, successCount: nextSuccess, totalCount: totalCount)
        }
    }

    private func markTrackDownloaded(_ track: Track) {
        var savedTracks = UserDefaultsManager.shared.localTracksData
        if let trackID = track.trackid,
           let index = savedTracks.firstIndex(where: { $0.trackid == trackID }) {
            savedTracks[index].isDownload = true
        } else {
            let song = track.convertToSongModel()
            song.isDownload = true
            savedTracks.append(song)
        }
        UserDefaultsManager.shared.localTracksData = savedTracks
    }

    @objc private func addSongsTapped() {
        let addVC = SmartMixAddSongsViewController()
        addVC.delegate = self
        addVC.existingTrackIDs = Set(tracks.compactMap { $0.trackid })
        addVC.allArtists = allArtists.isEmpty ? playlist.artists : allArtists
        addVC.modalPresentationStyle = .overFullScreen
        addVC.modalTransitionStyle = .coverVertical
        present(addVC, animated: true)
    }

    @objc private func editTitleTapped() {
        let alert = UIAlertController(title: "Rename Mix", message: nil, preferredStyle: .alert)
        alert.addTextField { [weak self] field in
            field.text = self?.playlist.title
            field.clearButtonMode = .whileEditing
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak self] _ in
            guard let self = self,
                  let text = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !text.isEmpty else { return }
            self.playlist.title = text
            self.titleLabel.text = text
            self.refreshActionButtonStates()
        }))
        present(alert, animated: true)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let point = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point),
              indexPath.row < tracks.count else { return }
        presentOptions(for: tracks[indexPath.row])
    }
}

// MARK: - UITableView
extension SmartMixPlaylistViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tracks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchSongCell", for: indexPath) as! SearchSongCell
        cell.selectionStyle = .none
        let track = tracks[indexPath.row]
        let coverURL = track.thumbnailArtCoverURL?.absoluteString ?? track.artcover_200 ?? track.artcover ?? ""
        if let url = URL(string: coverURL) {
            cell.imgArtist.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            cell.imgBg.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
        }
        cell.lblSongName.text = track.track
        cell.lblArtistName.text = track.artist
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        openPlayer(at: indexPath.row)
    }
}

// MARK: - Add Songs
extension SmartMixPlaylistViewController: SmartMixAddSongsDelegate {
    func smartMixAddSongsDidAdd(_ track: Track) {
        if let id = track.trackid, tracks.contains(where: { $0.trackid == id }) {
            return
        }
        tracks.append(track)
        playlist.tracks = tracks
        refreshStats()
        // Keep saved playlist in sync if already bookmarked.
        if isMixSaved {
            var playlists = UserDefaultsManager.shared.playListsData
            if let index = playlists.firstIndex(where: { $0.name == playlist.title }) {
                playlists[index].songs = tracks.map { $0.convertToSongModel() }
                UserDefaultsManager.shared.playListsData = playlists
            }
        }
        refreshActionButtonStates()
    }
}
