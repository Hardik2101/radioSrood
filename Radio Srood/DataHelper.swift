//
//  DataHelper.swift
//  GlobalOneV2
//
//  Created by appteve on 22/04/2017.
//  Copyright © 2017 Appteve. All rights reserved.
//

import UIKit
import Alamofire
import AVFoundation

class DataHelper: NSObject {
    
    func getRadioData ( completion:@escaping( _ resp:NSDictionary) -> Void){
        
        let url = String(format:"%@%@%@%@%@",BASE_BACKEND_URL,ENDPOINT_GET_RADIODETAIL,"0",API_KEY_PROV,API_KEY)
        Alamofire.request( url, method: .get, parameters: ["X-API-KEY":API_KEY])
            .responseJSON { response in
                
                print("LLLLL - - - ", response)
                switch response.result {
                case .success( _):
                    let data  = response.result.value as! NSArray
                    let dataradio = data[0] as! NSDictionary
                    completion (dataradio)
                case .failure(let error):
                    print("Request failed with error: \(error)")
                    completion ([:])
                }
            }
    }
    
    func getTimelineData ( completion:@escaping( _ resp: NSArray) -> Void){
        
        let url = String(format:"%@%@%@%@",BASE_BACKEND_URL,ENDPOINT_TV ,API_KEY_PROV,API_KEY)
        Alamofire.request( url, method: .get, parameters: ["X-API-KEY":API_KEY])
            .responseJSON { response in
                switch response.result {
                case .success( _):
                    let data  = response.result.value as! NSArray
                    completion (data)
                case .failure(let error):
                    print("Request failed with error: \(error)")
                    completion ([])
                }
            }
    }
    
    func getNewsData( completion:@escaping( _ resp: NSArray) -> Void){
        
        let url = String(format:"%@%@%@%@",BASE_BACKEND_URL,ENDPOINT_NEWS,API_KEY_PROV,API_KEY)
        Alamofire.request( url, method: .get, parameters: ["X-API-KEY":API_KEY])
            .responseJSON { response in
                print("LLLLL - - - ", response)
                switch response.result {
                case .success( _):
                    let data  = response.result.value as! NSArray
                    completion (data)
                case .failure(let error):
                    print("Request failed with error: \(error)")
                    completion ([])
                }
            }
    }
    
    func gePodcastData( completion:@escaping( _ resp: NSArray) -> Void){
        
        let url = String(format:"%@%@%@%@",BASE_BACKEND_URL,ENDPOINT_PODCAST,API_KEY_PROV,API_KEY)
        Alamofire.request(url, method: .get, parameters: ["X-API-KEY":API_KEY])
            .responseJSON { response in
                switch response.result {
                case .success( _):
                    let data  = response.result.value as! NSArray
                    completion (data)
                case .failure(let error):
                    print("Request failed with error: \(error)")
                    completion ([])
                }
            }
    }
    
    func getRecentListData(completion:@escaping(_ resp: NSDictionary) -> Void){
        Alamofire.request(recentListURL, method: .get, parameters: [:])
            .responseJSON { response in
                switch response.result {
                case .success( _):
                    completion(response.result.value as! NSDictionary)
                case .failure(let error):
                    print("Request failed with error: \(error)")
                    completion([:])
                }
            }
    }
    
    func getCurrentLyricData(completion:@escaping(_ resp: NSDictionary) -> Void){
        Alamofire.request(currentLyricURL, method: .get, parameters: [:])
            .responseJSON { response in
                switch response.result {
                case .success( _):
                    completion(response.result.value as! NSDictionary)
                case .failure(let error):
                    print("Request failed with error: \(error)")
                    completion([:])
                }
            }
    }
    
