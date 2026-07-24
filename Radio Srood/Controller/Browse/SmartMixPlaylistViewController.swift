//
//  SmartMixPlaylistViewController.swift
//  Radio Srood
//

import UIKit

final class SmartMixPlaylistViewController: UI_VC, OptionsViewControllerDelegate {
    var playlist: SmartMixPlaylist!
    /// Full artist catalog used by Add Songs (not only selected mix artists).
    var allArtists: [ArtistProfileSummary] = []

    private var tracks: [Track] = []
    private var isShuffle = false
    private var tableBottomConstraint: NSLayoutConstraint?
    private var headerTopSpacerHeightConstraint: NSLayoutConstraint?

    private let headerGradientLayer = CAGradientLayer()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

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
            makeCircleAction(systemName: "arrow.down.to.line", action: #selector(downloadTapped), size: 44),
            makeCircleAction(systemName: "bookmark", action: #selector(bookmarkTapped), size: 44),
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
        setupLongPress()
        configureHeaderContent()
        loadCollage()
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
        let alert = UIAlertController(title: "Download", message: "Downloading mix tracks is available from each song’s options menu.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func bookmarkTapped() {
        let alert = UIAlertController(title: "Saved", message: "Your Smart Mix is ready to play. Bookmark individual songs from the options menu.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
            guard let self, let text = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
            self.playlist.title = text
            self.titleLabel.text = text
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
        refreshStats()
    }
}
