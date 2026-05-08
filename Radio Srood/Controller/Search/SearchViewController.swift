//
//  SearchViewController.swift
//  Radio Srood
//
//  Created by Hardik on 08/05/26.
//  Copyright © 2026 Radio Srood Inc. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
    @IBOutlet private weak var tfSearch: UITextField!
    @IBOutlet private weak var tblSearch: UITableView!

    private enum SearchSection: Int, CaseIterable {
        case popularPlaylist
        case moodsAndGenres
        case popularArtist

        var title: String {
            switch self {
            case .popularPlaylist:
                return "POPULAR PLAYLIST"
            case .moodsAndGenres:
                return "Moods & Genres"
            case .popularArtist:
                return "POPULAR ARTIST"
            }
        }
    }

    private let popularPlaylistItems = [
        "Romance", "J-Rap", "Hip Hop",
        "Sleep", "Pop", "Breakup",
        "Turkish hip-hop", "1980s", "Farsi"
    ]

    private let moodItems = [
        "ARABIC HIP HOP", "ARABIC INDIE",
        "CHILLING", "DECADES",
        "TOP", "PODCASTS",
        "ARABIC HIP HOP", "ARABIC INDIE",
        "CHILLING", "DECADES"
    ]

    private let popularArtists = [
        "Jawid Sharif", "Habib Qaderi", "Aria Band",
        "Jawid Sharif", "Habib Qaderi", "Aria Band",
        "Jawid Sharif", "Habib Qaderi", "Aria Band"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        prepareView()
    }
}

private extension SearchViewController {
    func prepareView() {
        view.backgroundColor = UIColor(red: 0.09, green: 0.09, blue: 0.09, alpha: 1.0)
        navigationController?.navigationBar.topItem?.title = "SEARCH & DISCOVER"
        title = "SEARCH & DISCOVER"

        tfSearch.attributedPlaceholder = NSAttributedString(
            string: "Songs, artists, lyrics, playlists...",
            attributes: [.foregroundColor: UIColor(white: 0.55, alpha: 1.0)]
        )
        tfSearch.backgroundColor = UIColor(white: 0.86, alpha: 1.0)
        tfSearch.layer.cornerRadius = 6
        tfSearch.clipsToBounds = true
        tfSearch.textColor = .black
        tfSearch.leftView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        tfSearch.leftView?.tintColor = UIColor(white: 0.45, alpha: 1.0)
        tfSearch.leftViewMode = .always

        tblSearch.delegate = self
        tblSearch.dataSource = self
        tblSearch.backgroundColor = .clear
        tblSearch.separatorStyle = .none
        tblSearch.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)

        tblSearch.register(UINib(nibName: "PopularPlaylistTableViewCell", bundle: nil), forCellReuseIdentifier: PopularPlaylistTableViewCell.reuseID)
        tblSearch.register(SearchMoodTableViewCell.self, forCellReuseIdentifier: SearchMoodTableViewCell.reuseID)
        tblSearch.register(SearchArtistsTableViewCell.self, forCellReuseIdentifier: SearchArtistsTableViewCell.reuseID)
    }
}

extension SearchViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        SearchSection.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = SearchSection(rawValue: indexPath.section) else { return UITableView.automaticDimension }
        switch section {
        case .popularPlaylist:
            return 132
        case .moodsAndGenres:
            return 420
        case .popularArtist:
            return 320
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        34
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionType = SearchSection(rawValue: section) else { return nil }
        let container = UIView()
        container.backgroundColor = .clear

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = sectionType.title
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.textColor = .white

        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])

        return container
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = SearchSection(rawValue: indexPath.section) else { return UITableViewCell() }
        switch section {
        case .popularPlaylist:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PopularPlaylistTableViewCell.reuseID, for: indexPath) as? PopularPlaylistTableViewCell else {
                return UITableViewCell()
            }
            cell.configure(items: popularPlaylistItems)
            return cell
        case .moodsAndGenres:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchMoodTableViewCell.reuseID, for: indexPath) as? SearchMoodTableViewCell else {
                return UITableViewCell()
            }
            cell.configure(items: moodItems)
            return cell
        case .popularArtist:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchArtistsTableViewCell.reuseID, for: indexPath) as? SearchArtistsTableViewCell else {
                return UITableViewCell()
            }
            cell.configure(items: popularArtists)
            return cell
        }
    }
}

final class PopularPlaylistTableViewCell: UITableViewCell {
    static let reuseID = "PopularPlaylistTableViewCell"

    @IBOutlet private weak var collectionView: UICollectionView!

    private var items: [String] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        setupCollectionView()
    }

    func configure(items: [String]) {
        self.items = items
        collectionView.reloadData()
    }

    private func setupCollectionView() {
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 8
            layout.minimumInteritemSpacing = 8
            layout.sectionInset = .zero
        }
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "PopularPlaylistChipCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: PopularPlaylistChipCollectionViewCell.reuseID)
    }
}

