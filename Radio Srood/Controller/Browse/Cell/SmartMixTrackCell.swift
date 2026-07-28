//
//  SmartMixTrackCell.swift
//  Radio Srood
//

import UIKit

protocol SmartMixTrackCellDelegate: AnyObject {
    func smartMixTrackCellDidTapDownload(_ cell: SmartMixTrackCell)
}

final class SmartMixTrackCell: UITableViewCell {
    static let reuseID = "SmartMixTrackCell"

    weak var delegate: SmartMixTrackCellDelegate?

    private let coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 6
        imageView.backgroundColor = UIColor(white: 0.15, alpha: 1)
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .white
        label.numberOfLines = 1
        return label
    }()

    private let artistLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor(white: 0.65, alpha: 1)
        label.numberOfLines = 1
        return label
    }()

    private lazy var downloadButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = UIColor(white: 0.75, alpha: 1)
        button.setImage(UIImage(named: "ic_download")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        button.addTarget(self, action: #selector(downloadTapped), for: .touchUpInside)
        return button
    }()

    private let reorderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor(white: 0.55, alpha: 1)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        imageView.image = UIImage(systemName: "line.horizontal.3", withConfiguration: config)?
            .withRenderingMode(.alwaysTemplate)
        imageView.isUserInteractionEnabled = false
        return imageView
    }()

    private let textStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .fill
        return stack
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
        coverImageView.af_cancelImageRequest()
        coverImageView.image = nil
        delegate = nil
        downloadButton.isUserInteractionEnabled = true
    }

    private func setupUI() {
        backgroundColor = .black
        contentView.backgroundColor = .black
        selectionStyle = .none

        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(artistLabel)

        contentView.addSubview(coverImageView)
        contentView.addSubview(textStack)
        contentView.addSubview(downloadButton)
        contentView.addSubview(reorderImageView)

        NSLayoutConstraint.activate([
            coverImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            coverImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            coverImageView.widthAnchor.constraint(equalToConstant: 56),
            coverImageView.heightAnchor.constraint(equalToConstant: 56),

            textStack.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.trailingAnchor.constraint(equalTo: downloadButton.leadingAnchor, constant: -8),

            downloadButton.trailingAnchor.constraint(equalTo: reorderImageView.leadingAnchor, constant: -4),
            downloadButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            downloadButton.widthAnchor.constraint(equalToConstant: 36),
            downloadButton.heightAnchor.constraint(equalToConstant: 36),

            reorderImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            reorderImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            reorderImageView.widthAnchor.constraint(equalToConstant: 22),
            reorderImageView.heightAnchor.constraint(equalToConstant: 22)
        ])
    }

    func configure(with track: Track, isDownloaded: Bool, isDownloading: Bool) {
        titleLabel.text = track.track
        artistLabel.text = track.artist

        let coverURL = track.thumbnailArtCoverURL?.absoluteString
            ?? track.artcover_200
            ?? track.artcover
            ?? ""
        if let url = URL(string: coverURL), !coverURL.isEmpty {
            coverImageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
        } else {
            coverImageView.image = UIImage(named: "Lav_Radio_Logo.png")
        }

        applyDownloadAppearance(isDownloaded: isDownloaded, isDownloading: isDownloading)
    }

    func applyDownloadAppearance(isDownloaded: Bool, isDownloading: Bool) {
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        if isDownloaded {
            downloadButton.setImage(
                UIImage(systemName: "checkmark.circle.fill", withConfiguration: config),
                for: .normal
            )
            downloadButton.tintColor = .systemGreen
            downloadButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
            downloadButton.isUserInteractionEnabled = false
        } else if isDownloading {
            downloadButton.setImage(
                UIImage(named: "ic_download")?.withRenderingMode(.alwaysTemplate),
                for: .normal
            )
            downloadButton.tintColor = UIColor(white: 0.4, alpha: 1)
            downloadButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            downloadButton.isUserInteractionEnabled = false
        } else {
            downloadButton.setImage(
                UIImage(named: "ic_download")?.withRenderingMode(.alwaysTemplate),
                for: .normal
            )
            downloadButton.tintColor = UIColor(white: 0.75, alpha: 1)
            downloadButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            downloadButton.isUserInteractionEnabled = true
        }
    }

    @objc private func downloadTapped() {
        delegate?.smartMixTrackCellDidTapDownload(self)
    }
}
