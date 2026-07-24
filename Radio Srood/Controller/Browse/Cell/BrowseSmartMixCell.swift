//
//  BrowseSmartMixCell.swift
//  Radio Srood
//

import UIKit

protocol BrowseSmartMixCellDelegate: AnyObject {
    func smartMixCellDidToggleArtist(_ artist: ArtistProfileSummary)
    func smartMixCellDidTapMore()
    func smartMixCellDidTapStartMix()
}

final class BrowseSmartMixCell: UITableViewCell {
    static let reuseID = "BrowseSmartMixCell"

    weak var delegate: BrowseSmartMixCellDelegate?

    private let columns = 4
    private let previewCount = SmartMixBuilder.previewArtistCount
    private let columnSpacing: CGFloat = 10
    private let lineSpacing: CGFloat = 12
    private let horizontalInset: CGFloat = 14

    var artists: [ArtistProfileSummary] = []

    var selectedArtistIDs: Set<String> = []

    private let cardView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0.11, alpha: 1)
        view.layer.cornerRadius = 18
        view.clipsToBounds = true
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Srood Smart Mix"
        label.font = UIFont(name: "Kohinoor Telugu Medium", size: 20)
            ?? .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .white
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Start your personalized mix"
        label.font = UIFont.italicSystemFont(ofSize: 13)
        label.textColor = UIColor(white: 0.55, alpha: 1)
        return label
    }()

    private lazy var moreButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("More >", for: .normal)
        button.setTitleColor(UIColor(red: 0.35, green: 0.72, blue: 0.95, alpha: 1), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.addTarget(self, action: #selector(moreTapped), for: .touchUpInside)
        return button
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = columnSpacing
        layout.minimumLineSpacing = lineSpacing
        layout.sectionInset = .zero

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(SmartMixArtistCell.self, forCellWithReuseIdentifier: SmartMixArtistCell.reuseID)
        return collectionView
    }()

    private lazy var moreArtistsButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("More Artists", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.backgroundColor = UIColor(white: 0.16, alpha: 1)
        button.layer.cornerRadius = 24
        button.addTarget(self, action: #selector(moreTapped), for: .touchUpInside)
        return button
    }()

    private lazy var startMixButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        button.backgroundColor = UIColor(red: 0.90, green: 0.12, blue: 0.18, alpha: 1)
        button.layer.cornerRadius = 24
        button.tintColor = .white
        button.addTarget(self, action: #selector(startMixTapped), for: .touchUpInside)
        return button
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

        contentView.addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(subtitleLabel)
        cardView.addSubview(moreButton)
        cardView.addSubview(collectionView)
        cardView.addSubview(moreArtistsButton)
        cardView.addSubview(startMixButton)

        collectionHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 280)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: horizontalInset),

            moreButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            moreButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -horizontalInset),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: moreButton.leadingAnchor, constant: -8),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -horizontalInset),

            collectionView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 14),
            collectionView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: horizontalInset),
            collectionView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -horizontalInset),
            collectionHeightConstraint,

            moreArtistsButton.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 16),
            moreArtistsButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: horizontalInset),
            moreArtistsButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
            moreArtistsButton.heightAnchor.constraint(equalToConstant: 48),

            startMixButton.topAnchor.constraint(equalTo: moreArtistsButton.topAnchor),
            startMixButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -horizontalInset),
            startMixButton.leadingAnchor.constraint(equalTo: moreArtistsButton.trailingAnchor, constant: 10),
            startMixButton.widthAnchor.constraint(equalTo: moreArtistsButton.widthAnchor),
            startMixButton.heightAnchor.constraint(equalToConstant: 48)
        ])

        updateStartMixButton()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
        updateCollectionHeight()
    }

    func reloadCollectionView() {
        collectionView.reloadData()
        updateStartMixButton()
        setNeedsLayout()
    }

    /// Updates selection UI without recreating cells (keeps circular clips intact).
    func applySelection(_ ids: Set<String>) {
        selectedArtistIDs = ids
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard indexPath.item < previewArtists.count,
                  let cell = collectionView.cellForItem(at: indexPath) as? SmartMixArtistCell else { continue }
            let artist = previewArtists[indexPath.item]
            cell.setSelectedState(ids.contains(artist.artistid))
        }
        updateStartMixButton()
    }

    private var previewArtists: [ArtistProfileSummary] {
        Array(artists.prefix(previewCount))
    }

    private func itemWidth(for width: CGFloat) -> CGFloat {
        let totalSpacing = columnSpacing * CGFloat(columns - 1)
        return floor((width - totalSpacing) / CGFloat(columns))
    }

    private func updateCollectionHeight() {
        let rows = ceil(Double(previewArtists.count) / Double(columns))
        guard rows > 0 else {
            collectionHeightConstraint.constant = 0
            return
        }
        let width = collectionView.bounds.width > 0 ? collectionView.bounds.width : (UIScreen.main.bounds.width - 52)
        let imageSize = itemWidth(for: width)
        let itemHeight = imageSize + SmartMixArtistCell.nameAreaHeight
        let height = (CGFloat(rows) * itemHeight) + (CGFloat(max(rows - 1, 0)) * lineSpacing)
        collectionHeightConstraint.constant = max(height, 0)
    }

    private func updateStartMixButton() {
        let count = selectedArtistIDs.count
        let title = count > 0 ? "Start Mix (\(count))" : "Start Mix"
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        let icon = UIImage(systemName: "waveform", withConfiguration: config)
        startMixButton.setImage(icon, for: .normal)
        startMixButton.setTitle("  \(title)", for: .normal)
        startMixButton.alpha = count > 0 ? 1.0 : 0.55
        startMixButton.isEnabled = count > 0
    }

    @objc private func moreTapped() {
        delegate?.smartMixCellDidTapMore()
    }

    @objc private func startMixTapped() {
        guard !selectedArtistIDs.isEmpty else { return }
        delegate?.smartMixCellDidTapStartMix()
    }
}

// MARK: - UICollectionView
extension BrowseSmartMixCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        previewArtists.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SmartMixArtistCell.reuseID, for: indexPath) as! SmartMixArtistCell
        let artist = previewArtists[indexPath.item]
        cell.configure(with: artist, isSelected: selectedArtistIDs.contains(artist.artistid))
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width > 0 ? collectionView.bounds.width : (UIScreen.main.bounds.width - 52)
        let imageSize = itemWidth(for: width)
        return CGSize(width: imageSize, height: imageSize + SmartMixArtistCell.nameAreaHeight)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? SmartMixArtistCell)?.refreshCircularAppearance()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let artist = previewArtists[indexPath.item]
        if selectedArtistIDs.contains(artist.artistid) {
            selectedArtistIDs.remove(artist.artistid)
        } else {
            selectedArtistIDs.insert(artist.artistid)
        }

        if let cell = collectionView.cellForItem(at: indexPath) as? SmartMixArtistCell {
            cell.setSelectedState(selectedArtistIDs.contains(artist.artistid))
        } else {
            collectionView.reloadItems(at: [indexPath])
        }
        updateStartMixButton()
        delegate?.smartMixCellDidToggleArtist(artist)
    }
}
