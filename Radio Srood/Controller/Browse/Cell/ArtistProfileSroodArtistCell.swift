//
//  ArtistProfileSroodArtistCell.swift
//  Radio Srood
//

import UIKit

final class ArtistProfileSroodArtistCell: UICollectionViewCell {
    static let reuseID = "ArtistProfileSroodArtistCell"
    static let imageDiameter: CGFloat = 100
    static let nameAreaHeight: CGFloat = 32

    static var itemHeight: CGFloat {
        imageDiameter + nameAreaHeight + 6
    }

    private let imageContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0.12, alpha: 1)
        view.clipsToBounds = true
        return view
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "Kohinoor Telugu Medium", size: 11) ?? .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.92)
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let radius = Self.imageDiameter / 2
        imageContainer.layer.cornerRadius = radius
        imageView.layer.cornerRadius = radius
        imageContainer.layer.masksToBounds = true
        imageView.layer.masksToBounds = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        nameLabel.text = nil
    }

    private func setupUI() {
        contentView.addSubview(imageContainer)
        imageContainer.addSubview(imageView)
        contentView.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            imageContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageContainer.widthAnchor.constraint(equalToConstant: Self.imageDiameter),
            imageContainer.heightAnchor.constraint(equalToConstant: Self.imageDiameter),

            imageView.topAnchor.constraint(equalTo: imageContainer.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),

            nameLabel.topAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: 6),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
        ])
    }

    func configure(with artist: SimilarArtist) {
        nameLabel.text = artist.artist
        if let url = URL(string: artist.artistPhoto) {
            imageView.af_setImage(
                withURL: url,
                placeholderImage: UIImage(named: "Lav_Radio_Logo.png")
            )
        } else {
            imageView.image = UIImage(named: "Lav_Radio_Logo.png")
        }
        setNeedsLayout()
    }
}
