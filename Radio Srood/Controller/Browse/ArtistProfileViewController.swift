//
//  ArtistProfileViewController.swift
//  Radio Srood
//

import UIKit

final class ArtistProfileViewController: UI_VC, OptionsViewControllerDelegate {
    var artistID: String = ""
    var fallbackSummary: ArtistProfileSummary?

    private var profilePage: ArtistProfilePage?
    private var playbackTracks: [Track] = []
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
        let table = UITableView(frame: .zero, style: .grouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .black
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.delegate = self
        table.dataSource = self
        table.contentInsetAdjustmentBehavior = .never
        table.rowHeight = 88
        table.estimatedRowHeight = 88
        table.sectionHeaderHeight = UITableView.automaticDimension
        table.estimatedSectionHeaderHeight = 44
        table.sectionFooterHeight = UITableView.automaticDimension
        table.estimatedSectionFooterHeight = 52
        table.register(UINib(nibName: "SearchSongCell", bundle: nil), forCellReuseIdentifier: "SearchSongCell")
        if #available(iOS 15.0, *) {
            table.sectionHeaderTopPadding = 0
        }
        return table
    }()

    private lazy var headerView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 420))
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

    private let dariNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 26, weight: .semibold)
        label.textColor = UIColor(white: 0.72, alpha: 1)
        label.numberOfLines = 2
        label.isHidden = true
        return label
    }()

    private lazy var namesStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, dariNameLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        return stack
    }()

    private let statsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = UIColor(white: 0.55, alpha: 1)
        label.numberOfLines = 2
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
        applyFallbackSummary()
        setupUI()
        setupLongPress()
        fetchArtistProfile()
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

    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(backButton)
        view.addSubview(activityIndicator)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = .white

        headerView.addSubview(headerTopSpacer)
        headerView.addSubview(coverImageView)
        headerView.addSubview(shuffleButton)
        headerView.addSubview(playButton)
        headerView.addSubview(namesStackView)
        headerView.addSubview(statsLabel)

        let spacerHeight = headerTopSpacer.heightAnchor.constraint(equalToConstant: 0)
        headerTopSpacerHeightConstraint = spacerHeight

        let coverWidth = UIScreen.main.bounds.width - 32
        NSLayoutConstraint.activate([
            headerTopSpacer.topAnchor.constraint(equalTo: headerView.topAnchor),
            headerTopSpacer.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            headerTopSpacer.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            spacerHeight,

            coverImageView.topAnchor.constraint(equalTo: headerTopSpacer.bottomAnchor, constant: 8),
            coverImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            coverImageView.widthAnchor.constraint(equalToConstant: coverWidth),
            coverImageView.heightAnchor.constraint(equalTo: coverImageView.widthAnchor),

            playButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            playButton.centerYAnchor.constraint(equalTo: namesStackView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 56),
            playButton.heightAnchor.constraint(equalToConstant: 56),

            shuffleButton.trailingAnchor.constraint(equalTo: playButton.leadingAnchor, constant: -20),
            shuffleButton.centerYAnchor.constraint(equalTo: namesStackView.centerYAnchor),
            shuffleButton.widthAnchor.constraint(equalToConstant: 44),
            shuffleButton.heightAnchor.constraint(equalToConstant: 44),

            namesStackView.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: 20),
            namesStackView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            namesStackView.trailingAnchor.constraint(lessThanOrEqualTo: shuffleButton.leadingAnchor, constant: -12),

            statsLabel.topAnchor.constraint(equalTo: namesStackView.bottomAnchor, constant: 10),
            statsLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            statsLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            statsLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16)
        ])

        tableView.tableHeaderView = headerView

        let tableBottom = tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        tableBottomConstraint = tableBottom

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),

            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableBottom,

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        view.bringSubviewToFront(backButton)
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

    private func applyFallbackSummary() {
        guard let fallbackSummary else { return }
        applyArtistNames(english: fallbackSummary.artist, dari: fallbackSummary.artistDari)
        if let url = URL(string: fallbackSummary.artistPhoto) {
            loadCoverImage(from: url)
        }
    }

    private func fetchArtistProfile() {
        guard !artistID.isEmpty else { return }
        activityIndicator.startAnimating()

        DataHelper.getArtistProfilePage(artistID: artistID) { [weak self] page in
            guard let self else { return }
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                guard let page else { return }

                self.profilePage = page
                self.playbackTracks = page.playbackTracks
                self.applyProfileData(page.profileData)
                self.tableView.reloadData()
                self.resizeHeaderIfNeeded()
            }
        }
    }

    private func applyProfileData(_ data: ArtistProfileData) {
        applyArtistNames(english: data.artist, dari: data.artistDari)

        var statParts: [String] = []
        if let tracksTotal = data.tracksTotal, !tracksTotal.isEmpty {
            statParts.append("\(tracksTotal.uppercased()) Tracks")
        }
        if let likesTotal = data.likesTotal, !likesTotal.isEmpty {
            statParts.append("\(likesTotal.uppercased()) Likes")
        }
//        if let playcountsTotal = data.playcountsTotal, !playcountsTotal.isEmpty {
//            statParts.append("\(playcountsTotal.uppercased()) PLAYS")
//        }
        statsLabel.text = statParts.joined(separator: " • ")

        let photoURL = data.artistPhoto700 ?? data.artistPhoto ?? data.artistPhoto200
        if let photoURL, let url = URL(string: photoURL) {
            loadCoverImage(from: url)
        }

        resizeHeaderIfNeeded()
    }

    private func applyArtistNames(english: String, dari: String?) {
        titleLabel.text = english

        let trimmedDari = dari?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let shouldShowDari = !trimmedDari.isEmpty
            && trimmedDari.caseInsensitiveCompare(english) != .orderedSame

        if shouldShowDari {
            dariNameLabel.text = trimmedDari
            dariNameLabel.isHidden = false
        } else {
            dariNameLabel.text = nil
            dariNameLabel.isHidden = true
        }
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

    private func updateBottomInset() {
        let miniPlayerInset = TabbarVC.isMiniPlayerVisible ? 60.0 : 0.0
        tableBottomConstraint?.constant = -miniPlayerInset
        tableView.contentInset.bottom = miniPlayerInset
        view.layoutIfNeeded()
    }

    @objc private func popBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func playTapped() {
        guard !podcastTracks.isEmpty else { return }
        isShuffle = false
        openPlayer(at: 0, tracks: playbackTracks)
    }

    @objc private func shuffleTapped() {
        guard !podcastTracks.isEmpty else { return }
        isShuffle = true
        let randomIndex = Int.random(in: 0..<playbackTracks.count)
        openPlayer(at: randomIndex, tracks: playbackTracks)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }

        let touchPoint = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: touchPoint),
              let profileSection = profilePage?.sections[indexPath.section] else {
            return
        }

        switch profileSection.layout {
        case .carouselTracks:
            guard let browseCell = tableView.cellForRow(at: indexPath) as? BrowseTableCell,
                  let tracks = profileSection.tracks else { return }

            let collectionPoint = gesture.location(in: browseCell.playlistCollectionView)
            guard let collectionIndexPath = browseCell.playlistCollectionView.indexPathForItem(at: collectionPoint),
                  collectionIndexPath.item < tracks.count else { return }

            let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            feedbackGenerator.prepare()
            feedbackGenerator.impactOccurred()

            presentOptions(for: tracks[collectionIndexPath.item])

        case .latestRelease, .listTracks:
            guard let track = track(at: indexPath) else { return }
            presentOptions(for: track)

        case .similarArtists:
            break
        }
    }

    @objc private func moreTapped(_ sender: UIButton) {
        let sectionIndex = sender.tag
        guard let sections = profilePage?.sections, sectionIndex < sections.count else { return }
        let section = sections[sectionIndex]

        if let tracks = section.tracks {
            let vc = ArtistProfileSectionShowAllViewController()
            vc.sectionTitle = section.title
            vc.tracks = tracks
            navigationController?.pushViewController(vc, animated: true)
            return
        }

        if let artists = section.similarArtists {
            let vc = ArtistProfileSimilarArtistsShowAllViewController()
            vc.artists = artists
            navigationController?.pushViewController(vc, animated: true)
        }
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

    private var podcastTracks: [PodcastObject] {
        playbackTracks.map { $0.convertToPodcastModel() }
    }

    private func openPlayer(at index: Int, tracks: [Track]) {
        guard index >= 0, index < tracks.count else { return }
        let podcasts = tracks.map { $0.convertToPodcastModel() }
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "MyMusicPlayerViewController") as! MyMusicPlayerViewController
        vc.selectedIndex = index
        vc.tempTrack = podcasts
        vc.track = podcasts
        vc.isShuffle = isShuffle
        vc.isShowOptionList = true
        navigationController?.pushViewController(vc, animated: true)
    }

    private func track(at indexPath: IndexPath) -> Track? {
        guard let section = profilePage?.sections[indexPath.section] else { return nil }
        guard let tracks = section.tracks else { return nil }
        return tracks[indexPath.row]
    }

    private func tracks(for section: ArtistProfileSection) -> [Track] {
        let tracks = section.tracks ?? []
        switch section.layout {
        case .carouselTracks, .latestRelease:
            return tracks
        case .listTracks:
            return Array(tracks.prefix(ArtistProfilePage.listPreviewLimit))
        case .similarArtists:
            return []
        }
    }

    private func similarArtists(for section: ArtistProfileSection) -> [SimilarArtist] {
        let artists = section.similarArtists ?? []
        return Array(artists.prefix(ArtistProfilePage.similarArtistsLimit))
    }

    private func configure(cell: SearchSongCell, with track: Track) {
        let coverURL = track.thumbnailArtCoverURL?.absoluteString ?? track.artcover_200 ?? track.artcover ?? ""
        if let url = URL(string: coverURL) {
            cell.imgArtist.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            cell.imgBg.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
        }
        cell.lblSongName.text = track.track
        cell.lblArtistName.text = track.artist
    }

    private func makeSectionHeader(title: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .black

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        label.font = UIFont(name: "Kohinoor Telugu Medium", size: 18) ?? .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .white.withAlphaComponent(0.92)
        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 15),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -15),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6)
        ])

        return container
    }

    private func makeMoreFooter(sectionIndex: Int) -> UIView {
        let container = UIView()
        container.backgroundColor = .black

        let button = makeMoreButton(sectionIndex: sectionIndex)
        container.addSubview(button)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 15),
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -15),
            button.heightAnchor.constraint(equalToConstant: 42),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10)
        ])

        return container
    }

    private func makeMoreButton(sectionIndex: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("More", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = UIColor(white: 0.16, alpha: 1)
        button.layer.cornerRadius = 10
        button.tag = sectionIndex
        button.addTarget(self, action: #selector(moreTapped(_:)), for: .touchUpInside)
        return button
    }

    private func openArtistProfile(_ artist: SimilarArtist) {
        let vc = ArtistProfileViewController()
        vc.artistID = artist.artistProfileid
        vc.fallbackSummary = ArtistProfileSummary(
            artistid: artist.artistProfileid,
            artist: artist.artist,
            artistDari: artist.artistDari,
            playcountsTotal: nil,
            artistPhoto: artist.artistPhoto
        )
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension ArtistProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        profilePage?.sections.count ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let profileSection = profilePage?.sections[section] else { return 0 }
        switch profileSection.layout {
        case .carouselTracks, .similarArtists:
            return 1
        case .latestRelease, .listTracks:
            return tracks(for: profileSection).count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let profileSection = profilePage?.sections[indexPath.section] else {
            return UITableViewCell()
        }

        switch profileSection.layout {
        case .carouselTracks:
            guard let cell = tableView.registerAndGet(cell: BrowseTableCell.self) else {
                return UITableViewCell()
            }
            cell.applyCompactCarouselLayout(backgroundColor: .black)
            cell.presentView = nil
            cell.presentViewBrowse = nil
            cell.featuredBrowsePlaylists = []
            cell.playlist = []
            cell.newReleases = []
            cell.similarArtists = []
            cell.homeTrendingTracks = []
            cell.homePopularTracks = []
            cell.browseDelegate = self
            cell.artistProfileTracks = profileSection.tracks ?? []
            cell.reloadCollectionView()
            return cell

        case .similarArtists:
            guard let cell = tableView.registerAndGet(cell: BrowseTableCell.self) else {
                return UITableViewCell()
            }
            cell.applyArtistCarouselLayout(backgroundColor: .black)
            cell.presentView = nil
            cell.presentViewBrowse = nil
            cell.featuredBrowsePlaylists = []
            cell.playlist = []
            cell.newReleases = []
            cell.artistProfileTracks = []
            cell.homeTrendingTracks = []
            cell.homePopularTracks = []
            cell.browseDelegate = self
            cell.similarArtists = similarArtists(for: profileSection)
            cell.reloadCollectionView()
            return cell

        case .latestRelease, .listTracks:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SearchSongCell", for: indexPath) as! SearchSongCell
            cell.selectionStyle = .none
            if let track = tracks(for: profileSection)[safe: indexPath.row] {
                configure(cell: cell, with: track)
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let profileSection = profilePage?.sections[section] else { return nil }
        return makeSectionHeader(title: profileSection.title)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let profileSection = profilePage?.sections[section] else { return nil }
        guard profileSection.hasMoreItems else { return nil }
        return makeMoreFooter(sectionIndex: section)
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let profileSection = profilePage?.sections[section] else { return .leastNormalMagnitude }
        return profileSection.hasMoreItems ? UITableView.automaticDimension : .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let profileSection = profilePage?.sections[indexPath.section] else { return 88 }
        switch profileSection.layout {
        case .carouselTracks:
            return BrowseTableCell.Layout.homeTrackRowHeight
        case .similarArtists:
            return BrowseTableCell.Layout.homeArtistRowHeight
        case .latestRelease, .listTracks:
            return 88
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let profileSection = profilePage?.sections[indexPath.section],
              let tracks = profileSection.tracks else { return }
        guard profileSection.layout == .latestRelease || profileSection.layout == .listTracks else { return }
        isShuffle = false
        openPlayer(at: indexPath.row, tracks: tracks)
    }
}

extension ArtistProfileViewController: BrowseTableCellDelegate {
    func browseTableCell(_ cell: BrowseTableCell, didSelectTrackAt index: Int, tracks: [Track]) {
        isShuffle = false
        openPlayer(at: index, tracks: tracks)
    }

    func browseTableCell(_ cell: BrowseTableCell, didSelectSimilarArtistAt index: Int, artists: [SimilarArtist]) {
        guard index >= 0, index < artists.count else { return }
        openArtistProfile(artists[index])
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
