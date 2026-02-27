//
//  UserDefaultsManager.swift
//  Radio Srood
//
//  Created by Tech on 24/05/2023.
//  Copyright © 2023 Appteve. All rights reserved.
//

import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private let manager = UserDefaults.standard

    // FIX: Serial queue to prevent simultaneous read/write access crash:
    // "Simultaneous accesses to 0x..., but modification requires exclusive access"
    // AVPlayer KVO callbacks fire on background threads, which post notifications
    // that trigger reads/writes to localTracksData — causing the exclusivity crash
    // when the main thread is also accessing the same property at the same time.
    private let queue = DispatchQueue(label: "com.radiosrood.userdefaults.queue")

    private init() {}

    // MARK: - Playlists Data (thread-safe)
    var playListsData: [PlayListModel] {
        set {
            let data = try! NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: false)//archivedData(withRootObject: newValue!)
            manager.set(data, forKey: "PlayLists")
            manager.synchronize()
        }
        get {
            if let data = manager.data(forKey: "PlayLists") {
                let userInfo = try!  NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [PlayListModel] ?? [PlayListModel]()//unarchiveObject(with: data) as! LocationModel
                return userInfo
            }else {
                return [PlayListModel]()
            }
        }
    }
    
    var localTracksData: [SongModel] {
        set {
            let data = try! NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: false)//archivedData(withRootObject: newValue!)
            manager.set(data, forKey: "localTracksData")
            manager.synchronize()
        }
        get {
            if let data = manager.data(forKey: "localTracksData") {
                let userInfo = try!  NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [SongModel] ?? [SongModel]()//unarchiveObject(with: data) as! LocationModel
                return userInfo
            }else {
                return [SongModel]()
            }
        }
    }
}


// MARK: - UserDefaultKeys
struct UserDefaultKeys {

    enum CommanKeys: String {
        case isOnBoardDone      = "OnBoardDone"
        case LifeTimePurchase   = "LifeTimeKey"
        case LatestReciptObject = "latestReciptObject"
        case IsSubscribe        = "IsSubscribe"
        case SubscriptionDate   = "SubscriptionDate"
        case lastDocumentId     = "lastDocumentID"
        case subscriptionID     = "subscriptionID"
        case monthlyPrice       = "monthlyPrice"
        case yearlyPrice        = "yearlyPrice"

        var string: String { return self.rawValue }
    }
}


// MARK: - UserDefaults Extension
extension UserDefaults {

    // MARK: Generic Codable Methods
    class func setData<T: Codable>(data: T, forKey key: String) {
        do {
            let jsonData = try JSONEncoder().encode(data)
            UserDefaults.standard.set(jsonData, forKey: key)
            UserDefaults.standard.synchronize()
        } catch {
            print(error)
        }
    }

    class func getData<T: Codable>(objectType: T.Type, forKey key: String) -> T? {
        guard let result = UserDefaults.standard.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(objectType, from: result)
        } catch {
            print(error)
            return nil
        }
    }

    // MARK: OnBoard
    class var isOnBoardDone: Bool {
        get { return standard.bool(forKey: UserDefaultKeys.CommanKeys.isOnBoardDone.string) }
        set {
            standard.set(newValue, forKey: UserDefaultKeys.CommanKeys.isOnBoardDone.string)
            UserDefaults.standard.synchronize()
        }
    }
}


// MARK: - Global Helpers

public func setIntegerValueToUserDefaults(_ integerValue: Int, _ ForKey: String) {
    UserDefaults.standard.set(integerValue, forKey: ForKey)
    UserDefaults.standard.synchronize()
}

public func getIntegerValueFromUserDefaults(_ integerKey: String) -> Int {
    return UserDefaults.standard.integer(forKey: integerKey)
}

public func setBooleanValueToUserDefaults(_ booleanValue: Bool, _ ForKey: String) {
    runOnMainThread {
        let defaults = UserDefaults.standard
        defaults.set(booleanValue, forKey: ForKey)
        defaults.synchronize()
    }
}

public func getBooleanValueFromUserDefaults_ForKey(_ booleanKey: String) -> Bool {
    return UserDefaults.standard.bool(forKey: booleanKey)
}

public func setObjectValueToUserDefaults(_ idValue: AnyObject, _ ForKey: String) {
    runOnMainThread {
        let defaults = UserDefaults.standard
        defaults.set(idValue, forKey: ForKey)
        defaults.synchronize()
    }
}

public func getObjectValueFromUserDefaults_ForKey(_ strKey: String) -> AnyObject {
    return UserDefaults.standard.object(forKey: strKey) as AnyObject
}

public func removeObjectForKey(_ objectKey: String) {
    let defaults = UserDefaults.standard
    defaults.removeObject(forKey: objectKey)
    defaults.synchronize()
}

public func runOnMainThread(_ block: @escaping () -> Void) {
    DispatchQueue.main.async { block() }
}

public func runOnAfterTime(afterTime: Double, block: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + afterTime) { block() }
}

public func DLog<T>(_ message: T, file: String = #file, function: String = #function, lineNumber: Int = #line) {
    #if DEBUG
    if let text = message as? String {
        print("\((file as NSString).lastPathComponent) -> \(function) line: \(lineNumber): \(text)")
    }
    #endif
}