extension PopularPlaylistTableViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PopularPlaylistChipCollectionViewCell.reuseID, for: indexPath) as? PopularPlaylistChipCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.configure(title: items[indexPath.row], index: indexPath.row)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 132, height: 30)
    }
}

final class PopularPlaylistChipCollectionViewCell: UICollectionViewCell {
    static let reuseID = "PopularPlaylistChipCollectionViewCell"

    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var accentView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        containerView.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        containerView.layer.cornerRadius = 6
        containerView.clipsToBounds = true
        accentView.backgroundColor = UIColor(red: 0.98, green: 0.39, blue: 0.06, alpha: 1.0)
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
    }

    func configure(title: String, index: Int) {
        titleLabel.text = title
        accentView.backgroundColor = accentColor(for: index)
    }

    private func accentColor(for index: Int) -> UIColor {
        let colors: [UIColor] = [
            UIColor(red: 0.98, green: 0.39, blue: 0.06, alpha: 1.0), // orange
            UIColor(red: 0.16, green: 0.70, blue: 0.98, alpha: 1.0), // blue
            UIColor(red: 0.62, green: 0.34, blue: 0.98, alpha: 1.0), // purple
            UIColor(red: 0.15, green: 0.78, blue: 0.45, alpha: 1.0), // green
            UIColor(red: 0.98, green: 0.25, blue: 0.56, alpha: 1.0), // pink
            UIColor(red: 0.96, green: 0.78, blue: 0.16, alpha: 1.0)  // yellow
        ]
        return colors[index % colors.count]
    }
}

final class SearchMoodTableViewCell: UITableViewCell {
    static let reuseID = "SearchMoodTableViewCell"
    private var items: [String] = []
    private let colors: [UIColor] = [
        UIColor(red: 0.00, green: 0.80, blue: 0.44, alpha: 1),
        UIColor(red: 0.00, green: 0.73, blue: 0.95, alpha: 1),
        UIColor(red: 0.40, green: 0.48, blue: 0.96, alpha: 1),
        UIColor(red: 0.88, green: 0.28, blue: 0.95, alpha: 1),
        UIColor(red: 0.80, green: 0.30, blue: 0.64, alpha: 1)
    ]

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.backgroundColor = .clear
        return collection
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configure(items: [String]) {
        self.items = items
        collectionView.reloadData()
    }

    private func setup() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        collectionView.register(SearchMoodCollectionViewCell.self, forCellWithReuseIdentifier: SearchMoodCollectionViewCell.reuseID)
        collectionView.delegate = self
        collectionView.dataSource = self
    }
}

extension SearchMoodTableViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SearchMoodCollectionViewCell.reuseID, for: indexPath) as? SearchMoodCollectionViewCell else {
            return UICollectionViewCell()
        }
        let color = colors[indexPath.row % colors.count]
        cell.configure(title: items[indexPath.row], color: color)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 10) / 2
        return CGSize(width: width, height: 74)
    }
}

final class SearchMoodCollectionViewCell: UICollectionViewCell {
    static let reuseID = "SearchMoodCollectionViewCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configure(title: String, color: UIColor) {
        titleLabel.text = title
        contentView.backgroundColor = color
    }

    private func setup() {
        contentView.layer.cornerRadius = 6
        contentView.clipsToBounds = true
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}

final class SearchArtistsTableViewCell: UITableViewCell {
    static let reuseID = "SearchArtistsTableViewCell"
    private var items: [String] = []

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 8
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.backgroundColor = .clear
        return collection
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configure(items: [String]) {
        self.items = items
        collectionView.reloadData()
    }

    private func setup() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        collectionView.register(SearchArtistCollectionViewCell.self, forCellWithReuseIdentifier: SearchArtistCollectionViewCell.reuseID)
        collectionView.delegate = self
        collectionView.dataSource = self
    }
}

extension SearchArtistsTableViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SearchArtistCollectionViewCell.reuseID, for: indexPath) as? SearchArtistCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.configure(name: items[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 16) / 3
        return CGSize(width: width, height: 98)
    }
}

final class SearchArtistCollectionViewCell: UICollectionViewCell {
    static let reuseID = "SearchArtistCollectionViewCell"

    private let avatarView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        view.layer.cornerRadius = 30
        view.clipsToBounds = true
        return view
    }()

    private let initialsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        return label
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configure(name: String) {
        nameLabel.text = name
        initialsLabel.text = String(name.split(separator: " ").prefix(2).compactMap { $0.first })
    }

    private func setup() {
        contentView.addSubview(avatarView)
        avatarView.addSubview(initialsLabel)
        contentView.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor),
            avatarView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 60),
            avatarView.heightAnchor.constraint(equalToConstant: 60),

            initialsLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            nameLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 6),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4)
        ])
    }
}
