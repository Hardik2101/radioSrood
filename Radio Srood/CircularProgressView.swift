//
//  CircularProgressView.swift
//  Radio Srood
//
//  Created by Hardik on 25/06/25.
//  Copyright © 2025 Radio Srood Inc. All rights reserved.
//

import UIKit

class CircularProgressView: UIView {
    
    private var progressLayer = CAShapeLayer()
    private var backgroundMask = CAShapeLayer()
    private var checkmarkImageView: UIImageView!
    
    var lineWidth: CGFloat = 6 {
        didSet {
            progressLayer.lineWidth = lineWidth
            backgroundMask.lineWidth = lineWidth
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    private func setupView() {
        let circularPath = UIBezierPath(ovalIn: self.bounds.insetBy(dx: 4, dy: 4))
        
        // Background mask
        backgroundMask.path = circularPath.cgPath
        backgroundMask.strokeColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
        backgroundMask.fillColor = UIColor.clear.cgColor
        backgroundMask.lineWidth = lineWidth
        layer.addSublayer(backgroundMask)
        
        // Progress layer
        progressLayer.path = circularPath.cgPath
        progressLayer.strokeColor = UIColor.systemGreen.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.strokeEnd = 0
        progressLayer.lineCap = .round
        layer.addSublayer(progressLayer)
        
        // Checkmark image view
        checkmarkImageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkmarkImageView.tintColor = .systemGreen
        checkmarkImageView.contentMode = .scaleAspectFit
        checkmarkImageView.isHidden = true
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(checkmarkImageView)

        NSLayoutConstraint.activate([
            checkmarkImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            checkmarkImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 36),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    func setProgress(_ progress: Float) {
        DispatchQueue.main.async {
            self.progressLayer.strokeEnd = CGFloat(progress)
            self.checkmarkImageView.isHidden = progress < 1.0
        }
    }

    func resetProgress() {
        setProgress(0)
        checkmarkImageView.isHidden = true
    }
}


