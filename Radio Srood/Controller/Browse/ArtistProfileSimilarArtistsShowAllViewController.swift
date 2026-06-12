//
//  ArtistProfileSimilarArtistsShowAllViewController.swift
//  Radio Srood
//

import UIKit

final class ArtistProfileSimilarArtistsShowAllViewController: UI_VC {
    var artists: [SimilarArtist] = []

    private let columns: CGFloat = 3
    private let columnSpacing: CGFloat = 6
    private let lineSpacing: CGFloat = 10
    private let horizontalInset: CGFloat = 14

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
        label.text = "Srood Artists"
        label.font = UIFont(name: "Kohinoor Telugu Medium", size: 22) ?? .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = columnSpacing
        layout.minimumLineSpacing = lineSpacing
        layout.sectionInset = UIEdgeInsets(top: 8, left: horizontalInset, bottom: 20, right: horizontalInset)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .black
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ArtistProfileGridCell.self, forCellWithReuseIdentifier: ArtistProfileGridCell.reuseID)
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
            navigationController?.setNavigationBarHidden(true, animated: animated)
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
        view.addSubview(collectionView)
        view.addSubview(backButton)
        view.addSubview(titleLabel)

        let collectionBottom = collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        collectionViewBottomConstraint = collectionBottom

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -64),

            collectionView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 12),
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

extension ArtistProfileSimilarArtistsShowAllViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        artists.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ArtistProfileGridCell.reuseID,
            for: indexPath
        ) as! ArtistProfileGridCell
        cell.configure(with: artists[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalSpacing = (horizontalInset * 2) + (columnSpacing * (columns - 1))
        let width = floor((collectionView.bounds.width - totalSpacing) / columns)
        let imageHeight = width
        return CGSize(width: width, height: imageHeight + ArtistProfileGridCell.nameAreaHeight)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        openArtistProfile(artists[indexPath.item])
    }
}
