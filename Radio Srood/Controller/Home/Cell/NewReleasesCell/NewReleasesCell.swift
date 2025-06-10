import UIKit

class NewReleasesCell: UITableViewCell {
    
    @IBOutlet private weak var newReleasesCollectionView: UICollectionView!
    @IBOutlet private weak var newReleasesHeightConstraint: NSLayoutConstraint!
    
    var newReleases: [NewRelease] = []
    var presentView: HomeViewController?
    // Removed presentViewBrowse since you only want HomeViewController case
    
    override func awakeFromNib() {
        super.awakeFromNib()
        newReleasesCollectionView.delegate = self
        newReleasesCollectionView.dataSource = self
        
        if let layout = newReleasesCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 10
            layout.sectionInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        }
        
        newReleasesCollectionView.isPagingEnabled = false
        newReleasesCollectionView.showsHorizontalScrollIndicator = true
        
        setCellHeight()
    }

    
    func reloadCollectionView() {
        setCellHeight()
        newReleasesCollectionView.reloadData()
    }
    
    private func setCellHeight() {
        let topInset: CGFloat = 10
        let bottomInset: CGFloat = 10
        let lineSpace: CGFloat = 10
        let rowCount: CGFloat = 3 // 3 rows fixed
        
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

        // visible width for 2.5 cells (2 full + 1 half)
        let totalSpacing = leftInset + rightInset + spacing * 1.5  // spacing between cells count is 1.5 for 2.5 cells
        let availableWidth = Common.screenSize.width - totalSpacing

        let cellWidth = availableWidth / 2.5
        return cellWidth
    }


}

extension NewReleasesCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Show all items, scrolling horizontally to see more if needed
        return newReleases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.registerAndGet(NewReleasesCollectionCell.self, indexPath: indexPath) {
            cell.newRelease = newReleases[indexPath.row]
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedNewRelease = newReleases[indexPath.row]
        
        if let presentView = presentView {
            presentView.groupID = selectedNewRelease.newReleasesTrackID
            presentView.homeHeader = .newReleases
            
            if presentView.interstitial != nil {
                presentView.interstitial.present(fromRootViewController: presentView)
            } else {
                presentView.openMusicPlayerViewController()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = getCellWidth()
        let height = getCellHeight()
        return CGSize(width: width, height: height)
    }
}
