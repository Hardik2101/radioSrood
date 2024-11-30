//
//  Date + Extension.swift
//  Radio Srood
//
//  Created by Hardik Chotaliya on 20/12/23.
//  Copyright © 2023 Appteve. All rights reserved.
//

import UIKit

extension Date {
    func isEqualTo(_ date: Date) -> Bool {
        return self == date
    }
    
    func isGreaterThan(_ date: Date) -> Bool {
        return self > date
    }
    
    func isSmallerThan(_ date: Date) -> Bool {
        return self < date
    }
}


