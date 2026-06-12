//
//  ArtistProfileViewController.swift
//  Radio Srood
//

import UIKit

final class ArtistProfileViewController: UI_VC, OptionsViewControllerDelegate {
    var artistID: String = ""
    var fallbackSummary: ArtistProfileSummary?

    private var tracks: [Track] = []
    private var profileData: ArtistProfileData?

    private var tableBottomConstraint: NSLayoutConstraint?
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .black
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.delegate = self
        table.dataSource = self
        table.rowHeight = 88
        table.register(UINib(nibName: "SearchSongCell", bundle: nil), forCellReuseIdentifier: "SearchSongCell")
        return table
    }()

    private lazy var headerView: UIView = {
        UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 320))
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
        imageView.layer.cornerRadius = 70
        imageView.backgroundColor = UIColor(white: 0.12, alpha: 1)
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 26, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    private let statsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor(white: 0.55, alpha: 1)
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    private let sectionTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Top Tracks"
        label.font = UIFont(name: "Kohinoor Telugu Medium", size: 18) ?? .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .white.withAlphaComponent(0.85)
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        applyFallbackSummary()
        setupUI()
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
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }

    override func fixMiniplayerSpace() {
        super.fixMiniplayerSpace()
        updateBottomInset()
    }

    func didUpdateTrackMetadata() {
        tableView.reloadData()
    }

    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(backButton)
        view.addSubview(activityIndicator)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = .white

        headerView.addSubview(coverImageView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(statsLabel)
        headerView.addSubview(sectionTitleLabel)

        NSLayoutConstraint.activate([
            coverImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 12),
            coverImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            coverImageView.widthAnchor.constraint(equalToConstant: 140),
            coverImageView.heightAnchor.constraint(equalToConstant: 140),

            titleLabel.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),

            statsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            statsLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            statsLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),

            sectionTitleLabel.topAnchor.constraint(equalTo: statsLabel.bottomAnchor, constant: 20),
            sectionTitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 15),
            sectionTitleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
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
    }

    private func applyFallbackSummary() {
        guard let fallbackSummary else { return }
        titleLabel.text = fallbackSummary.artist
        if let playcounts = fallbackSummary.playcountsTotal {
            statsLabel.text = "\(playcounts) Plays"
        }
        if let url = URL(string: fallbackSummary.artistPhoto) {
            coverImageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
        }
    }

    private func fetchArtistProfile() {
        guard !artistID.isEmpty else { return }
        activityIndicator.startAnimating()

        DataHelper.getArtistProfile(artistID: artistID) { [weak self] response in
            guard let self else { return }
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                guard let detail = response?.detail else { return }

                self.profileData = detail.artistProfileData
                self.titleLabel.text = detail.artistProfileData.artist

                let plays = detail.artistProfileData.playcountsTotal ?? ""
                let tracksTotal = detail.artistProfileData.tracksTotal ?? ""
                let likes = detail.artistProfileData.likesTotal ?? ""
                self.statsLabel.text = [plays.isEmpty ? nil : "\(plays) Plays",
                                        tracksTotal.isEmpty ? nil : "\(tracksTotal) Tracks",
                                        likes.isEmpty ? nil : "\(likes) Likes"]
                    .compactMap { $0 }
                    .joined(separator: " · ")

                let photoURL = detail.artistProfileData.artistPhoto700
                    ?? detail.artistProfileData.artistPhoto
                    ?? detail.artistProfileData.artistPhoto200
                if let photoURL, let url = URL(string: photoURL) {
                    self.coverImageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                }

                var mergedTracks = detail.artistTopTracks ?? []
                if let latest = detail.artistLatestTrack,
                   !mergedTracks.contains(where: { $0.trackid == latest.trackid }) {
                    mergedTracks.insert(latest, at: 0)
                }
                self.tracks = mergedTracks
                self.tableView.reloadData()
            }
        }
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

    private var podcastTracks: [PodcastObject] {
        tracks.map { $0.convertToPodcastModel() }
    }
}

extension ArtistProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tracks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchSongCell", for: indexPath) as! SearchSongCell
        cell.selectionStyle = .none
        let track = tracks[indexPath.row]
        if let url = URL(string: track.artcover_200 ?? track.artcover ?? "") {
            cell.imgArtist.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            cell.imgBg.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
        }
        cell.lblArtistName.text = track.artist
        cell.lblSongName.text = track.track
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "MyMusicPlayerViewController") as! MyMusicPlayerViewController
        vc.selectedIndex = indexPath.row
        vc.tempTrack = podcastTracks
        vc.track = podcastTracks
        vc.isShowOptionList = true
        navigationController?.pushViewController(vc, animated: true)
    }
}
