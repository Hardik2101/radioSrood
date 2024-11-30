//
//  BrowseRadioCollectionCell.swift
//  Radio Srood
//
//  Created by Hardik on 18/10/24.
//  Copyright © 2024 Radio Srood Inc. All rights reserved.
//

import UIKit

class BrowseRadioCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var vwContaint: UIView!
    @IBOutlet weak var imgRadio: UIImageView!
    @IBOutlet weak var lblRadio: UILabel!
    
    var radioData: RadioModelData? {
        didSet {
            if let newRelease = radioData {
                if let url = URL(string: newRelease.radioImage) {
                    imgRadio.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                }
                lblRadio.text = newRelease.radioTitle
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

}
