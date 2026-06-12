//
//  ArtistProfileGridCell.swift
//  Radio Srood
//

import UIKit

final class ArtistProfileGridCell: UICollectionViewCell {
    static let reuseID = "ArtistProfileGridCell"
    static let imageCornerRadius: CGFloat = 4
    static let nameFontSize: CGFloat = 14
    static let nameAreaHeight: CGFloat = 36

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
        imageView.backgroundColor = .clear
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "Kohinoor Telugu Medium", size: ArtistProfileGridCell.nameFontSize)
            ?? .systemFont(ofSize: ArtistProfileGridCell.nameFontSize, weight: .medium)
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
        imageContainer.layer.cornerRadius = Self.imageCornerRadius
        imageView.layer.cornerRadius = Self.imageCornerRadius
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
            imageContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageContainer.heightAnchor.constraint(equalTo: imageContainer.widthAnchor),

            imageView.topAnchor.constraint(equalTo: imageContainer.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),

            nameLabel.topAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: 5),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 1),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -1),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
        ])
    }

    func configure(with artist: ArtistProfileSummary) {
        nameLabel.text = artist.artist
        loadPhoto(from: artist.artistPhoto)
    }

    func configure(with artist: SimilarArtist) {
        nameLabel.text = artist.artist
        loadPhoto(from: artist.artistPhoto)
    }

    private func loadPhoto(from urlString: String) {
        if let url = URL(string: urlString) {
            imageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
        } else {
            imageView.image = UIImage(named: "Lav_Radio_Logo.png")
        }
    }
}
