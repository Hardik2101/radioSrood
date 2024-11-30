//
//  AdsAPIModel.swift
//  Radio Srood
//
//  Created by Hardik Chotaliya on 04/02/24.
//  Copyright © 2024 Appteve. All rights reserved.
//

import UIKit

struct SroodAds: Codable {
    let type: String
    let AdsCampaign: [AdsCampaign]
}

struct AdsCampaign: Codable {
    let CampaignTitle: String?
    let CampaignSubTitle: String?
    let CampaignDate: String?
    let CampaignCover: String?
    let CampaignAudio: String?
    let CampaignLink: String?
    let CampaignLinkTitle: String?
    let CampaignID: Int?
}

class ApiManager {
    
    static func fetchSroodAds(completion: @escaping (Result<SroodAds, Error>) -> Void) {
        guard let url = URL(string: "https://api.srood.stream/static/app/api/SroodAds.json") else {
            let error = NSError(domain: "URLError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            completion(.failure(error))
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                let error = NSError(domain: "DataError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Data is missing"])
                completion(.failure(error))
                return
            }

            do {
                let sroodAds = try JSONDecoder().decode(SroodAds.self, from: data)
                completion(.success(sroodAds))
            } catch let decodingError as DecodingError {
                print("Decoding Error: \(decodingError)")
                completion(.failure(decodingError))
            } catch {
                let genericError = NSError(domain: "DecodingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error decoding JSON"])
                print("Error: \(genericError.localizedDescription)")
                completion(.failure(genericError))
            }
        }

        task.resume()
    }
}
