//
//  BrowseRadioTableCell.swift
//  Radio Srood
//
//  Created by Hardik on 18/10/24.
//  Copyright © 2024 Radio Srood Inc. All rights reserved.
//

import UIKit

class BrowseRadioTableCell: UITableViewCell {
    @IBOutlet weak var collectionRadio: UICollectionView!
    
    var radioModel: [RadioModelData] = []
    var presentViewBrowse: BrowseTabVC?

    override func awakeFromNib() {
        super.awakeFromNib()
        collectionRadio.delegate = self
        collectionRadio.dataSource = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func reloadCollectionView() {
        collectionRadio.reloadData()
    }
}


//MARK: - UICollectionView Delegate and DataSource
extension BrowseRadioTableCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return radioModel.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.registerAndGet(BrowseRadioCollectionCell.self, indexPath: indexPath) {
            cell.radioData = self.radioModel[indexPath.row]
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        presentViewBrowse?.onClickRadio(at: indexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let cellSpace = (collectionViewLayout as? UICollectionViewFlowLayout)?.minimumInteritemSpacing ?? 0
//        let leftInset = (collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset.left ?? 0
//        let rightInset = (collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset.right ?? 0
//        let space = cellSpace * 2
//        let totalInset = leftInset + rightInset + space
//        let width = (Common.screenSize.width - totalInset) / 3
//        let height = width + 30
//        return CGSize(width: width, height: height)
        
        return CGSize(width: 150, height: 175)
    }
}