    func getCurrentLyricDataInModle(completion:@escaping(_ resp: CurrentLyricDataModle?) -> Void) {
        Alamofire.request(currentLyricURL, method: .get, parameters: [:])
            .responseData { response in
                switch response.result {
                case .success( _):
                    if let data = response.result.value, let resp = try? JSONDecoder().decode(CurrentLyricDataModle.self, from: data) {
                        completion(resp)
                    } else {
                        completion(nil)
                    }
                case .failure(let error):
                    print("Request failed with error: \(error)")
                    completion(nil)
                }
            }
    }
    
    func getRedioHomeData(completion: @escaping(_ resp: HomeMusicModles?) -> Void) {
        Alamofire.request(redioHomeURL, method: .get, parameters: [:])
            .responseData { response in
                switch response.result {
                case .success( _):
                    if let data = response.result.value, let resp = try? JSONDecoder().decode(HomeMusicModles.self, from: data) {
                        completion(resp)
                    } else {
                        completion(nil)
                    }
                case .failure(let error):
                    print("Request failed with error: \(error)")
                    completion(nil)
                }
            }
    }
    func getFeaturedArtistSponserdDetailsData(completion: @escaping(_ resp: NewFeaturedArtistModles?) -> Void) {
        Alamofire.request(homeSponserURL1, method: .get, parameters: [:])
            .responseData { response in
                switch response.result {
                case .success( _):
                    if let data = response.result.value, let resp = try? JSONDecoder().decode(NewFeaturedArtistModles.self, from: data) {
                        completion(resp)
                    } else {
                        completion(nil)
                    }
                case .failure(let error):
                    print("Request failed with error: \(error)")
                    completion(nil)
                }
            }
    }
    func getFeaturedArtistSponserdData(completion: @escaping(_ resp: NewSponserModel?) -> Void) {
        Alamofire.request(homeSponserURL, method: .get, parameters: [:])
            .responseData { response in
                switch response.result {
                case .success( _):
                    if let data = response.result.value, let resp = try? JSONDecoder().decode(NewSponserModel.self, from: data) {
                        completion(resp)
                    } else {
                        completion(nil)
                    }
                case .failure(let error):
                    print("Request failed with error: \(error)")
                    completion(nil)
                }
            }
    }
    func getNewReleaseData(completion: @escaping(_ resp: NewReleaseModles?) -> Void) {
        Alamofire.request(newReleaseURL, method: .get, parameters: [:])
            .responseData { response in
                switch response.result {
                case .success( _):
                    if let data = response.result.value, let resp = try? JSONDecoder().decode(NewReleaseModles.self, from: data) {
                        completion(resp)
                    } else {
                        completion(nil)
                    }
                case .failure(let error):
                    print("Request failed with error: \(error)")
                    completion(nil)
                }
            }
    }
    
    func getTrendingPlaylistData(completion: @escaping(_ resp: TrendingPlaylistModles?) -> Void) {
        Alamofire.request(trendingPlaylistURL, method: .get, parameters: [:])
            .responseData { response in
                switch response.result {
                case .success( _):
                    if let data = response.result.value, let resp = try? JSONDecoder().decode(TrendingPlaylistModles.self, from: data) {
                        completion(resp)
                    } else {
                        completion(nil)
                    }
                case .failure(let error):
                    print("Request failed with error: \(error)")
                    completion(nil)
                }
            }
    }
    
    func getPopularPlaylistData(completion: @escaping(_ resp: PopularPlaylistModles?) -> Void) {
        Alamofire.request(popularPlaylistURL, method: .get, parameters: [:])
            .responseData { response in
                switch response.result {
                case .success( _):
                    if let data = response.result.value, let resp = try? JSONDecoder().decode(PopularPlaylistModles.self, from: data) {
                        completion(resp)
                    } else {
                        completion(nil)
                    }
                case .failure(let error):
                    print("Request failed with error: \(error)")
                    completion(nil)
                }
            }
    }
    
