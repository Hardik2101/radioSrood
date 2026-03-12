//
//  SkeletonCellTableViewCell.swift
//  Radio Srood
//
//  Created by Hardik on 12/03/26.
//  Copyright © 2026 Radio Srood Inc. All rights reserved.
//

import UIKit

class SkeletonCell: UITableViewCell {

    private var shimmerViews: [UIView] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSkeleton()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSkeleton()
    }

    private func setupSkeleton() {
        backgroundColor = .clear
        selectionStyle = .none

        let screenWidth = UIScreen.main.bounds.width

        // Large block — simulates the collection view
        addShimmerView(frame: CGRect(x: 15, y: 10, width: screenWidth - 30, height: 130))

        // Three label blocks below
        let itemWidth: CGFloat = (screenWidth - 50) / 3
        for i in 0..<3 {
            let x = 15 + CGFloat(i) * (itemWidth + 10)
            addShimmerView(frame: CGRect(x: x, y: 152, width: itemWidth, height: 10))
        }
    }

    private func addShimmerView(frame: CGRect) {
        // Dark base
        let base = UIView(frame: frame)
        base.backgroundColor = UIColor.white.withAlphaComponent(0.07)
        base.layer.cornerRadius = 6
        base.clipsToBounds = true
        contentView.addSubview(base)
        shimmerViews.append(base)

        // Shimmer highlight — starts fully off-screen to the LEFT
        let shimmer = UIView(frame: CGRect(x: -frame.width, y: 0, width: frame.width * 0.6, height: frame.height))
        shimmer.backgroundColor = .clear

        // White gradient on the shimmer view itself
        let gradient = CAGradientLayer()
        gradient.frame = shimmer.bounds
        gradient.colors = [
            UIColor.clear.cgColor,
            UIColor.white.withAlphaComponent(0.25).cgColor,
            UIColor.clear.cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        shimmer.layer.addSublayer(gradient)
        base.addSubview(shimmer)

        // Animate the shimmer view sliding from left → right
        let totalTravel = frame.width + shimmer.frame.width  // full slide distance
        let animation = CABasicAnimation(keyPath: "position.x")
        animation.fromValue = -shimmer.frame.width / 2          // starts off left edge
        animation.toValue = frame.width + shimmer.frame.width / 2  // ends off right edge
        animation.duration = 1.3
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        // Stagger each view slightly so they don't all flash in sync
        animation.beginTime = CACurrentMediaTime() + Double(shimmerViews.count) * 0.08
        shimmer.layer.add(animation, forKey: "shimmerSlide")

        _ = totalTravel // suppress warning
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // Re-trigger animations in case cell was recycled and animations stopped
        for base in shimmerViews {
            if let shimmer = base.subviews.first {
                shimmer.layer.removeAllAnimations()
                let animation = CABasicAnimation(keyPath: "position.x")
                animation.fromValue = -shimmer.frame.width / 2
                animation.toValue = base.frame.width + shimmer.frame.width / 2
                animation.duration = 1.3
                animation.repeatCount = .infinity
                animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                shimmer.layer.add(animation, forKey: "shimmerSlide")
            }
        }
    }
}
