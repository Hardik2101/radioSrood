//
//  SmartMixBuilder.swift
//  Radio Srood
//

import Foundation
import UIKit

struct SmartMixPlaylist {
    var title: String
    let subtitle: String
    let artists: [ArtistProfileSummary]
    var tracks: [Track]

    var songCountText: String {
        let count = tracks.count
        let songs = count == 1 ? "1 song" : "\(count) songs"
        let minutes = max(count, 1) * 3 + (count / 2)
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(songs) • \(hours) hr \(mins) min"
        }
        return "\(songs) • \(mins) min"
    }

    var artistPhotoURLs: [String] {
        artists.prefix(4).map { $0.artistPhoto }
    }
}

enum SmartMixBuilder {
    static let targetTrackCount = 50
    static let previewArtistCount = 12

    static func mixTitle(for artists: [ArtistProfileSummary]) -> String {
        let names = artists.map { firstName(from: $0.artist) }
        guard !names.isEmpty else { return "Smart Mix" }
        if names.count == 1 { return names[0] }
        if names.count == 2 { return "\(names[0]) & \(names[1])" }
        let head = names.dropLast().joined(separator: ", ")
        return "\(head) & \(names.last!)"
    }

    static func mixSubtitle(for artists: [ArtistProfileSummary]) -> String {
        let names = artists.map { $0.artist }
        guard !names.isEmpty else { return "Personalized mix" }
        if names.count == 1 {
            return "Personalized mix featuring \(names[0])"
        }
        if names.count == 2 {
            return "Personalized mix featuring \(names[0]), \(names[1])"
        }
        let head = names.dropLast().joined(separator: ", ")
        return "Personalized mix featuring \(head), \(names.last!)"
    }

    static func buildPlaylist(
        artists: [ArtistProfileSummary],
        completion: @escaping (SmartMixPlaylist?) -> Void
    ) {
        guard !artists.isEmpty else {
            completion(nil)
            return
        }

        let group = DispatchGroup()
        var artistTracks: [[Track]] = Array(repeating: [], count: artists.count)
        let lock = NSLock()

        for (index, artist) in artists.enumerated() {
            group.enter()
            DataHelper.getArtistProfilePage(artistID: artist.artistid) { page in
                defer { group.leave() }
                guard let page else { return }
                let pool = preferredTracks(from: page)
                lock.lock()
                artistTracks[index] = pool
                lock.unlock()
            }
        }

        group.notify(queue: .global(qos: .userInitiated)) {
            let mixed = interleave(artistTracks, limit: targetTrackCount)
            guard !mixed.isEmpty else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let playlist = SmartMixPlaylist(
                title: mixTitle(for: artists),
                subtitle: mixSubtitle(for: artists),
                artists: artists,
                tracks: mixed
            )
            DispatchQueue.main.async { completion(playlist) }
        }
    }

    private static func preferredTracks(from page: ArtistProfilePage) -> [Track] {
        var ordered: [Track] = []
        var seen = Set<Int>()

        func append(_ tracks: [Track]?) {
            guard let tracks else { return }
            for track in tracks {
                if let id = track.trackid {
                    guard !seen.contains(id) else { continue }
                    seen.insert(id)
                }
                ordered.append(track)
            }
        }

        for section in page.sections {
            switch section.key {
            case "artist_top_tracks", "artist_trending_tracks", "artist_recent_tracks", "artist_featured_tracks":
                append(section.tracks)
            default:
                break
            }
        }

        if ordered.count < targetTrackCount {
            append(page.playbackTracks)
        }

        return ordered
    }

    private static func interleave(_ pools: [[Track]], limit: Int) -> [Track] {
        var result: [Track] = []
        var seen = Set<Int>()
        var indices = Array(repeating: 0, count: pools.count)
        var madeProgress = true

        while result.count < limit && madeProgress {
            madeProgress = false
            for poolIndex in pools.indices {
                guard result.count < limit else { break }
                let pool = pools[poolIndex]
                var cursor = indices[poolIndex]
                while cursor < pool.count {
                    let track = pool[cursor]
                    cursor += 1
                    if let id = track.trackid {
                        if seen.contains(id) { continue }
                        seen.insert(id)
                    }
                    result.append(track)
                    madeProgress = true
                    break
                }
                indices[poolIndex] = cursor
            }
        }

        return result
    }

    private static func firstName(from fullName: String) -> String {
        fullName.split(separator: " ").first.map(String.init) ?? fullName
    }

    static func collageImage(from urls: [String], size: CGFloat, completion: @escaping (UIImage?) -> Void) {
        let photos = Array(urls.prefix(4))
        guard !photos.isEmpty else {
            completion(UIImage(named: "Lav_Radio_Logo.png"))
            return
        }

        let group = DispatchGroup()
        var images: [UIImage?] = Array(repeating: nil, count: photos.count)

        for (index, urlString) in photos.enumerated() {
            guard let url = URL(string: urlString) else { continue }
            group.enter()
            URLSession.shared.dataTask(with: url) { data, _, _ in
                defer { group.leave() }
                if let data, let image = UIImage(data: data) {
                    images[index] = image
                }
            }.resume()
        }

        group.notify(queue: .main) {
            let loaded = images.compactMap { $0 }
            guard !loaded.isEmpty else {
                completion(UIImage(named: "Lav_Radio_Logo.png"))
                return
            }
            completion(renderCollage(images: loaded, size: size))
        }
    }

    private static func renderCollage(images: [UIImage], size: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { context in
            let count = min(images.count, 4)
            let frames: [CGRect]
            switch count {
            case 1:
                frames = [CGRect(x: 0, y: 0, width: size, height: size)]
            case 2:
                let half = size / 2
                frames = [
                    CGRect(x: 0, y: 0, width: half, height: size),
                    CGRect(x: half, y: 0, width: half, height: size)
                ]
            case 3:
                let half = size / 2
                frames = [
                    CGRect(x: 0, y: 0, width: half, height: size),
                    CGRect(x: half, y: 0, width: half, height: half),
                    CGRect(x: half, y: half, width: half, height: half)
                ]
            default:
                let half = size / 2
                frames = [
                    CGRect(x: 0, y: 0, width: half, height: half),
                    CGRect(x: half, y: 0, width: half, height: half),
                    CGRect(x: 0, y: half, width: half, height: half),
                    CGRect(x: half, y: half, width: half, height: half)
                ]
            }

            for index in 0..<frames.count {
                drawAspectFill(images[index], in: frames[index], context: context.cgContext)
            }
        }
    }

    /// Draws an image clipped to `rect` while preserving aspect ratio (no stretch).
    private static func drawAspectFill(_ image: UIImage, in rect: CGRect, context: CGContext) {
        context.saveGState()
        context.addRect(rect)
        context.clip()

        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else {
            context.restoreGState()
            return
        }

        let widthRatio = rect.width / imageSize.width
        let heightRatio = rect.height / imageSize.height
        let scale = max(widthRatio, heightRatio)
        let drawSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let drawRect = CGRect(
            x: rect.midX - drawSize.width / 2,
            y: rect.midY - drawSize.height / 2,
            width: drawSize.width,
            height: drawSize.height
        )
        image.draw(in: drawRect)
        context.restoreGState()
    }
}
