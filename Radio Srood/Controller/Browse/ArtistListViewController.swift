//
//  ArtistListViewController.swift
//  Radio Srood
//

import UIKit

final class ArtistListViewController: UI_VC {
    var allArtists: [ArtistProfileSummary] = []

    private let pageSize = 30
    private var visibleCount = 30
    private var isLoadingMore = false

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
        label.text = "Popular Artists"
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
        visibleCount = min(pageSize, allArtists.count)
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

    private var displayedArtists: [ArtistProfileSummary] {
        Array(allArtists.prefix(visibleCount))
    }

    private var hasMoreArtists: Bool {
        visibleCount < allArtists.count
    }

    private func itemWidth(for width: CGFloat) -> CGFloat {
        let totalInset = horizontalInset * 2
        let totalSpacing = columnSpacing * (columns - 1)
        return floor((width - totalInset - totalSpacing) / columns)
    }

    private func loadMoreIfNeeded() {
        guard hasMoreArtists, !isLoadingMore else { return }
        isLoadingMore = true
        visibleCount = min(visibleCount + pageSize, allArtists.count)
        collectionView.reloadData()
        isLoadingMore = false
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

extension ArtistListViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        displayedArtists.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ArtistProfileGridCell.reuseID, for: indexPath) as! ArtistProfileGridCell
        cell.configure(with: displayedArtists[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width > 0 ? collectionView.bounds.width : view.bounds.width
        let imageSize = itemWidth(for: width)
        return CGSize(width: imageSize, height: imageSize + ArtistProfileGridCell.nameAreaHeight)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let threshold = max(displayedArtists.count - 6, 0)
        if indexPath.item >= threshold {
            loadMoreIfNeeded()
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.height
        if offsetY > contentHeight - frameHeight - 120 {
            loadMoreIfNeeded()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let artist = displayedArtists[indexPath.item]
        let profileVC = ArtistProfileViewController()
        profileVC.artistID = artist.artistid
        profileVC.fallbackSummary = artist
        navigationController?.pushViewController(profileVC, animated: true)
    }
}
