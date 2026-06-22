//
//  SearchViewController.swift
//  Radio Srood
//
//  Created by Hardik on 08/05/26.
//  Copyright © 2026 Radio Srood Inc. All rights reserved.
//

import UIKit

class SearchViewController: UI_VC, OptionsViewControllerDelegate {
    @IBOutlet private weak var tfSearch: UITextField!
    @IBOutlet private weak var tblSearch: UITableView!

    private var categories: [SearchPlaylistCategory] = []
    private var subCategoryGroups: [SearchSubCategoryGroup] = []
    private var searchResults: [SearchModel] = []
    private var isSearching = false
    private var isBrowseCategoriesLoaded = false
    private var isFetchingBrowseCategories = false

    private static let skeletonItemCount = 8

    private let lblTitle: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Search"
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = .white
        return label
    }()

    private let lblBrowseAll: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Browse all"
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .white
        return label
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = .zero

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(SearchBrowseCategoryCell.self, forCellWithReuseIdentifier: SearchBrowseCategoryCell.reuseID)
        return collectionView
    }()

    private var collectionViewBottomConstraint: NSLayoutConstraint?
    private var tfSearchTrailingToCloseButton: NSLayoutConstraint?
    private var tfSearchTrailingToEdge: NSLayoutConstraint?
    private var btnCloseWidthConstraint: NSLayoutConstraint?

    private let btnCloseSearch: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor(white: 0.18, alpha: 1)
        button.layer.cornerRadius = 22
        button.clipsToBounds = true
        button.accessibilityLabel = "Clear search"
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        updateBottomInset()

        if !isBrowseCategoriesLoaded {
            fetchBrowseCategories()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkInternetForTabbar()
    }

    override func refreshAfterReconnect() {
        guard !isBrowseCategoriesLoaded else { return }
        fetchBrowseCategories()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func fixMiniplayerSpace() {
        super.fixMiniplayerSpace()
        updateBottomInset()
    }

    private func updateBottomInset() {
        let miniPlayerInset = TabbarVC.isMiniPlayerVisible ? 80.0 : 0.0
        collectionViewBottomConstraint?.constant = -miniPlayerInset
        tblSearch.contentInset.bottom = miniPlayerInset
        view.layoutIfNeeded()
    }

    private func setupUI() {
        view.backgroundColor = .black

        view.addSubview(lblTitle)
        view.addSubview(lblBrowseAll)
        view.addSubview(collectionView)
        view.addSubview(btnCloseSearch)

        tfSearch.translatesAutoresizingMaskIntoConstraints = false
        styleSearchField()
        setupSearchTable()

        btnCloseSearch.addTarget(self, action: #selector(cancelSearch), for: .touchUpInside)

        let collectionBottom = collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        collectionViewBottomConstraint = collectionBottom

        btnCloseWidthConstraint = btnCloseSearch.widthAnchor.constraint(equalToConstant: 0)
        tfSearchTrailingToCloseButton = tfSearch.trailingAnchor.constraint(equalTo: btnCloseSearch.leadingAnchor, constant: -12)
        tfSearchTrailingToEdge = tfSearch.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor)

        NSLayoutConstraint.activate([
            lblTitle.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            lblTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            lblTitle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionBottom,

            tfSearch.topAnchor.constraint(equalTo: lblTitle.bottomAnchor, constant: 16),
            tfSearch.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            tfSearch.heightAnchor.constraint(equalToConstant: 44),

            btnCloseSearch.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            btnCloseSearch.centerYAnchor.constraint(equalTo: tfSearch.centerYAnchor),
            btnCloseSearch.heightAnchor.constraint(equalToConstant: 44),
            btnCloseWidthConstraint!,

            lblBrowseAll.topAnchor.constraint(equalTo: tfSearch.bottomAnchor, constant: 24),
            lblBrowseAll.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            lblBrowseAll.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),

            collectionView.topAnchor.constraint(equalTo: lblBrowseAll.bottomAnchor, constant: 12)
        ])

        tfSearchTrailingToEdge?.isActive = true
        btnCloseSearch.isHidden = true
    }

    private func styleSearchField() {
        tfSearch.borderStyle = .none
        tfSearch.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        tfSearch.textColor = .white
        tfSearch.font = .systemFont(ofSize: 15)
        tfSearch.layer.cornerRadius = 22
        tfSearch.clipsToBounds = true
        tfSearch.attributedPlaceholder = NSAttributedString(
            string: "Artists, Songs, Lyrics, and More",
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.45)]
        )
        tfSearch.delegate = self
        tfSearch.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        tfSearch.returnKeyType = .search
        tfSearch.autocorrectionType = .no
        tfSearch.autocapitalizationType = .none
        tfSearch.clearButtonMode = .never

        let iconView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        iconView.tintColor = UIColor.white.withAlphaComponent(0.55)
        iconView.contentMode = .scaleAspectFit
        iconView.frame = CGRect(x: 0, y: 0, width: 36, height: 20)

        let leftContainer = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 20))
        leftContainer.addSubview(iconView)
        iconView.center = leftContainer.center
        tfSearch.leftView = leftContainer
        tfSearch.leftViewMode = .always

        let rightPadding = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 20))
        tfSearch.rightView = rightPadding
        tfSearch.rightViewMode = .always
    }

    private func updateCloseButtonVisibility() {
        let hasText = !(tfSearch.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let shouldShow = isSearching || hasText || tfSearch.isFirstResponder

        btnCloseSearch.isHidden = !shouldShow
        btnCloseWidthConstraint?.constant = shouldShow ? 44 : 0
        tfSearchTrailingToCloseButton?.isActive = shouldShow
        tfSearchTrailingToEdge?.isActive = !shouldShow

        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }

    private func setupSearchTable() {
        tblSearch.delegate = self
        tblSearch.dataSource = self
        tblSearch.backgroundColor = .clear
        tblSearch.separatorStyle = .none
        tblSearch.isHidden = true
        tblSearch.register(UINib(nibName: "SearchSongCell", bundle: nil), forCellReuseIdentifier: "SearchSongCell")

        let longPressSearch = UILongPressGestureRecognizer(target: self, action: #selector(handleSearchLongPress(_:)))
        longPressSearch.minimumPressDuration = 0.3
        tblSearch.addGestureRecognizer(longPressSearch)

        tblSearch.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tblSearch.topAnchor.constraint(equalTo: tfSearch.bottomAnchor, constant: 12),
            tblSearch.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            tblSearch.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            tblSearch.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func fetchBrowseCategories() {
        guard !isFetchingBrowseCategories else { return }
        isFetchingBrowseCategories = true

        if !isBrowseCategoriesLoaded {
            collectionView.reloadData()
        }

        DataHelper.getSearchBrowseAllData { [weak self] response in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isFetchingBrowseCategories = false

                guard let response else { return }

                self.categories = response.playlistCategories
                self.subCategoryGroups = response.subCategories
                self.isBrowseCategoriesLoaded = true
                self.collectionView.reloadData()
            }
        }
    }

    private func setSearching(_ searching: Bool) {
        isSearching = searching
        tblSearch.isHidden = !searching
        collectionView.isHidden = searching
        lblBrowseAll.isHidden = searching
        updateCloseButtonVisibility()
    }

    @objc private func searchTextChanged() {
        guard let query = tfSearch.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }

        updateCloseButtonVisibility()

        if query.isEmpty {
            cancelSearch()
            return
        }

        setSearching(true)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(performSearch), object: nil)
        perform(#selector(performSearch), with: query, afterDelay: 0.5)
    }

    @objc private func performSearch(_ query: String) {
        DataHelper.getSearchResults(query: query) { [weak self] results in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let results = results {
                    self.searchResults = results
                } else {
                    self.searchResults = []
                    print("No results found for: \(query)")
                }
                self.tblSearch.reloadData()
            }
        }
    }

    @objc private func cancelSearch() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(performSearch), object: nil)
        tfSearch.text = ""
        tfSearch.resignFirstResponder()
        searchResults.removeAll()
        tblSearch.reloadData()
        setSearching(false)
        updateCloseButtonVisibility()
    }

    func didUpdateTrackMetadata() {
        tblSearch.reloadData()
    }

    @objc private func handleSearchLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }

        let point = gesture.location(in: tblSearch)
        guard let indexPath = tblSearch.indexPathForRow(at: point),
              indexPath.row < searchResults.count else { return }

        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()

        if let cell = tblSearch.cellForRow(at: indexPath) {
            cell.isUserInteractionEnabled = false
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                cell.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
            }) { _ in
                UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                    cell.transform = .identity
                    cell.isUserInteractionEnabled = true
                })
            }
        }

        let track = searchResults[indexPath.row].convertToTrack()
        guard let optionsVC = storyboard?.instantiateViewController(withIdentifier: "OptionsViewController") as? OptionsViewController else {
            print("Error: Could not instantiate OptionsViewController")
            return
        }
        optionsVC.track = track
        optionsVC.delegate = self
        optionsVC.modalPresentationStyle = .overFullScreen
        present(optionsVC, animated: true)
    }
}

