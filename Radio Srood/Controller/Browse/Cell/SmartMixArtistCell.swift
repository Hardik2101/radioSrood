//
//  SmartMixArtistCell.swift
//  Radio Srood
//

import UIKit

final class SmartMixArtistCell: UICollectionViewCell {
    static let reuseID = "SmartMixArtistCell"
    static let nameAreaHeight: CGFloat = 44
    static let pickNameAreaHeight: CGFloat = 52

    private let imageContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0.12, alpha: 1)
        view.clipsToBounds = true
        view.layer.masksToBounds = true
        return view
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        return imageView
    }()

    private let selectionOverlay: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 0.78, green: 0.18, blue: 0.42, alpha: 0.55)
        view.isHidden = true
        view.clipsToBounds = true
        view.layer.masksToBounds = true
        view.isUserInteractionEnabled = false
        return view
    }()

    private let checkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        imageView.isHidden = true
        imageView.isUserInteractionEnabled = false
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)
        imageView.image = UIImage(systemName: "checkmark", withConfiguration: config)
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "Kohinoor Telugu Medium", size: 12)
            ?? .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    private let dariLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 11, weight: .regular)
        label.textColor = UIColor(white: 0.62, alpha: 1)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.isHidden = true
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
        refreshCircularAppearance()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.af_cancelImageRequest()
        imageView.image = nil
        nameLabel.text = nil
        dariLabel.text = nil
        setSelectedState(false)
    }

    private func setupUI() {
        contentView.clipsToBounds = false
        contentView.addSubview(imageContainer)
        imageContainer.addSubview(imageView)
        imageContainer.addSubview(selectionOverlay)
        imageContainer.addSubview(checkImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(dariLabel)

        NSLayoutConstraint.activate([
            imageContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageContainer.heightAnchor.constraint(equalTo: imageContainer.widthAnchor),

            imageView.topAnchor.constraint(equalTo: imageContainer.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),

            selectionOverlay.topAnchor.constraint(equalTo: imageContainer.topAnchor),
            selectionOverlay.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
            selectionOverlay.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            selectionOverlay.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),

            checkImageView.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            checkImageView.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),
            checkImageView.widthAnchor.constraint(equalToConstant: 30),
            checkImageView.heightAnchor.constraint(equalToConstant: 30),

            nameLabel.topAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: 6),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),

            dariLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 1),
            dariLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            dariLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            dariLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
        ])
    }

    /// Always re-apply circle clip. Call after selection changes / image loads.
    func refreshCircularAppearance() {
        imageContainer.layoutIfNeeded()
        let side = imageContainer.bounds.width
        guard side > 0.5 else { return }

        let radius = side * 0.5
        imageContainer.layer.cornerRadius = radius
        imageContainer.layer.masksToBounds = true
        imageContainer.clipsToBounds = true

        imageView.layer.cornerRadius = radius
        imageView.layer.masksToBounds = true
        imageView.clipsToBounds = true

        selectionOverlay.layer.cornerRadius = radius
        selectionOverlay.layer.masksToBounds = true
        selectionOverlay.clipsToBounds = true

        // Keep mask in sync with current size (replace any stale zero-size mask).
        let maskLayer: CAShapeLayer
        if let existing = imageContainer.layer.mask as? CAShapeLayer {
            maskLayer = existing
        } else {
            maskLayer = CAShapeLayer()
            imageContainer.layer.mask = maskLayer
        }
        maskLayer.frame = imageContainer.bounds
        maskLayer.path = UIBezierPath(ovalIn: imageContainer.bounds).cgPath
    }

    func configure(with artist: ArtistProfileSummary, isSelected: Bool, showsDariName: Bool = false) {
        nameLabel.text = artist.artist
        dariLabel.text = artist.artistDari
        dariLabel.isHidden = !showsDariName || (artist.artistDari?.isEmpty ?? true)
        nameLabel.numberOfLines = showsDariName ? 1 : 2
        setSelectedState(isSelected)
        loadPhoto(from: artist.artistPhoto)
        setNeedsLayout()
        layoutIfNeeded()
        refreshCircularAppearance()
    }

    func setSelectedState(_ selected: Bool) {
        selectionOverlay.isHidden = !selected
        checkImageView.isHidden = !selected
        // Selection overlay show/hide must not drop the circle.
        refreshCircularAppearance()
    }

    private func loadPhoto(from urlString: String) {
        let placeholder = UIImage(named: "Lav_Radio_Logo.png")
        guard let url = URL(string: urlString) else {
            imageView.image = placeholder
            refreshCircularAppearance()
            return
        }

        imageView.af_setImage(
            withURL: url,
            placeholderImage: placeholder,
            imageTransition: .crossDissolve(0.2),
            completion: { [weak self] _ in
                self?.refreshCircularAppearance()
            }
        )
    }
}
