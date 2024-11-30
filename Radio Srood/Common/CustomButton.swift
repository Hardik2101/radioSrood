//
//  CustomButton.swift
//  Radio Srood
//
//  Created by B on 07/11/24.
//  Copyright © 2024 Radio Srood Inc. All rights reserved.
//

import UIKit

public class CustomButton: UIButton {
    var closureFunction: ((CustomButton)->(Void))?
    
    func setFuncFor(event: UIControl.Event, function: @escaping ((CustomButton)->Void)) {
        closureFunction = function
        self.addTarget(self, action: #selector(myFunction), for: event)
    }
    
    @objc func myFunction(_ btn: CustomButton) {
        closureFunction?(btn)
    }
}
