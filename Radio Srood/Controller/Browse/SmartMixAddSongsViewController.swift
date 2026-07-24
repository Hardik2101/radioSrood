//
//  SmartMixAddSongsViewController.swift
//  Radio Srood
//

import UIKit

protocol SmartMixAddSongsDelegate: AnyObject {
    func smartMixAddSongsDidAdd(_ track: Track)
}

final class SmartMixAddSongsViewController: UIViewController {
    weak var delegate: SmartMixAddSongsDelegate?
    var existingTrackIDs: Set<Int> = []

    private var results: [SearchModel] = []
    private var searchWorkItem: DispatchWorkItem?
    private var addedTrackIDs: Set<Int> = []

    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0.10, alpha: 1)
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Add Songs to Mix"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .white
        return label
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return button
    }()

    private lazy var searchField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.textColor = .white
        field.tintColor = .white
        field.font = .systemFont(ofSize: 15)
        field.backgroundColor = .clear
        field.layer.cornerRadius = 10
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor(white: 0.35, alpha: 1).cgColor
        field.attributedPlaceholder = NSAttributedString(
            string: "Search songs or artists...",
            attributes: [.foregroundColor: UIColor(white: 0.5, alpha: 1)]
        )
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 40))
        field.leftViewMode = .always
        field.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 40))
        field.rightViewMode = .always
        field.clearButtonMode = .whileEditing
        field.returnKeyType = .search
        field.delegate = self
        field.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
        return field
    }()

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.keyboardDismissMode = .onDrag
        table.rowHeight = 72
        table.delegate = self
        table.dataSource = self
        table.register(SmartMixAddSongCell.self, forCellReuseIdentifier: SmartMixAddSongCell.reuseID)
        return table
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Search for songs to add"
        label.textColor = UIColor(white: 0.5, alpha: 1)
        label.font = .systemFont(ofSize: 15)
        label.textAlignment = .center
        return label
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        addedTrackIDs = existingTrackIDs
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchField.becomeFirstResponder()
    }

    private func setupUI() {
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(closeButton)
        containerView.addSubview(searchField)
        containerView.addSubview(tableView)
        containerView.addSubview(emptyLabel)
        containerView.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.82),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 18),

            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),

            searchField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            searchField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            searchField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            searchField.heightAnchor.constraint(equalToConstant: 44),

            tableView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyLabel.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 40),

            activityIndicator.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 40)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(dimTapped(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func dimTapped(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: view)
        if !containerView.frame.contains(point) {
            dismiss(animated: true)
        }
    }

    @objc private func searchChanged() {
        searchWorkItem?.cancel()
        let query = searchField.text ?? ""
        let work = DispatchWorkItem { [weak self] in
            self?.performSearch(query)
        }
        searchWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }

    private func performSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            results = []
            emptyLabel.text = trimmed.isEmpty ? "Search for songs to add" : "Keep typing..."
            emptyLabel.isHidden = false
            tableView.reloadData()
            return
        }

        emptyLabel.isHidden = true
        activityIndicator.startAnimating()

        DataHelper.getSearchResults(query: trimmed) { [weak self] response in
            DispatchQueue.main.async {
                guard let self else { return }
                self.activityIndicator.stopAnimating()
                self.results = response ?? []
                self.emptyLabel.isHidden = !self.results.isEmpty
                self.emptyLabel.text = "No songs found"
                self.tableView.reloadData()
            }
        }
    }
}

// MARK: - UITableView
extension SmartMixAddSongsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SmartMixAddSongCell.reuseID, for: indexPath) as! SmartMixAddSongCell
        let song = results[indexPath.row]
        let alreadyAdded = addedTrackIDs.contains(song.trackid)
        cell.configure(with: song, isAdded: alreadyAdded)
        cell.onAddTapped = { [weak self] in
            guard let self, !alreadyAdded else { return }
            self.addedTrackIDs.insert(song.trackid)
            self.delegate?.smartMixAddSongsDidAdd(song.convertToTrack())
            tableView.reloadRows(at: [indexPath], with: .none)
        }
        return cell
    }
}

// MARK: - UITextFieldDelegate
extension SmartMixAddSongsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        performSearch(textField.text ?? "")
        return true
    }
}

// MARK: - Add Song Cell
final class SmartMixAddSongCell: UITableViewCell {
    static let reuseID = "SmartMixAddSongCell"

    var onAddTapped: (() -> Void)?

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
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .white
        return label
    }()

    private let artistLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor(white: 0.55, alpha: 1)
        return label
    }()

    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1.5
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        button.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        button.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        return button
    }()

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

        contentView.addSubview(coverImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(artistLabel)
        contentView.addSubview(addButton)

        NSLayoutConstraint.activate([
            coverImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            coverImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            coverImageView.widthAnchor.constraint(equalToConstant: 52),
            coverImageView.heightAnchor.constraint(equalToConstant: 52),

            addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            addButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 32),
            addButton.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: addButton.leadingAnchor, constant: -10),
            titleLabel.topAnchor.constraint(equalTo: coverImageView.topAnchor, constant: 6),

            artistLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            artistLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2)
        ])
    }

    func configure(with song: SearchModel, isAdded: Bool) {
        titleLabel.text = song.track
        artistLabel.text = song.artist
        if let url = URL(string: song.artcover_200.isEmpty ? song.artcover : song.artcover_200) {
            coverImageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
        } else {
            coverImageView.image = UIImage(named: "Lav_Radio_Logo.png")
        }

        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        if isAdded {
            addButton.setImage(UIImage(systemName: "checkmark", withConfiguration: config), for: .normal)
            addButton.alpha = 0.5
            addButton.isEnabled = false
        } else {
            addButton.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
            addButton.alpha = 1
            addButton.isEnabled = true
        }
    }

    @objc private func addTapped() {
        onAddTapped?()
    }
}
