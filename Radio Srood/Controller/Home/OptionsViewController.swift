//
//  OptionsViewController.swift
//  Radio Srood
//
//  Created by Hardik on 08/07/25.
//  Copyright © 2025 Radio Srood Inc. All rights reserved.
//

import UIKit

class OptionsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        addBlurBackground()
    }
    
    func addBlurBackground() {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.insertSubview(blurView, at: 0)
    }

    
    @IBAction func clickOn_btnAddToQueue(_ sender: UIButton) {
    }
    
    @IBAction func clickOn_btnAddToCollection(_ sender: UIButton) {
    }

    @IBAction func clickOn_btnDownload(_ sender: UIButton) {
    }

    @IBAction func clickOn_btnViewInfo(_ sender: UIButton) {
    }

    @IBAction func clickOn_btnViewLyrics(_ sender: UIButton) {
    }

    @IBAction func clickOn_btnShare(_ sender: UIButton) {
    }
    
    @IBAction func clickOn_btnCancel(_ sender: UIButton) {
        
        self.dismiss(animated: true, completion: nil)
    }


}
