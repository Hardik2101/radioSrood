//
//  SearchViewController.swift
//  Radio Srood
//
//  Created by Hardik on 08/05/26.
//  Copyright © 2026 Radio Srood Inc. All rights reserved.
//

import UIKit

class SearchViewController: UI_VC {
    @IBOutlet private weak var tfSearch: UITextField!
    @IBOutlet private weak var tblSearch: UITableView!

    private var categories: [SearchPlaylistCategory] = []
    private var subCategoryGroups: [SearchSubCategoryGroup] = []
    private var searchResults: [SearchModel] = []
    private var isSearching = false

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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchBrowseCategories()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        updateBottomInset()
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

        styleSearchField()
        setupSearchTable()

        let collectionBottom = collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        collectionViewBottomConstraint = collectionBottom

        NSLayoutConstraint.activate([
            lblTitle.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            lblTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            lblTitle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            tfSearch.topAnchor.constraint(equalTo: lblTitle.bottomAnchor, constant: 16),
            tfSearch.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tfSearch.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tfSearch.heightAnchor.constraint(equalToConstant: 44),

            lblBrowseAll.topAnchor.constraint(equalTo: tfSearch.bottomAnchor, constant: 24),
            lblBrowseAll.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            lblBrowseAll.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            collectionView.topAnchor.constraint(equalTo: lblBrowseAll.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionBottom
        ])
    }

    private func styleSearchField() {
        tfSearch.borderStyle = .none
        tfSearch.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        tfSearch.textColor = .white
        tfSearch.font = .systemFont(ofSize: 15)
        tfSearch.layer.cornerRadius = 8
        tfSearch.clipsToBounds = true
        tfSearch.attributedPlaceholder = NSAttributedString(
            string: "Search,Artist,Song or Albums...",
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.45)]
        )
        tfSearch.delegate = self
        tfSearch.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        tfSearch.returnKeyType = .search
        tfSearch.autocorrectionType = .no
        tfSearch.autocapitalizationType = .none

        let iconView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        iconView.tintColor = UIColor.white.withAlphaComponent(0.55)
        iconView.contentMode = .scaleAspectFit
        iconView.frame = CGRect(x: 0, y: 0, width: 36, height: 20)

        let leftContainer = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 20))
        leftContainer.addSubview(iconView)
        iconView.center = leftContainer.center
        tfSearch.leftView = leftContainer
        tfSearch.leftViewMode = .always

        let clearButton = UIButton(type: .custom)
        clearButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        clearButton.tintColor = UIColor.white.withAlphaComponent(0.45)
        clearButton.frame = CGRect(x: 0, y: 0, width: 36, height: 20)
        clearButton.addTarget(self, action: #selector(clearSearch), for: .touchUpInside)
        tfSearch.rightView = clearButton
        tfSearch.rightViewMode = .whileEditing
    }

    private func setupSearchTable() {
        tblSearch.delegate = self
        tblSearch.dataSource = self
        tblSearch.backgroundColor = .clear
        tblSearch.separatorStyle = .none
        tblSearch.isHidden = true
        tblSearch.register(UINib(nibName: "SearchSongCell", bundle: nil), forCellReuseIdentifier: "SearchSongCell")

        tblSearch.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tblSearch.topAnchor.constraint(equalTo: tfSearch.bottomAnchor, constant: 12),
            tblSearch.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            tblSearch.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            tblSearch.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func fetchBrowseCategories() {
        DataHelper.getSearchBrowseAllData { [weak self] response in
            guard let self else { return }
            DispatchQueue.main.async {
                self.categories = response?.playlistCategories ?? []
                self.subCategoryGroups = response?.subCategories ?? []
                self.collectionView.reloadData()
            }
        }
    }

    private func setSearching(_ searching: Bool) {
        isSearching = searching
        tblSearch.isHidden = !searching
        collectionView.isHidden = searching
        lblBrowseAll.isHidden = searching
    }

    @objc private func searchTextChanged() {
        guard let query = tfSearch.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }

        if query.isEmpty {
            cancelSearch()
            return
        }

        setSearching(true)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(performSearch), object: nil)
        perform(#selector(performSearch), with: query, afterDelay: 0.4)
    }

    @objc private func performSearch(_ query: String) {
        DataHelper.getSearchResults(query: query) { [weak self] results in
            guard let self else { return }
            DispatchQueue.main.async {
                self.searchResults = results ?? []
                self.tblSearch.reloadData()
            }
        }
    }

    @objc private func clearSearch() {
        cancelSearch()
    }

    private func cancelSearch() {
        tfSearch.text = ""
        tfSearch.resignFirstResponder()
        searchResults.removeAll()
        tblSearch.reloadData()
        setSearching(false)
    }
}

// MARK: - UICollectionView

extension SearchViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        categories.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SearchBrowseCategoryCell.reuseID, for: indexPath) as! SearchBrowseCategoryCell
        cell.configure(with: categories[indexPath.item], index: indexPath.item)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 12
        let contentWidth = collectionView.bounds.width > 0 ? collectionView.bounds.width : view.bounds.width - 32
        let width = (contentWidth - spacing) / 2
        return CGSize(width: floor(width), height: 100)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        searchResults.count
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
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let query = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !query.isEmpty {
            performSearch(query)
        }
        return true
    }
}

