//
//  SearchSubPlaylistCell.swift
//  Radio Srood
//

import UIKit

final class SearchSubPlaylistCell: UICollectionViewCell {
    static let reuseID = "SearchSubPlaylistCell"

    private let coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        imageView.backgroundColor = UIColor(white: 0.12, alpha: 1)
        return imageView
    }()

    private let statusIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "")
        imageView.tintColor = UIColor.white.withAlphaComponent(0.85)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor(white: 0.55, alpha: 1)
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

    override func prepareForReuse() {
        super.prepareForReuse()
        coverImageView.image = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
    }

    private func setupUI() {
        contentView.addSubview(coverImageView)
        coverImageView.addSubview(statusIconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            coverImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            coverImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            coverImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            coverImageView.heightAnchor.constraint(equalTo: coverImageView.widthAnchor),

            statusIconView.topAnchor.constraint(equalTo: coverImageView.topAnchor, constant: 10),
            statusIconView.trailingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: -10),
            statusIconView.widthAnchor.constraint(equalToConstant: 18),
            statusIconView.heightAnchor.constraint(equalToConstant: 18),

            titleLabel.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
        ])
    }

    func configure(with playlist: SearchSubPlaylist) {
        titleLabel.text = playlist.title

        if playlist.tracksCount > 0 {
            let songLabel = playlist.tracksCount == 1 ? "song" : "songs"
            subtitleLabel.text = "\(playlist.tracksCount) \(songLabel) · \(playlist.playCount) plays"
        } else {
            subtitleLabel.text = "\(playlist.likesCount) likes · \(playlist.playCount) plays"
        }

        if let url = URL(string: playlist.cover) {
            coverImageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
        } else {
            coverImageView.image = UIImage(named: "Lav_Radio_Logo.png")
        }
    }

}
