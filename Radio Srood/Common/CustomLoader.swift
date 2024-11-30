//
//  CustomLoader.swift
//  Radio Srood
//
//  Created by Hardik Chotaliya on 22/12/23.
//  Copyright © 2023 Appteve. All rights reserved.
//

import UIKit

class CustomLoader {
    static let shared = CustomLoader()

    private var loaderView: UIView?

    private init() {}

    func showLoader(in view: UIView) {
        let loaderView = UIView(frame: view.bounds)
        loaderView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        loaderView.tag = 999 // You can use a unique tag to identify the loader view

        let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicator.center = loaderView.center
        activityIndicator.startAnimating()

        loaderView.addSubview(activityIndicator)
        view.addSubview(loaderView)

        self.loaderView = loaderView
    }

    func hideLoader() {
        loaderView?.removeFromSuperview()
        loaderView = nil
    }
}
