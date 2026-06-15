//
//  SearchPlaylistDetailViewController.swift
//  Radio Srood
//

import UIKit

final class SearchPlaylistDetailViewController: UI_VC, OptionsViewControllerDelegate {
    var playlistPID: String = ""
    var fallbackPlaylist: SearchSubPlaylist?

    private var tracks: [Track] = []
    private var playlistInfo: SearchPlaylistInfo?
    private var isShuffle = false

    private var tableBottomConstraint: NSLayoutConstraint?
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let headerGradientLayer = CAGradientLayer()
    private let headerTopSpacer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    private var headerTopSpacerHeightConstraint: NSLayoutConstraint?

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
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 460))
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
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()

    private let statsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor(white: 0.55, alpha: 1)
        return label
    }()

    private lazy var shuffleButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        button.setImage(UIImage(systemName: "shuffle", withConfiguration: config), for: .normal)
        button.addTarget(self, action: #selector(shuffleTapped), for: .touchUpInside)
        return button
    }()

    private lazy var playButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(red: 0.90, green: 0.10, blue: 0.15, alpha: 1)
        button.tintColor = .white
        button.layer.cornerRadius = 28
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
        button.setImage(UIImage(systemName: "play.fill", withConfiguration: config), for: .normal)
        button.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupHeaderGradient()
        setupTableView()
        setupHeaderView()
        setupLongPress()
        applyFallbackInfo()
        fetchPlaylist()
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
        updateGradientFrames()
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
        applyHeaderGradient(topColor: UIColor(white: 0.14, alpha: 1), animated: false)

        headerGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        headerGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        headerView.layer.insertSublayer(headerGradientLayer, at: 0)
    }

    private func setupTableView() {
        view.addSubview(tableView)
        view.addSubview(backButton)

        activityIndicator.color = .white
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
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
        headerView.addSubview(statsLabel)
        headerView.addSubview(shuffleButton)
        headerView.addSubview(playButton)

        let spacerHeight = headerTopSpacer.heightAnchor.constraint(equalToConstant: 0)
        headerTopSpacerHeightConstraint = spacerHeight

        NSLayoutConstraint.activate([
            headerTopSpacer.topAnchor.constraint(equalTo: headerView.topAnchor),
            headerTopSpacer.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            headerTopSpacer.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            spacerHeight,

            coverImageView.topAnchor.constraint(equalTo: headerTopSpacer.bottomAnchor, constant: 8),
            coverImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            coverImageView.widthAnchor.constraint(equalToConstant: 270),
            coverImageView.heightAnchor.constraint(equalToConstant: 270),

            playButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            playButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 56),
            playButton.heightAnchor.constraint(equalToConstant: 56),

            shuffleButton.trailingAnchor.constraint(equalTo: playButton.leadingAnchor, constant: -20),
            shuffleButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            shuffleButton.widthAnchor.constraint(equalToConstant: 44),
            shuffleButton.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: shuffleButton.leadingAnchor, constant: -12),

            statsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            statsLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            statsLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            statsLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16)
        ])

        tableView.tableHeaderView = headerView
    }

    private func setupLongPress() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.3
        longPress.cancelsTouchesInView = false
        longPress.delegate = self
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

    private func applyFallbackInfo() {
        guard let fallbackPlaylist else { return }
        titleLabel.text = fallbackPlaylist.title
        statsLabel.text = "\(fallbackPlaylist.likesCount) Likes · \(fallbackPlaylist.tracksCount) Tracks"
        if let url = URL(string: fallbackPlaylist.cover) {
            loadCoverImage(from: url)
        }
    }

    private func fetchPlaylist() {
        guard !playlistPID.isEmpty else { return }
        activityIndicator.startAnimating()

        DataHelper.getSearchPlaylistData(pid: playlistPID) { [weak self] response in
            guard let self else { return }
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                guard let playlist = response?.playlist else { return }

                self.playlistInfo = playlist.info
                self.tracks = playlist.tracks
                self.titleLabel.text = playlist.info.title
                self.statsLabel.text = "\(playlist.info.likesCount) Likes · \(playlist.info.tracksCount) Tracks"

                if let url = URL(string: playlist.info.cover) {
                    self.loadCoverImage(from: url)
                }

                self.tableView.reloadData()
                self.resizeHeaderIfNeeded()
            }
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

    private func loadCoverImage(from url: URL) {
        let placeholder = UIImage(named: "Lav_Radio_Logo.png")
        coverImageView.af_setImage(
            withURL: url,
            placeholderImage: placeholder,
            filter: nil,
            imageTransition: .crossDissolve(0.25),
            completion: { [weak self] response in
                guard let self, let image = response.value else { return }
                self.updateHeaderGradient(from: image)
            }
        )
    }

    private func updateHeaderGradient(from image: UIImage) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let topColor = image.playlistGradientColor()
            DispatchQueue.main.async {
                self?.applyHeaderGradient(topColor: topColor, animated: true)
            }
        }
    }

    private func applyHeaderGradient(topColor: UIColor, animated: Bool) {
        let midColor = topColor.withBrightnessMultiplier(0.55)

        let apply = {
            self.headerGradientLayer.colors = [
                topColor.cgColor,
                topColor.cgColor,
                midColor.cgColor,
                UIColor.black.cgColor
            ]
            self.updateGradientLocations()
        }

        guard animated else {
            apply()
            return
        }

        CATransaction.begin()
        CATransaction.setAnimationDuration(0.35)
        apply()
        CATransaction.commit()
    }

    private func updateGradientFrames() {
        headerGradientLayer.frame = headerView.bounds
        updateGradientLocations()
    }

    private func updateGradientLocations() {
        guard headerGradientLayer.colors?.count == 4 else { return }

        let height = headerView.bounds.height
        guard height > 0 else { return }

        let safeRatio = min(view.safeAreaInsets.top / height, 0.18)
        let fadeStart = min(safeRatio + 0.05, 0.22)
        let fadeEnd = min(fadeStart + 0.4, 0.92)

        headerGradientLayer.locations = [
            0,
            NSNumber(value: Float(fadeStart)),
            NSNumber(value: Float(fadeEnd)),
            1
        ]
    }

    @objc private func popBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func playTapped() {
        guard !podcastTracks.isEmpty else { return }
        isShuffle = false
        openPlayer(at: 0)
    }

    @objc private func shuffleTapped() {
        guard !podcastTracks.isEmpty else { return }
        isShuffle = true
        let randomIndex = Int.random(in: 0..<podcastTracks.count)
        openPlayer(at: randomIndex)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }

        let point = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point),
              indexPath.row < tracks.count else { return }

        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()

        if let cell = tableView.cellForRow(at: indexPath) {
            cell.isUserInteractionEnabled = false
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                cell.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
            }) { _ in
                UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                    cell.transform = .identity
                    cell.isUserInteractionEnabled = true
                })
            }
        }

        presentOptions(for: tracks[indexPath.row])
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
}

// MARK: - UIGestureRecognizerDelegate

extension SearchPlaylistDetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}

// MARK: - UITableView

extension SearchPlaylistDetailViewController: UITableViewDelegate, UITableViewDataSource {
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
        isShuffle = false
        openPlayer(at: indexPath.row)
    }
}