// MARK: - UICollectionView

extension SearchViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        isBrowseCategoriesLoaded ? categories.count : Self.skeletonItemCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SearchBrowseCategoryCell.reuseID, for: indexPath) as! SearchBrowseCategoryCell

        if isBrowseCategoriesLoaded {
            cell.configure(with: categories[indexPath.item], index: indexPath.item)
        } else {
            cell.showSkeleton()
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 12
        let contentWidth = collectionView.bounds.width > 0 ? collectionView.bounds.width : view.bounds.width - 32
        let width = (contentWidth - spacing) / 2
        return CGSize(width: floor(width), height: 100)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard isBrowseCategoriesLoaded, indexPath.item < categories.count else { return }

        let category = categories[indexPath.item]
        let subPlaylists = subCategoryGroups.first(where: { $0.playlistTitle == category.title })?.subPlaylist ?? []

        let detailVC = SearchCategoryDetailViewController()
        detailVC.categoryTitle = category.title
        detailVC.subPlaylists = subPlaylists
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - UITableView

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        searchResults.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        70
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchSongCell", for: indexPath) as! SearchSongCell
        cell.selectionStyle = .none
        if let url = URL(string: self.searchResults[indexPath.row].artcover_200) {
            cell.imgArtist.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            cell.imgBg.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
        }
        cell.lblArtistName.text = self.searchResults[indexPath.row].artist
        cell.lblSongName.text = self.searchResults[indexPath.row].track
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tracks = searchResults.map { $0.convertToPodcastModel() }
        let vc = storyboard?.instantiateViewController(withIdentifier: "MyMusicPlayerViewController") as! MyMusicPlayerViewController
        vc.selectedIndex = indexPath.row
        vc.tempTrack = tracks
        vc.track = tracks
        vc.isShowOptionList = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension SearchViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateCloseButtonVisibility()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        updateCloseButtonVisibility()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

