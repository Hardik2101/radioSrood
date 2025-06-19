//
//  DataHelper.swift
//  GlobalOneV2
//
//  Created by appteve on 22/04/2017.
//  Updated to use Alamofire 5+ best practices
//

import UIKit
import Alamofire
import AVFoundation

class DataHelper: NSObject {
    
    func getRadioData(completion: @escaping (_ resp: NSDictionary) -> Void) {
        let urlString = "\(BASE_BACKEND_URL)\(ENDPOINT_GET_RADIODETAIL)0\(API_KEY_PROV)\(API_KEY)"
        let headers: HTTPHeaders = ["X-API-KEY": API_KEY]

        AF.request(BASE_BACKEND_URL, method: .get, headers: headers).responseData { response in
            switch response.result {
            case .success(let data):
                if let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any],
                   let firstItem = array?.first as? [String: Any] {
                    completion(firstItem as NSDictionary)
                } else {
                    print("Unexpected data format")
                    completion([:])
                }
            case .failure(let error):
                print("Request failed: \(error)")
                completion([:])
            }
        }
    }

    func getTimelineData(completion: @escaping (_ resp: NSArray) -> Void) {
        let url = "\(BASE_BACKEND_URL)\(ENDPOINT_TV)\(API_KEY_PROV)\(API_KEY)"
        let headers: HTTPHeaders = ["X-API-KEY": API_KEY]

        AF.request(url, method: .get, headers: headers).responseData { response in
            switch response.result {
            case .success(let data):
                if let array = try? JSONSerialization.jsonObject(with: data, options: []) as? NSArray {
                    completion(array ?? [])
                } else {
                    print("Data is not an array")
                    completion([])
                }
            case .failure(let error):
                print("Request failed: \(error)")
                completion([])
            }
        }
    }

    func getNewsData(completion: @escaping (_ resp: NSArray) -> Void) {
        let url = "\(BASE_BACKEND_URL)\(ENDPOINT_NEWS)\(API_KEY_PROV)\(API_KEY)"
        let headers: HTTPHeaders = ["X-API-KEY": API_KEY]

        AF.request(url, method: .get, headers: headers).responseData { response in
            switch response.result {
            case .success(let data):
                if let array = try? JSONSerialization.jsonObject(with: data, options: []) as? NSArray {
                    completion(array ?? [])
                } else {
                    completion([])
                }
            case .failure(let error):
                print("Request failed: \(error)")
                completion([])
            }
        }
    }

    func gePodcastData(completion: @escaping (_ resp: NSArray) -> Void) {
        let url = "\(BASE_BACKEND_URL)\(ENDPOINT_PODCAST)\(API_KEY_PROV)\(API_KEY)"
        let headers: HTTPHeaders = ["X-API-KEY": API_KEY]

        AF.request(url, method: .get, headers: headers).responseData { response in
            switch response.result {
            case .success(let data):
                if let array = try? JSONSerialization.jsonObject(with: data, options: []) as? NSArray {
                    completion(array ?? [])
                } else {
                    completion([])
                }
            case .failure(let error):
                print("Request failed: \(error)")
                completion([])
            }
        }
    }

    func getRecentListData(completion: @escaping (_ resp: NSDictionary) -> Void) {
        AF.request(recentListURL).responseData { response in
            switch response.result {
            case .success(let data):
                if let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                    completion(dict ?? [:])
                } else {
                    completion([:])
                }
            case .failure(let error):
                print("Request failed: \(error)")
                completion([:])
            }
        }
    }

    func getCurrentLyricData(completion: @escaping (_ resp: NSDictionary) -> Void) {
        AF.request(currentLyricURL).responseData { response in
            switch response.result {
            case .success(let data):
                if let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                    completion(dict ?? [:])
                } else {
                    completion([:])
                }
            case .failure(let error):
                print("Request failed: \(error)")
                completion([:])
            }
        }
    }

    func getCurrentLyricDataInModle(completion: @escaping (_ resp: CurrentLyricDataModle?) -> Void) {
        AF.request(currentLyricURL).responseDecodable(of: CurrentLyricDataModle.self) { response in
            completion(response.value)
        }
    }

    func getRedioHomeData(completion: @escaping (_ resp: HomeMusicModles?) -> Void) {
        AF.request(redioHomeURL).responseDecodable(of: HomeMusicModles.self) { response in
            completion(response.value)
        }
    }
    
    func getRecentlyAddedData(completion: @escaping (_ resp: RecentlyAddedModel?) -> Void) {
        AF.request(recentlyAdded).responseDecodable(of: RecentlyAddedModel.self) { response in
            completion(response.value)
        }
    }

    func getRecentlyAddedDataDetailed1(completion: @escaping (_ resp: RecentlyAddedPlaylist?) -> Void) {
        AF.request(recentlyAddedDetailed).responseDecodable(of: RecentlyAddedPlaylist.self) { response in
            completion(response.value)
        }
    }

    
    func getRecentlyAddedDataDetailed(completion: @escaping (_ resp: RecentlyAddedPlaylist?) -> Void) {
        guard let url = URL(string: recentlyAddedDetailed) else {
            completion(nil)
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
        urlRequest.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        urlRequest.setValue("no-cache", forHTTPHeaderField: "Pragma")

        AF.request(recentlyAddedDetailed).responseDecodable(of: RecentlyAddedPlaylist.self) { response in
            switch response.result {
            case .success(let value):
                print("✅ Success: \(value)")
                completion(value)
            case .failure(let error):
                print("❌ Decoding failed:", error)
                if let data = response.data, let jsonStr = String(data: data, encoding: .utf8) {
                    print("📦 Raw JSON:\n\(jsonStr)")
                }
            }
        }

    }

    func getTodayTopPicData(completion: @escaping (_ resp: TodayPickModel?) -> Void) {
        AF.request(todayPickURL).responseDecodable(of: TodayPickModel.self) { response in
            completion(response.value)
        }
    }

    func getTodayTopPicDetailed11(completion: @escaping (_ resp: TodayTopPickPlaylistModel?) -> Void) {
        AF.request(todayPickURLDetailed).responseDecodable(of: TodayTopPickPlaylistModel.self) { response in
            completion(response.value)
        }
    }
    
    func getTodayTopPicDetailed(completion: @escaping (_ resp: TodayTopPickPlaylistModel?) -> Void) {
        // Create a URLRequest with a cache-busting policy
        guard let url = URL(string: todayPickURLDetailed) else {
            completion(nil)
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
        urlRequest.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        urlRequest.setValue("no-cache", forHTTPHeaderField: "Pragma")

        AF.request(urlRequest).responseDecodable(of: TodayTopPickPlaylistModel.self) { response in
            switch response.result {
            case .success(let model):
                completion(model)
            case .failure(let error):
                print("❌ Error loading TodayTopPicDetailed:", error.localizedDescription)
                completion(nil)
            }
        }
    }


    func getTodayTopPicDetailed1(completion: @escaping (_ resp: TodayTopPickPlaylistModel?) -> Void) {
        AF.request(todayPickURLDetailed).responseData { response in
            switch response.result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    let decoded = try decoder.decode(TodayTopPickPlaylistModel.self, from: data)
                    completion(decoded)
                } catch {
                    print("❌ Decoding failed:", error)
                    
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, let context):
                            print("🔑 Missing key: '\(key.stringValue)' – \(context.debugDescription)")
                        case .typeMismatch(let type, let context):
                            print("📘 Type mismatch: \(type) – \(context.debugDescription)")
                        case .valueNotFound(let value, let context):
                            print("❗️Value not found: \(value) – \(context.debugDescription)")
                        case .dataCorrupted(let context):
                            print("💥 Data corrupted – \(context.debugDescription)")
                        @unknown default:
                            print("❓ Unknown decoding error")
                        }
                    }

                    print("🔎 Raw JSON:\n", String(data: data, encoding: .utf8) ?? "Unable to display JSON")
                    completion(nil)
                }

            case .failure(let error):
                print("🔥 Network error:", error)
                completion(nil)
            }
        }
    }




    func getFeaturedArtistSponserdDetailsData(completion: @escaping (_ resp: NewFeaturedArtistModles?) -> Void) {
        AF.request(homeSponserURL1).responseDecodable(of: NewFeaturedArtistModles.self) { response in
            completion(response.value)
        }
    }

    func getFeaturedArtistSponserdData(completion: @escaping (_ resp: NewSponserModel?) -> Void) {
        AF.request(homeSponserURL).responseDecodable(of: NewSponserModel.self) { response in
            completion(response.value)
        }
    }

    func getNewReleaseData(completion: @escaping (_ resp: NewReleaseModles?) -> Void) {
        AF.request(newReleaseURL).responseDecodable(of: NewReleaseModles.self) { response in
            completion(response.value)
        }
    }

    func getTrendingPlaylistData(completion: @escaping (_ resp: TrendingPlaylistModles?) -> Void) {
        AF.request(trendingPlaylistURL).responseDecodable(of: TrendingPlaylistModles.self) { response in
            completion(response.value)
        }
    }

    func getPopularPlaylistData(completion: @escaping (_ resp: PopularPlaylistModles?) -> Void) {
        AF.request(popularPlaylistURL).responseDecodable(of: PopularPlaylistModles.self) { response in
            completion(response.value)
        }
    }

    func getPlaylistData(completion: @escaping (_ resp: PlaylistsModles?) -> Void) {
        AF.request(playlistURL).responseDecodable(of: PlaylistsModles.self) { response in
            completion(response.value)
        }
    }

    func getFeaturedArtistData(completion: @escaping (_ resp: FeaturedArtistModles?) -> Void) {
        AF.request(featuredArtistURL).responseDecodable(of: FeaturedArtistModles.self) { response in
            completion(response.value)
        }
    }

    func getFeaturedRadioData(completion: @escaping (_ resp: RadioModel?) -> Void) {
        AF.request(featuredRadio).responseDecodable(of: RadioModel.self) { response in
            completion(response.value)
        }
    }

    func fetchMp3(completion: @escaping (_ resp: [PodcastObject]) -> Void) {
        var object = [PodcastObject]()
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: []).sorted(by: {
                let dateOfFirst = try $0.resourceValues(forKeys:[.contentModificationDateKey]).contentModificationDate
                let dateOfSecond = try $1.resourceValues(forKeys:[.contentModificationDateKey]).contentModificationDate
                return dateOfFirst?.compare(dateOfSecond ?? Date()) == .orderedDescending
            })
            let mp3Files = directoryContents.filter { $0.pathExtension == "mp3" }
            for file in mp3Files {
                let metadataList = AVAsset(url: file).metadata
                var trackTitle = ""
                var artistName = ""
                var image: UIImage?
                for item in metadataList {
                    guard let key = item.commonKey?.rawValue, let value = item.value else { continue }
                    switch key {
                    case "title": trackTitle = value as? String ?? ""
                    case "artist": artistName = value as? String ?? ""
                    case "artwork" where value is Data:
                        if let data = value as? Data {
                            image = UIImage(data: data)
                        }
                    default: break
                    }
                }
                let imageUrl = URL(string: UserDefaults.standard.string(forKey: file.deletingPathExtension().lastPathComponent) ?? "")
                object.append(PodcastObject(file: file, trackName: trackTitle, artistName: artistName, image: image, imageURL: imageUrl))
            }
            completion(object)
        } catch {
            print(error.localizedDescription)
        }
    }

    func removeFile(fileURL: NSURL, error: NSErrorPointer) {
        do {
            try FileManager.default.removeItem(at: fileURL as URL)
        } catch let err as NSError {
            error?.pointee = err
        }
    }

    func downloadImage(withURL url: URL, completion: @escaping (UIImage?) -> Void) {
        let placeholderImage = UIImage(named: "Lav_Radio_Logo.png")
        AF.request(url).responseData { response in
            switch response.result {
            case .success(let data):
                completion(UIImage(data: data) ?? placeholderImage)
            case .failure:
                completion(placeholderImage)
            }
        }
    }
}//
