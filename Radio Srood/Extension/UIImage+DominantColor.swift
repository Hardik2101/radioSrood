//
//  UIImage+DominantColor.swift
//  Radio Srood
//

import UIKit

extension UIImage {
    /// Picks a vibrant tone from the artwork for playlist-style gradient headers.
    func playlistGradientColor() -> UIColor {
        guard let cgImage else {
            return UIColor(white: 0.14, alpha: 1)
        }

        let sampleSize = 25
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * sampleSize
        var pixelData = [UInt8](repeating: 0, count: sampleSize * bytesPerRow)

        guard let context = CGContext(
            data: &pixelData,
            width: sampleSize,
            height: sampleSize,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return UIColor(white: 0.14, alpha: 1)
        }

        context.interpolationQuality = .low
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: sampleSize, height: sampleSize))

        var redTotal: CGFloat = 0
        var greenTotal: CGFloat = 0
        var blueTotal: CGFloat = 0
        var weightTotal: CGFloat = 0

        for offset in stride(from: 0, to: pixelData.count, by: bytesPerPixel) {
            let alpha = CGFloat(pixelData[offset + 3]) / 255
            guard alpha > 0.2 else { continue }

            let red = CGFloat(pixelData[offset]) / 255
            let green = CGFloat(pixelData[offset + 1]) / 255
            let blue = CGFloat(pixelData[offset + 2]) / 255

            var hue: CGFloat = 0
            var saturation: CGFloat = 0
            var brightness: CGFloat = 0
            UIColor(red: red, green: green, blue: blue, alpha: 1)
                .getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)

            let weight = max(saturation, 0.12) * brightness
            redTotal += red * weight
            greenTotal += green * weight
            blueTotal += blue * weight
            weightTotal += weight
        }

        guard weightTotal > 0 else {
            return UIColor(white: 0.14, alpha: 1)
        }

        var color = UIColor(
            red: redTotal / weightTotal,
            green: greenTotal / weightTotal,
            blue: blueTotal / weightTotal,
            alpha: 1
        )

        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        saturation = min(saturation * 1.3 + 0.1, 1)
        brightness = min(max(brightness * 0.82, 0.22), 0.62)

        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }
}

extension UIColor {
    func withBrightnessMultiplier(_ multiplier: CGFloat) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return UIColor(hue: hue, saturation: saturation, brightness: min(brightness * multiplier, 1), alpha: alpha)
    }
}
