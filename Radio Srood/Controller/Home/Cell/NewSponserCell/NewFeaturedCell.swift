import UIKit

class NewFeaturedCell: UITableViewCell {
    
    var featuredTop: [FeaturedTop] = []
    var presentView: HomeViewController?
    var presentViewBrowse: BrowseTabVC?

    @IBOutlet weak var newFeaturedsCollectionView: UICollectionView!
//    @IBOutlet private weak var newReleasesHeightConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        newFeaturedsCollectionView.delegate = self
        newFeaturedsCollectionView.dataSource = self
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal // Set the scroll direction to horizontal
        layout.minimumLineSpacing = 20 // Space between cells
        layout.minimumInteritemSpacing = 20 // Space between items
        
        newFeaturedsCollectionView.setCollectionViewLayout(layout, animated: false)
        newFeaturedsCollectionView.showsHorizontalScrollIndicator = false

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    func reloadCollectionView() {
        newFeaturedsCollectionView.reloadData()
    }
    
    


}

extension NewFeaturedCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.featuredTop.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.registerAndGet(NewHomeCollectionViewCell.self, indexPath: indexPath) {
            let featuredItem = self.featuredTop[indexPath.row]
            if let url = URL(string: featuredItem.featuredImage) {
                cell.imgView.af_setImage(withURL: url, placeholderImage: UIImage(named: "RS_Logo_BLS_640x300.png"))
                cell.lblArtistName.text = featuredItem.featuredTitle
                cell.lblSongName.text = featuredItem.featuredSubtitle
            }
            
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let featuredItem = self.featuredTop[indexPath.row]
        
        // Check if the item is sponsored and print the appropriate message
        if featuredItem.sponsored == true {
            if let url = URL(string: featuredItem.externalLink ?? "https://instagram.com/RadioSrood") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        } else {
            if let presentView = presentView {
                presentView.groupID = featuredItem.featuredSongID
                presentView.homeHeader = .featured
//                if presentView.interstitial != nil {
//                    presentView.interstitial.present(fromRootViewController: presentView)
//                } else {
                    presentView.openMusicPlayerViewController()
//                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 375, height: 250)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
}