    func getPlaylistData(completion: @escaping(_ resp: PlaylistsModles?) -> Void) {
        Alamofire.request(playlistURL, method: .get, parameters: [:])
            .responseData { response in
                switch response.result {
                case .success( _):
                    if let data = response.result.value, let resp = try? JSONDecoder().decode(PlaylistsModles.self, from: data) {
                        completion(resp)
                    } else {
                        completion(nil)
                    }
                case .failure(let error):
                    print("Request failed with error: \(error)")
                    completion(nil)
                }
            }
    }
    
    func getFeaturedArtistData(completion: @escaping(_ resp: FeaturedArtistModles?) -> Void) {
        Alamofire.request(featuredArtistURL, method: .get, parameters: [:])
            .responseData { response in
                switch response.result {
                case .success( _):
                    if let data = response.result.value, let resp = try? JSONDecoder().decode(FeaturedArtistModles.self, from: data) {
                        completion(resp)
                    } else {
                        completion(nil)
                    }
                case .failure(let error):
                    print("Request failed with error: \(error)")
                    completion(nil)
                }
            }
    }
    
    func getFeaturedRadioData(completion: @escaping(_ resp: RadioModel?) -> Void) {
        Alamofire.request(featuredRadio, method: .get, parameters: [:])
            .responseData { response in
                switch response.result {
                case .success( _):
                    if let data = response.result.value, let resp = try? JSONDecoder().decode(RadioModel.self, from: data) {
                        completion(resp)
                    } else {
                        completion(nil)
                    }
                case .failure(let error):
                    print("Request failed with error: \(error)")
                    completion(nil)
                }
            }
    }

    
    
    func fetchMp3(completion: @escaping( _ resp: [PodcastObject]) -> Void){
        var object = [PodcastObject]()
        object.removeAll()
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: []).sorted(by: {
                let dateOfFirst = try $0.promisedItemResourceValues(forKeys:[.contentModificationDateKey]).contentModificationDate
                let dateOfSecond = try $1.promisedItemResourceValues(forKeys:[.contentModificationDateKey]).contentModificationDate
                return dateOfFirst?.compare(dateOfSecond ?? Date()) == .orderedDescending
            })
            let mp3Files = directoryContents.filter{ $0.pathExtension == "mp3" }
            let mp3FileNames = mp3Files.map{ $0.deletingPathExtension().lastPathComponent }
            for i in 0..<mp3Files.count {
                let metadataList = AVAsset(url: mp3Files[i]).metadata
                var trackTitle = ""
                var artistName = ""
                var image: UIImage?
                for item in metadataList {
                    guard let key = item.commonKey?.rawValue, let value = item.value else{
                        continue
                    }
                    switch key {
                    case "title":
                        trackTitle = value as? String ?? mp3FileNames[i]
                    case "artist":
                        artistName = value as? String ?? ""
                    case "artwork" where value is Data:
                        if let data = value as? Data {
                            image = UIImage(data: data)
                        }
                    default:
                        continue
                    }
                }
                var imageUrl : URL?
                imageUrl = URL(string: UserDefaults.standard.string(forKey: mp3FileNames[i]) ?? "")
                object.append(PodcastObject(file: mp3Files[i], trackName: trackTitle, artistName: artistName, image: image , imageURL: imageUrl))
            }
            completion(object)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    func removeFile(fileURL: NSURL, error: NSErrorPointer) {
        do {
            try FileManager.default.removeItem(at: fileURL as URL)
        } catch _ as NSError {
            //  error?.memory = fileError
        }
    }
    
    func downloadImage(withURL url: URL, completion: @escaping (UIImage?) -> Void) {
        let placeholderImage = UIImage(named: "Lav_Radio_Logo.png")
        Alamofire.download(url).responseData { response in
            switch response.result {
            case .success(let data):
                if let image = UIImage(data: data) {
                    completion(image)
                } else {
                    let error = NSError(domain: "InvalidImageData", code: 0, userInfo: nil)
                    completion(placeholderImage)
                }
            case .failure(let error):
                completion(placeholderImage)
            }
        }
    }
}
