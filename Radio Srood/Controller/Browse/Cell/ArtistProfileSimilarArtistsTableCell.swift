//
//  ArtistProfileSimilarArtistsTableCell.swift
//  Radio Srood
//

import UIKit

protocol ArtistProfileSimilarArtistsTableCellDelegate: AnyObject {
    func similarArtistsCell(_ cell: ArtistProfileSimilarArtistsTableCell, didSelect artist: SimilarArtist)
}

final class ArtistProfileSimilarArtistsTableCell: UITableViewCell {
    static let reuseID = "ArtistProfileSimilarArtistsTableCell"
    static let rowHeight: CGFloat = ArtistProfileSroodArtistCell.itemHeight + 16

    private let itemWidth: CGFloat = 108
    private let itemSpacing: CGFloat = 12
    private let horizontalInset: CGFloat = 15

    weak var delegate: ArtistProfileSimilarArtistsTableCellDelegate?

    private var artists: [SimilarArtist] = []

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = itemSpacing
        layout.minimumInteritemSpacing = itemSpacing
        layout.sectionInset = UIEdgeInsets(top: 0, left: horizontalInset, bottom: 0, right: horizontalInset)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.clipsToBounds = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(
            ArtistProfileSroodArtistCell.self,
            forCellWithReuseIdentifier: ArtistProfileSroodArtistCell.reuseID
        )
        return collectionView
    }()

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
        backgroundColor = .black
        contentView.backgroundColor = .black
        contentView.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            collectionView.heightAnchor.constraint(equalToConstant: Self.rowHeight - 12)
        ])
    }

    func configure(with artists: [SimilarArtist]) {
        self.artists = artists
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
    }
}

extension ArtistProfileSimilarArtistsTableCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        artists.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ArtistProfileSroodArtistCell.reuseID,
            for: indexPath
        ) as! ArtistProfileSroodArtistCell
        cell.configure(with: artists[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: itemWidth, height: ArtistProfileSroodArtistCell.itemHeight)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.similarArtistsCell(self, didSelect: artists[indexPath.item])
    }
}
