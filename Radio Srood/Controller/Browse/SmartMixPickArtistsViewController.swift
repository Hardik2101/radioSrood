//
//  SmartMixPickArtistsViewController.swift
//  Radio Srood
//

import UIKit

protocol SmartMixPickArtistsDelegate: AnyObject {
    func smartMixPickArtistsDidUpdateSelection(_ selectedIDs: Set<String>)
    func smartMixPickArtistsDidRequestStartMix(_ selectedArtists: [ArtistProfileSummary])
}

final class SmartMixPickArtistsViewController: UI_VC {
    var allArtists: [ArtistProfileSummary] = []
    var selectedArtistIDs: Set<String> = []
    weak var delegate: SmartMixPickArtistsDelegate?

    private let columns: CGFloat = 3
    private let columnSpacing: CGFloat = 14
    private let lineSpacing: CGFloat = 18
    private let horizontalInset: CGFloat = 18
    private let pageSize = 60

    private var filteredArtists: [ArtistProfileSummary] = []
    private var visibleCount = 60
    private var isLoadingMore = false
    private var searchWorkItem: DispatchWorkItem?

    private var collectionBottomConstraint: NSLayoutConstraint?
    private var startMixBottomConstraint: NSLayoutConstraint?

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Pick Artists"
        label.font = UIFont(name: "Kohinoor Telugu Medium", size: 20)
            ?? .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private lazy var searchContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0.12, alpha: 1)
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(white: 0.28, alpha: 1).cgColor
        return view
    }()

    private let searchIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = UIColor(white: 0.55, alpha: 1)
        imageView.contentMode = .scaleAspectFit
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        imageView.image = UIImage(systemName: "magnifyingglass", withConfiguration: config)
        return imageView
    }()

    private lazy var searchField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.textColor = .white
        field.tintColor = .white
        field.font = .systemFont(ofSize: 16, weight: .regular)
        field.attributedPlaceholder = NSAttributedString(
            string: "Search Artists",
            attributes: [.foregroundColor: UIColor(white: 0.5, alpha: 1)]
        )
        field.clearButtonMode = .whileEditing
        field.returnKeyType = .search
        field.delegate = self
        field.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        return field
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = columnSpacing
        layout.minimumLineSpacing = lineSpacing
        layout.sectionInset = UIEdgeInsets(top: 8, left: horizontalInset, bottom: 100, right: horizontalInset)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .black
        collectionView.keyboardDismissMode = .onDrag
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(SmartMixArtistCell.self, forCellWithReuseIdentifier: SmartMixArtistCell.reuseID)
        return collectionView
    }()

    private lazy var startMixButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.backgroundColor = UIColor(red: 0.90, green: 0.12, blue: 0.18, alpha: 1)
        button.layer.cornerRadius = 26
        button.tintColor = .white
        button.addTarget(self, action: #selector(startMixTapped), for: .touchUpInside)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.35
        button.layer.shadowRadius = 8
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        filteredArtists = allArtists
        visibleCount = min(pageSize, filteredArtists.count)
        setupUI()
        updateStartMixButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        updateBottomInset()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.smartMixPickArtistsDidUpdateSelection(selectedArtistIDs)
        if isMovingFromParent {
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }

    override func fixMiniplayerSpace() {
        super.fixMiniplayerSpace()
        updateBottomInset()
    }

    private func setupUI() {
        view.addSubview(closeButton)
        view.addSubview(titleLabel)
        view.addSubview(searchContainer)
        searchContainer.addSubview(searchIcon)
        searchContainer.addSubview(searchField)
        view.addSubview(collectionView)
        view.addSubview(startMixButton)

        let collectionBottom = collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        collectionBottomConstraint = collectionBottom
        let startMixBottom = startMixButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        startMixBottomConstraint = startMixBottom

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            searchContainer.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 12),
            searchContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchContainer.heightAnchor.constraint(equalToConstant: 44),

            searchIcon.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 12),
            searchIcon.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            searchIcon.widthAnchor.constraint(equalToConstant: 18),
            searchIcon.heightAnchor.constraint(equalToConstant: 18),

            searchField.leadingAnchor.constraint(equalTo: searchIcon.trailingAnchor, constant: 8),
            searchField.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -12),
            searchField.topAnchor.constraint(equalTo: searchContainer.topAnchor),
            searchField.bottomAnchor.constraint(equalTo: searchContainer.bottomAnchor),

            collectionView.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionBottom,

            startMixButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startMixButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 180),
            startMixButton.heightAnchor.constraint(equalToConstant: 52),
            startMixBottom
        ])
    }

    private var displayedArtists: [ArtistProfileSummary] {
        Array(filteredArtists.prefix(visibleCount))
    }

    private var selectedArtists: [ArtistProfileSummary] {
        allArtists.filter { selectedArtistIDs.contains($0.artistid) }
    }

    private func itemWidth(for width: CGFloat) -> CGFloat {
        let totalInset = horizontalInset * 2
        let totalSpacing = columnSpacing * (columns - 1)
        return floor((width - totalInset - totalSpacing) / columns)
    }

    private func updateStartMixButton() {
        let count = selectedArtistIDs.count
        let title = count > 0 ? "Start Mix (\(count))" : "Start Mix"
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        let icon = UIImage(systemName: "waveform", withConfiguration: config)
        startMixButton.setImage(icon, for: .normal)
        startMixButton.setTitle("  \(title)", for: .normal)
        startMixButton.isHidden = count == 0
        startMixButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 22, bottom: 0, right: 22)
    }

    private func updateBottomInset() {
        let miniPlayerInset = TabbarVC.isMiniPlayerVisible ? 60.0 : 0.0
        collectionBottomConstraint?.constant = -miniPlayerInset
        startMixBottomConstraint?.constant = -16 - miniPlayerInset
        collectionView.contentInset.bottom = 90 + miniPlayerInset
        view.layoutIfNeeded()
    }

    private func applySearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            filteredArtists = allArtists
        } else {
            let lower = trimmed.lowercased()
            filteredArtists = allArtists.filter {
                $0.artist.lowercased().contains(lower)
                    || ($0.artistDari?.contains(trimmed) ?? false)
                    || $0.artistid.lowercased().contains(lower)
            }
        }
        visibleCount = min(pageSize, filteredArtists.count)
        collectionView.reloadData()
    }

    private func loadMoreIfNeeded() {
        guard visibleCount < filteredArtists.count, !isLoadingMore else { return }
        isLoadingMore = true
        visibleCount = min(visibleCount + pageSize, filteredArtists.count)
        collectionView.reloadData()
        isLoadingMore = false
    }

    @objc private func closeTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func searchTextChanged() {
        searchWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.applySearch(self?.searchField.text ?? "")
        }
        searchWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: work)
    }

    @objc private func startMixTapped() {
        guard !selectedArtistIDs.isEmpty else { return }
        delegate?.smartMixPickArtistsDidUpdateSelection(selectedArtistIDs)
        delegate?.smartMixPickArtistsDidRequestStartMix(selectedArtists)
    }
}

// MARK: - UICollectionView
extension SmartMixPickArtistsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        displayedArtists.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SmartMixArtistCell.reuseID, for: indexPath) as! SmartMixArtistCell
        let artist = displayedArtists[indexPath.item]
        cell.configure(
            with: artist,
            isSelected: selectedArtistIDs.contains(artist.artistid),
            showsDariName: true
        )
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width > 0 ? collectionView.bounds.width : view.bounds.width
        let imageSize = itemWidth(for: width)
        return CGSize(width: imageSize, height: imageSize + SmartMixArtistCell.pickNameAreaHeight)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let artist = displayedArtists[indexPath.item]
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
        delegate?.smartMixPickArtistsDidUpdateSelection(selectedArtistIDs)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? SmartMixArtistCell)?.refreshCircularAppearance()
        if indexPath.item >= max(displayedArtists.count - 9, 0) {
            loadMoreIfNeeded()
        }
    }
}

// MARK: - UITextFieldDelegate
extension SmartMixPickArtistsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
