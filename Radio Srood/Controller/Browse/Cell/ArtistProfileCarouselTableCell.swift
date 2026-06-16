//
//  ArtistProfileCarouselTableCell.swift
//  Radio Srood
//

import UIKit

protocol ArtistProfileCarouselTableCellDelegate: AnyObject {
    func carouselCell(_ cell: ArtistProfileCarouselTableCell, didSelect artist: SimilarArtist)
}

final class ArtistProfileCarouselTableCell: UITableViewCell {
    static let reuseID = "ArtistProfileCarouselTableCell"

    private static let browseCollectionHeight: CGFloat = 250

    private let itemSpacing: CGFloat = 6
    private let horizontalInset: CGFloat = 10

    weak var delegate: ArtistProfileCarouselTableCellDelegate?
    private var artists: [SimilarArtist] = []

    private(set) lazy var carouselCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = itemSpacing
        layout.minimumInteritemSpacing = itemSpacing
        layout.sectionInset = UIEdgeInsets(top: 4, left: horizontalInset, bottom: 4, right: horizontalInset)
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.clipsToBounds = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(
            ArtistProfileHorizontalCardCell.self,
            forCellWithReuseIdentifier: ArtistProfileHorizontalCardCell.reuseID
        )
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
        backgroundColor = .black
        contentView.backgroundColor = .black
        contentView.addSubview(carouselCollectionView)

        collectionHeightConstraint = carouselCollectionView.heightAnchor.constraint(equalToConstant: Self.browseCollectionHeight)

        NSLayoutConstraint.activate([
            carouselCollectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            carouselCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            carouselCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            carouselCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            collectionHeightConstraint
        ])
    }

    func configure(with artists: [SimilarArtist]) {
        self.artists = artists
        carouselCollectionView.reloadData()
    }

    static func rowHeight(for width: CGFloat) -> CGFloat {
        browseCollectionHeight + 12
    }
}

extension ArtistProfileCarouselTableCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        artists.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ArtistProfileHorizontalCardCell.reuseID,
            for: indexPath
        ) as! ArtistProfileHorizontalCardCell
        cell.configure(with: artists[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.carouselCell(self, didSelect: artists[indexPath.item])
    }
}
