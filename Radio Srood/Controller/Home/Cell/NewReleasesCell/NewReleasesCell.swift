import UIKit

class NewReleasesCell: UITableViewCell {
    
    @IBOutlet private weak var newReleasesCollectionView: UICollectionView!
    @IBOutlet private weak var newReleasesHeightConstraint: NSLayoutConstraint!
    
    var newReleases: [NewRelease] = []
    var recentlyAdded: [RecentlyAdded] = []
    var presentView: HomeViewController?
    
    enum CellMode {
        case newReleases
        case recentlyAdded
    }
    
    private var mode: CellMode = .newReleases

    override func awakeFromNib() {
        super.awakeFromNib()
        setupCollectionView()
        setCellHeight()
    }
    
    private func setupCollectionView() {
        newReleasesCollectionView.delegate = self
        newReleasesCollectionView.dataSource = self
        
        if let layout = newReleasesCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 10
            layout.sectionInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        }
        
        newReleasesCollectionView.isPagingEnabled = false
        newReleasesCollectionView.showsHorizontalScrollIndicator = true
        
        newReleasesCollectionView.register(UINib(nibName: "NewReleasesCollectionCell", bundle: nil), forCellWithReuseIdentifier: "NewReleasesCollectionCell")
    }
    
    func reloadCollectionView() {
        setCellHeight()
        newReleasesCollectionView.reloadData()
    }
    
    private func setCellHeight() {
        let topInset: CGFloat = 10
        let bottomInset: CGFloat = 10
        let lineSpace: CGFloat = 10
        let rowCount: CGFloat = 3
        
        let cellHeight = getCellHeight()
        newReleasesHeightConstraint.constant = (cellHeight * rowCount) + (lineSpace * (rowCount - 1)) + topInset + bottomInset
    }
    
    private func getCellHeight() -> CGFloat {
        let width = getCellWidth()
        return width + 50
    }

    private func getCellWidth() -> CGFloat {
        let leftInset: CGFloat = 8
        let rightInset: CGFloat = 8
        let spacing: CGFloat = 10
        
        let totalSpacing = leftInset + rightInset + spacing * 1.5
        let availableWidth = Common.screenSize.width - totalSpacing
        
        return availableWidth / 2.5
    }

    // MARK: - Public Configuration Methods

    func configureCell(withNewReleases newReleases: [NewRelease], presenter: HomeViewController) {
        self.mode = .newReleases
        self.newReleases = newReleases
        self.recentlyAdded = []
        self.presentView = presenter
        reloadCollectionView()
    }

    func configureCell(withRecentlyAdded recentlyAdded: [RecentlyAdded], presenter: HomeViewController) {
        self.mode = .recentlyAdded
        self.recentlyAdded = recentlyAdded
        self.newReleases = []
        self.presentView = presenter
        reloadCollectionView()
    }
}

// MARK: - UICollectionView Delegate & Data Source

extension NewReleasesCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch mode {
        case .newReleases:
            return newReleases.count
        case .recentlyAdded:
            return recentlyAdded.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewReleasesCollectionCell", for: indexPath) as? NewReleasesCollectionCell else {
            return UICollectionViewCell()
        }
        
        switch mode {
        case .newReleases:
            cell.newRelease = newReleases[indexPath.row]
        case .recentlyAdded:
            cell.recentlyAdded = recentlyAdded[indexPath.row]
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let presentView = presentView else { return }

        switch mode {
        case .newReleases:
            let selected = newReleases[indexPath.row]
            presentView.groupID = selected.newReleasesTrackID
            presentView.homeHeader = .newReleases
        case .recentlyAdded:
            let selected = recentlyAdded[indexPath.row]
            presentView.groupID = selected.RAID
            presentView.homeHeader = .recentlyAdded
        }

        if let interstitial = presentView.interstitial {
            interstitial.present(fromRootViewController: presentView)
        } else {
            presentView.openMusicPlayerViewController()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: getCellWidth(), height: getCellHeight())
    }
}
