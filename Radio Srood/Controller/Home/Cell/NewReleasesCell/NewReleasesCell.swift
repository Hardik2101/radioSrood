import UIKit

class NewReleasesCell: UITableViewCell {
    
    @IBOutlet private weak var newReleasesCollectionView: UICollectionView!
    @IBOutlet private weak var newReleasesHeightConstraint: NSLayoutConstraint!
    
    var newReleases: [NewRelease] = []
    var recentlyAdded: [RecentlyAdded] = []
    var presentView: HomeViewController?
    
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
        
        // Register cell
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
}

// MARK: - UICollectionView Delegate & Data Source

extension NewReleasesCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if !newReleases.isEmpty {
            return newReleases.count
        } else if !recentlyAdded.isEmpty {
            return recentlyAdded.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewReleasesCollectionCell", for: indexPath) as? NewReleasesCollectionCell else {
            return UICollectionViewCell()
        }
        
        if !newReleases.isEmpty {
            cell.newRelease = newReleases[indexPath.row]
        } else if !recentlyAdded.isEmpty {
            cell.recentlyAdded = recentlyAdded[indexPath.row]
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let presentView = presentView else { return }
        
        if !newReleases.isEmpty {
            let selected = newReleases[indexPath.row]
            presentView.groupID = selected.newReleasesTrackID
            presentView.homeHeader = .newReleases
        } else if !recentlyAdded.isEmpty {
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
