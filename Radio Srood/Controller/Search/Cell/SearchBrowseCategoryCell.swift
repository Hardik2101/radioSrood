//
//  SearchBrowseCategoryCell.swift
//  Radio Srood
//

import UIKit

final class SearchBrowseCategoryCell: UICollectionViewCell {
    static let reuseID = "SearchBrowseCategoryCell"

    /// Distinct hues only — avoids similar purples/pinks sitting next to each other in the palette.
    private static let cardPalette: [UIColor] = [
        UIColor(red: 0.92, green: 0.71, blue: 0.28, alpha: 1.0),  // yellow
        UIColor(red: 0.90, green: 0.22, blue: 0.22, alpha: 1.0),  // red
        UIColor(red: 0.30, green: 0.62, blue: 0.92, alpha: 1.0),  // blue
        UIColor(red: 0.20, green: 0.65, blue: 0.45, alpha: 1.0),  // green
        UIColor(red: 0.88, green: 0.20, blue: 0.55, alpha: 1.0),  // pink
        UIColor(red: 0.95, green: 0.45, blue: 0.18, alpha: 1.0),  // orange
        UIColor(red: 0.50, green: 0.28, blue: 0.78, alpha: 1.0),  // purple
        UIColor(red: 0.72, green: 0.68, blue: 0.28, alpha: 1.0),  // olive
        UIColor(red: 0.18, green: 0.55, blue: 0.62, alpha: 1.0),  // teal
        UIColor(red: 0.92, green: 0.35, blue: 0.32, alpha: 1.0)   // coral
    ]

    /// Maps grid position to palette slots so neighbours in a 2-column layout look different.
    private static let gridColorOrder = [0, 5, 2, 7, 4, 9, 1, 6, 3, 8]

    private let cardView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()

    private let coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 4
        imageView.transform = CGAffineTransform(rotationAngle: 0.35)
        return imageView
    }()

    private var skeletonTitleView: UIView?
    private var skeletonImageView: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        setupUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        coverImageView.af_cancelImageRequest()
        coverImageView.image = nil
        titleLabel.text = nil
        cardView.backgroundColor = nil
        hideSkeleton()
    }

    private func setupUI() {
        contentView.addSubview(cardView)
        cardView.addSubview(coverImageView)
        cardView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: cardView.trailingAnchor, constant: -56),

            coverImageView.widthAnchor.constraint(equalToConstant: 56),
            coverImageView.heightAnchor.constraint(equalToConstant: 56),
            coverImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: 8),
            coverImageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 8)
        ])
    }

    func configure(with category: SearchPlaylistCategory, index: Int) {
        hideSkeleton()
        titleLabel.isHidden = false
        coverImageView.isHidden = false
        titleLabel.text = category.title
        cardView.backgroundColor = Self.cardBackgroundColor(at: index)

        if let url = URL(string: category.categoryCover) {
            coverImageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
        } else {
            coverImageView.image = UIImage(named: "Lav_Radio_Logo.png")
        }
    }

    func showSkeleton() {
        hideSkeleton()
        titleLabel.isHidden = true
        coverImageView.isHidden = true
        cardView.backgroundColor = UIColor.white.withAlphaComponent(0.07)

        let titleSkeleton = ShimmerPlaceholderView(cornerRadius: 4)
        cardView.addSubview(titleSkeleton)
        NSLayoutConstraint.activate([
            titleSkeleton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            titleSkeleton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20),
            titleSkeleton.widthAnchor.constraint(equalToConstant: 72),
            titleSkeleton.heightAnchor.constraint(equalToConstant: 14)
        ])
        skeletonTitleView = titleSkeleton

        let imageSkeleton = ShimmerPlaceholderView(cornerRadius: 4)
        cardView.addSubview(imageSkeleton)
        NSLayoutConstraint.activate([
            imageSkeleton.widthAnchor.constraint(equalToConstant: 56),
            imageSkeleton.heightAnchor.constraint(equalToConstant: 56),
            imageSkeleton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: 8),
            imageSkeleton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 8)
        ])
        skeletonImageView = imageSkeleton
    }

    private func hideSkeleton() {
        skeletonTitleView?.removeFromSuperview()
        skeletonImageView?.removeFromSuperview()
        skeletonTitleView = nil
        skeletonImageView = nil
    }
}

private final class ShimmerPlaceholderView: UIView {
    private let shimmerView = UIView()
    private let gradient = CAGradientLayer()
    private var didStartAnimation = false

    init(cornerRadius: CGFloat) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.white.withAlphaComponent(0.07)
        layer.cornerRadius = cornerRadius
        clipsToBounds = true

        shimmerView.backgroundColor = .clear
        addSubview(shimmerView)

        gradient.colors = [
            UIColor.clear.cgColor,
            UIColor.white.withAlphaComponent(0.25).cgColor,
            UIColor.clear.cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        shimmerView.layer.addSublayer(gradient)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shimmerView.frame = CGRect(x: -bounds.width * 0.6, y: 0, width: bounds.width * 0.6, height: bounds.height)
        gradient.frame = shimmerView.bounds
        startAnimationIfNeeded()
    }

    private func startAnimationIfNeeded() {
        guard !didStartAnimation, bounds.width > 0 else { return }
        didStartAnimation = true

        let animation = CABasicAnimation(keyPath: "position.x")
        animation.fromValue = -shimmerView.bounds.width / 2
        animation.toValue = bounds.width + shimmerView.bounds.width / 2
        animation.duration = 1.3
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        shimmerView.layer.add(animation, forKey: "shimmerSlide")
    }
}

extension SearchBrowseCategoryCell {

    static func cardBackgroundColor(at index: Int) -> UIColor {
        guard !cardPalette.isEmpty else {
            return UIColor(white: 0.18, alpha: 1)
        }

        let orderIndex = gridColorOrder[index % gridColorOrder.count]
        return cardPalette[orderIndex % cardPalette.count]
    }
}
