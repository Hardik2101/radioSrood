//
//  BrowseFeaturedPlaylistsShowAllViewController.swift
//  Radio Srood
//

import UIKit

final class BrowseFeaturedPlaylistsShowAllViewController: UI_VC {
    var playlists: [BrowseFeaturedPlaylist] = []

    private var collectionViewBottomConstraint: NSLayoutConstraint?

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

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Featured Playlists"
        label.font = UIFont(name: "Kohinoor Telugu Medium", size: 22) ?? .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 20
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 24, right: 16)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .black
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(SearchSubPlaylistCell.self, forCellWithReuseIdentifier: SearchSubPlaylistCell.reuseID)
        return collectionView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    override func fixMiniplayerSpace() {
        super.fixMiniplayerSpace()
        updateBottomInset()
    }

    private func setupUI() {
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(collectionView)

        let collectionBottom = collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        collectionViewBottomConstraint = collectionBottom

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),

            collectionView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionBottom
        ])
    }

    private func updateBottomInset() {
        let miniPlayerInset = TabbarVC.isMiniPlayerVisible ? 60.0 : 0.0
        collectionViewBottomConstraint?.constant = -miniPlayerInset
        collectionView.contentInset.bottom = miniPlayerInset
        view.layoutIfNeeded()
    }

    @objc private func popBack() {
        navigationController?.popViewController(animated: true)
    }
}

extension BrowseFeaturedPlaylistsShowAllViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        playlists.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SearchSubPlaylistCell.reuseID, for: indexPath) as! SearchSubPlaylistCell
        cell.configure(with: playlists[indexPath.item].toSearchSubPlaylist())
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let horizontalInset: CGFloat = 32
        let columnSpacing: CGFloat = 16
        let contentWidth = collectionView.bounds.width > 0 ? collectionView.bounds.width : view.bounds.width
        let itemWidth = floor((contentWidth - horizontalInset - columnSpacing) / 2)
        let textHeight: CGFloat = 48
        return CGSize(width: itemWidth, height: itemWidth + textHeight)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let playlist = playlists[indexPath.item]
        let detailVC = SearchPlaylistDetailViewController()
        detailVC.playlistPID = playlist.pid
        detailVC.fallbackPlaylist = playlist.toSearchSubPlaylist()
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
