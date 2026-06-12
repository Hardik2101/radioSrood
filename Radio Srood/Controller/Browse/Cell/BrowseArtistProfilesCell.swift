//
//  BrowseArtistProfilesCell.swift
//  Radio Srood
//

import UIKit

final class BrowseArtistProfilesCell: UITableViewCell {
    static let reuseID = "BrowseArtistProfilesCell"

    weak var presentViewBrowse: BrowseTabVC?

    private let columns = 3
    private let previewCount = 15
    private let columnSpacing: CGFloat = 6
    private let lineSpacing: CGFloat = 10
    private let horizontalInset: CGFloat = 14

    var artists: [ArtistProfileSummary] = [] {
        didSet { collectionView.reloadData() }
    }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = columnSpacing
        layout.minimumLineSpacing = lineSpacing
        layout.sectionInset = UIEdgeInsets(top: 6, left: horizontalInset, bottom: 6, right: horizontalInset)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ArtistProfileGridCell.self, forCellWithReuseIdentifier: ArtistProfileGridCell.reuseID)
        return collectionView
    }()

    private var collectionHeightConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(collectionView)
        collectionHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 520)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            collectionHeightConstraint
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
        updateCollectionHeight()
    }

    func reloadCollectionView() {
        collectionView.reloadData()
        setNeedsLayout()
    }

    private var previewArtists: [ArtistProfileSummary] {
        Array(artists.prefix(previewCount))
    }

    private func itemWidth(for width: CGFloat) -> CGFloat {
        let totalInset = horizontalInset * 2
        let totalSpacing = columnSpacing * CGFloat(columns - 1)
        return floor((width - totalInset - totalSpacing) / CGFloat(columns))
    }

    private func updateCollectionHeight() {
        let rows = ceil(Double(previewArtists.count) / Double(columns))
        guard rows > 0 else {
            collectionHeightConstraint.constant = 0
            return
        }

        let width = collectionView.bounds.width > 0 ? collectionView.bounds.width : UIScreen.main.bounds.width
        let imageSize = itemWidth(for: width)
        let itemHeight = imageSize + 30
        let sectionInset: CGFloat = 12
        let height = sectionInset + (CGFloat(rows) * itemHeight) + (CGFloat(rows - 1) * lineSpacing)
        collectionHeightConstraint.constant = max(height, 0)
    }
}

extension BrowseArtistProfilesCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        previewArtists.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ArtistProfileGridCell.reuseID, for: indexPath) as! ArtistProfileGridCell
        cell.configure(with: previewArtists[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width > 0 ? collectionView.bounds.width : UIScreen.main.bounds.width
        let imageSize = itemWidth(for: width)
        return CGSize(width: imageSize, height: imageSize + 30)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let artist = previewArtists[indexPath.item]
        presentViewBrowse?.openArtistProfile(artistID: artist.artistid, summary: artist)
    }
}
