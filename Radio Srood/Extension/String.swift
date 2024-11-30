//
//  String.swift
//  Radio Srood
//
//  Created by BrainX IOS Dev on 5/1/23.
//  Copyright © 2023 Appteve. All rights reserved.
//

import Foundation
import UIKit

extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public extension String {
    var length: Int {
        return self.count
    }
    
}
