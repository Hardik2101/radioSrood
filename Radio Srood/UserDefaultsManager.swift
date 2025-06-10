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
    
    private init() {}
    
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


struct UserDefaultKeys {
    
    enum CommanKeys: String {
        case isOnBoardDone = "OnBoardDone"
        case LifeTimePurchase = "LifeTimeKey"
        case LatestReciptObject = "latestReciptObject"
        case IsSubscribe = "IsSubscribe"
        case SubscriptionDate = "SubscriptionDate"
        case lastDocumentId = "lastDocumentID"
        case subscriptionID = "subscriptionID"
        case monthlyPrice = "monthlyPrice"
        case yearlyPrice = "yearlyPrice"
        var string: String {
            return self.rawValue
        }
    }
    
}

extension UserDefaults {
    
    // MARK: - Generic Methods
    class func setData<T: Codable>(data: T, forKey key: String) {
        do {
            let jsonData = try JSONEncoder().encode(data)
            UserDefaults.standard.set(jsonData, forKey: key)
            UserDefaults.standard.synchronize()
        } catch let error {
            print(error)
        }
    }
    
    class func getData<T: Codable>(objectType: T.Type, forKey key: String) -> T? {
        guard let result = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        do {
            return try JSONDecoder().decode(objectType, from: result)
        } catch let error {
            print(error)
            return nil
        }
    }
    
    // MARK: - Manage OnBoard Data
    
    class var isOnBoardDone: Bool {
        get {
            return standard.bool(forKey: UserDefaultKeys.CommanKeys.isOnBoardDone.string)
        }
        set {
            standard.set(newValue, forKey: UserDefaultKeys.CommanKeys.isOnBoardDone.string)
            UserDefaults.standard.synchronize()
        }
    }
    
}

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
    
    let defaults = UserDefaults.standard
    
    var b: Bool = false
    b = defaults.bool(forKey: booleanKey)
    
    return b
}

public func setObjectValueToUserDefaults(_ idValue: AnyObject, _ ForKey: String) {
    
    runOnMainThread {
        let defaults = UserDefaults.standard
        defaults.set(idValue, forKey: ForKey)
        defaults.synchronize()
    }
}

public func getObjectValueFromUserDefaults_ForKey(_ strKey: String) -> AnyObject {
    
    let defaults = UserDefaults.standard
    var obj: AnyObject?
    obj = defaults.object(forKey: strKey) as AnyObject
    return obj!
}

public func removeObjectForKey(_ objectKey: String) {
    
    let defaults = UserDefaults.standard
    defaults.removeObject(forKey: objectKey)
    defaults.synchronize()
}


public func runOnMainThread(_ block: @escaping () -> Void) {
    DispatchQueue.main.async(execute: {
        block()
    })
}


public func runOnAfterTime(afterTime: Double, block: @escaping () -> Void) {
    let dispatchTime = DispatchTime.now() + afterTime
    DispatchQueue.main.asyncAfter(deadline: dispatchTime) {
        block()
    }
}


public func DLog<T>(_ message: T, file: String = #file, function: String = #function, lineNumber: Int = #line ) {
    #if DEBUG
    if let text = message as? String {
        
        print("\((file as NSString).lastPathComponent) -> \(function) line: \(lineNumber): \(text)")
    }
    #endif
}
