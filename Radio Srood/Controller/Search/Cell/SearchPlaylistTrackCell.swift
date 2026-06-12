//
//  SearchPlaylistTrackCell.swift
//  Radio Srood
//

import UIKit

final class SearchPlaylistTrackCell: UITableViewCell {
    static let reuseID = "SearchPlaylistTrackCell"

    private let coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 6
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .white
        return label
    }()

    private let artistLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor(white: 0.55, alpha: 1)
        return label
    }()

    private let moreIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "ellipsis")
        imageView.tintColor = UIColor(white: 0.55, alpha: 1)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
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
        artistLabel.text = nil
    }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(coverImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(artistLabel)
        contentView.addSubview(moreIconView)

        NSLayoutConstraint.activate([
            coverImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            coverImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            coverImageView.widthAnchor.constraint(equalToConstant: 52),
            coverImageView.heightAnchor.constraint(equalToConstant: 52),

            moreIconView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            moreIconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            moreIconView.widthAnchor.constraint(equalToConstant: 20),
            moreIconView.heightAnchor.constraint(equalToConstant: 20),

            titleLabel.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: moreIconView.leadingAnchor, constant: -12),
            titleLabel.topAnchor.constraint(equalTo: coverImageView.topAnchor, constant: 4),

            artistLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            artistLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4)
        ])
    }

    func configure(with track: Track) {
        titleLabel.text = track.track
        artistLabel.text = track.artist

        let coverURL = track.thumbnailArtCoverURL
        if let url = coverURL {
            coverImageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
        } else {
            coverImageView.image = UIImage(named: "Lav_Radio_Logo.png")
        }
    }
}
