//
//  IAPHandler.swift
//  Radio Srood
//
//  Created by Hardik Chotaliya on 20/12/23.
//  Copyright © 2023 Appteve. All rights reserved.
//
///// latest
import Foundation
import UIKit
import StoreKit

enum IAPHandlerAlertType {
    case setProductIds
    case disabled
    case restored
    case purchased
    case notPurchase
    case failPurchase
    
    var message: String {
        switch self {
        case .setProductIds: return "Product ids not set, call setProductIds method!"
        case .disabled: return "Purchases are disabled in your device!"
        case .restored: return "You've successfully restored your purchase!"
        case .purchased: return "You've successfully bought this purchase!"
        case .notPurchase: return "Nothing to restore!"
        case .failPurchase: return "Fail to restore/purchase subscription. Please try again later"
        }
    }
}

#if DEBUG
let verifyReceiptURL = "https://sandbox.itunes.apple.com/verifyReceipt"
#else
let verifyReceiptURL = "https://buy.itunes.apple.com/verifyReceipt"
#endif


enum IAProduct: String {
    case Product_identifierOneMonth  = "com.developer.radiosrood_1month"
    case Product_identifierYearly  = "com.developer.radiosrood_1year"
}

extension Notification.Name {
    static let PurchaseSuccess = Notification.Name("purchaseSuccess")
    static let FetchAds = Notification.Name("fetchAds")
}

class IAPHandler: NSObject {
    
    // MARK: - Shared Object
  
    static let shared = IAPHandler()
    private override init() { }
    
    // MARK: - Properties
    // MARK: - Private
    fileprivate var productIds = [String]()
    fileprivate var productID = ""
    fileprivate var productsRequest = SKProductsRequest()
    fileprivate var fetchProductComplition: (([SKProduct]) -> Void)?
    
    fileprivate var productToPurchase: SKProduct?
    fileprivate var purchaseProductComplition: ((IAPHandlerAlertType, SKProduct?, SKPaymentTransaction?) -> Void)?
    
    typealias RestorationCompletion = () -> Void
    
    // Create a property to hold the completion handler
    var restorationCompletion: RestorationCompletion?
    
    // MARK: - Public
    var isLogEnabled: Bool = true
    var productArray: [SKProduct] = [SKProduct]()
    var navHomeController: UINavigationController?
    var navLeftController: UINavigationController?
    
    private var isRestoredAlertDisplayed = false
    private var isPurchasedAlertDisplayed = false
    
    private var isPurchasing: Bool = false

    // MARK: - Set Product Ids
    func setProductIds(ids: [String]) {
        self.productIds = ids
        DLog("product id fetched=====>\(self.productIds)")
    }
    
    // MARK: - find products
    func findPaymentIndex(productIdentifier: String) -> Int? {
        if self.productArray == nil {
            return nil
        }
        for payment in self.productArray where payment.productIdentifier == productIdentifier {
            return self.productArray.firstIndex(of: payment)
        }
        return nil
    }
    
    // MARK: - MAKE PURCHASE OF A PRODUCT
    func canMakePurchases() -> Bool {  return SKPaymentQueue.canMakePayments()  }
    
    func purchase(product: SKProduct, complition: @escaping ((IAPHandlerAlertType, SKProduct?, SKPaymentTransaction?) -> Void)) {
        self.purchaseProductComplition = complition
        self.productToPurchase = product
        
        if self.canMakePurchases() {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(self)
            SKPaymentQueue.default().add(payment)
            
            DLog("PRODUCT TO PURCHASE: \(product.productIdentifier)")
            productID = product.productIdentifier
        } else {
            CustomLoader.shared.hideLoader()
            //            SVProgressHUD.dismiss {
//                complition(IAPHandlerAlertType.disabled, nil, nil)
//            }
        }
    }
    
    // MARK: - RESTORE PURCHASE
    func restorePurchase(complition: @escaping ((IAPHandlerAlertType, SKProduct?, SKPaymentTransaction?) -> Void)) {
        // SVProgressHUD.show()
        self.purchaseProductComplition = complition
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    // MARK: - FETCH AVAILABLE IAP PRODUCTS
    func fetchAvailableProducts(complition: @escaping (([SKProduct]) -> Void)) {
        self.fetchProductComplition = complition
        // Put here your IAP Products ID's
        if self.productIds.isEmpty {
            DLog("\(IAPHandlerAlertType.setProductIds.message)")
            fatalError(IAPHandlerAlertType.setProductIds.message)
        } else {
            productsRequest = SKProductsRequest(productIdentifiers: Set(self.productIds))
            productsRequest.delegate = self
            productsRequest.start()
        }
    }
    
    // MARK: - Receipt Validation
    
    func receiptValidation() {
        let receiptFileURL = Bundle.main.appStoreReceiptURL
        let receiptData = try? Data(contentsOf: receiptFileURL!, options: NSData.ReadingOptions.alwaysMapped)
        //        let recieptString = receiptData?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        let base64encodedReceipt = receiptData?.base64EncodedString(options: NSData.Base64EncodingOptions.endLineWithCarriageReturn)
        if base64encodedReceipt == nil {
            return
        }
        let jsonDict: [String: AnyObject] = ["receipt-data": base64encodedReceipt! as AnyObject, "password": "bde25ea635e3477692603e4a2c3c073f" as AnyObject]
        do {
            let requestData = try JSONSerialization.data(withJSONObject: jsonDict, options: JSONSerialization.WritingOptions.prettyPrinted)
            let storeURL = URL(string: verifyReceiptURL)!
            var storeRequest = URLRequest(url: storeURL)
            storeRequest.setValue("Application/json", forHTTPHeaderField: "Content-Type")
            storeRequest.httpMethod = "POST"
            storeRequest.httpBody = requestData
            
            let session = URLSession(configuration: URLSessionConfiguration.default)
            let task = session.dataTask(with: storeRequest, completionHandler: { [weak self] (data, _, _) in
                do {
                    runOnMainThread {
                        CustomLoader.shared.hideLoader()
                    }
                    
                    guard let dataResult = data else {
                        return
                    }
                    let jsonResponse = try JSONSerialization.jsonObject(with: dataResult, options: JSONSerialization.ReadingOptions.mutableContainers)
                    DLog(jsonResponse)
                    if let latestReciptObject = self?.getExpirationDateFromResponse(jsonResponse as! NSDictionary) {
                        DLog("\(latestReciptObject)")
                        setObjectValueToUserDefaults(latestReciptObject as AnyObject, UserDefaultKeys.CommanKeys.LatestReciptObject.string)
                        
                        if let expireDate = self?.checkExpireDateInSubcripation(lastReceipt: latestReciptObject) {
                            
                            DLog("CurrentDateTime \(String(describing: Date()))")
                            DLog("isGreaterThan \(String(describing: expireDate))")
                            self?.isRestoredAlertDisplayed = false
                            self?.isPurchasedAlertDisplayed = false
                            // Check purchase pack is expire/cancel Or Not (Expired/Cancel = true )
                            
                            if Date().isGreaterThan(expireDate) {
                                setBooleanValueToUserDefaults(false, UserDefaultKeys.CommanKeys.IsSubscribe.string)
                                removeObjectForKey(UserDefaultKeys.CommanKeys.SubscriptionDate.string)
                                self?.refreshReceipt()
                                
                                // Navigation to Dashboard
//                                DispatchQueue.main.async {
//                                    if UserDefaults.isOnBoardDone {
//                                        let listVC = UIStoryboard.getViewController(with: UIStoryboard.Name.home.rawValue, vcIdentifier: HomeViewController.identifier) as! HomeViewController
//                                        let menuVC = UIStoryboard.getViewController(with: UIStoryboard.Name.home.rawValue, vcIdentifier: LeftMenuVC.identifier) as! LeftMenuVC
//
//                                        let navHomeController = UINavigationController(rootViewController: listVC)
//                                        let navLeftController = UINavigationController(rootViewController: menuVC)
//
//                                        let frostedViewController = REFrostedViewController(contentViewController: navHomeController, menuViewController: navLeftController)
//                                        frostedViewController?.direction = .left
//                                        frostedViewController?.menuViewSize = CGSize(width: SCREEN_WIDTH/1.4, height: SCREEN_HEIGHT)
//                                        frostedViewController?.limitMenuViewSize = true
//
//                                        appInstance.keyWindow?.rootViewController = frostedViewController
//                                        appInstance.keyWindow?.makeKeyAndVisible()
//                                    } else {
//                                        guard let nav = UIStoryboard.getNavigationController(with: UIStoryboard.Name.main.rawValue, navIdentifier: storyboardIdentifier.onBoardNav) else { return }
//                                        appInstance.keyWindow?.rootViewController = nav
//                                        appInstance.keyWindow?.makeKeyAndVisible()
//                                    }
//                                }
                            } else {
                                setObjectValueToUserDefaults(expireDate as AnyObject, UserDefaultKeys.CommanKeys.SubscriptionDate.string)
                                setBooleanValueToUserDefaults(true, UserDefaultKeys.CommanKeys.IsSubscribe.string)
                                DLog("CurrentDateTime \(String(describing: Date()))")
                                DLog("isGreaterThan \(String(describing: expireDate))")
                              
                                let currentDT = expireDate
                                let formatter = DateFormatter()
                                formatter.dateFormat = "yyyy-MM-dd"
                                let result = formatter.string(from: currentDT)
                                
                                // Navigation to Dashboard
                                
//                                DispatchQueue.main.async {
//                                    if UserDefaults.isOnBoardDone {
//                                        let listVC = UIStoryboard.getViewController(with: UIStoryboard.Name.home.rawValue, vcIdentifier: HomeViewController.identifier) as! HomeViewController
//                                        let menuVC = UIStoryboard.getViewController(with: UIStoryboard.Name.home.rawValue, vcIdentifier: LeftMenuVC.identifier) as! LeftMenuVC
//
//                                        let navHomeController = UINavigationController(rootViewController: listVC)
//                                        let navLeftController = UINavigationController(rootViewController: menuVC)
//
//                                        let frostedViewController = REFrostedViewController(contentViewController: navHomeController, menuViewController: navLeftController)
//                                        frostedViewController?.direction = .left
//                                        frostedViewController?.menuViewSize = CGSize(width: SCREEN_WIDTH/1.4, height: SCREEN_HEIGHT)
//                                        frostedViewController?.limitMenuViewSize = true
//
//                                        appInstance.keyWindow?.rootViewController = frostedViewController
//                                        appInstance.keyWindow?.makeKeyAndVisible()
//                                    } else {
//                                        guard let nav = UIStoryboard.getNavigationController(with: UIStoryboard.Name.main.rawValue, navIdentifier: storyboardIdentifier.onBoardNav) else { return }
//                                        appInstance.keyWindow?.rootViewController = nav
//                                        appInstance.keyWindow?.makeKeyAndVisible()
//                                    }
//                                }

                            }
                        }
                    } else {
                        self?.refreshReceipt()
                    }
                } catch let parseError {
                    CustomLoader.shared.hideLoader()
                    DLog("\(parseError)")
                }
            })
            task.resume()
        } catch let parseError {
            CustomLoader.shared.hideLoader()
            DLog("\(parseError)")
        }
    }
    
    // MARK: get expiration date from json
    func getExpirationDateFromResponse(_ jsonResponse: NSDictionary) -> [String: Any] {
        
        if let receiptInfo: NSArray = jsonResponse["latest_receipt_info"] as? NSArray {
            DLog(receiptInfo)
            DLog(receiptInfo[0])
            let lastReceipt = receiptInfo.firstObject as! NSDictionary
            return lastReceipt as! [String: Any]
        } else {
            return [:]
        }
    }
        
    func refreshReceipt() {
        let appReceiptRefreshRequest = SKReceiptRefreshRequest(receiptProperties: nil)
        appReceiptRefreshRequest.delegate = self
        appReceiptRefreshRequest.start()
    }
    
    func checkExpireDateInSubcripation(lastReceipt: [String: Any]) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss VV"
        //        let reciptProductId = lastReceipt["product_id"] as? String ?? ""
        if let expiresDate = lastReceipt["expires_date"] as? String {
            return formatter.date(from: expiresDate)
        }
        
        return nil
    }
    
    // MARK: - Check purchase data or not
    func isGetPurchase() -> Bool {
//        if debugDeveloperSkipAds {
//            return true
//        }
        
        // check monthly subscription
        if getBooleanValueFromUserDefaults_ForKey(UserDefaultKeys.CommanKeys.IsSubscribe.string) {
            // get subscription date from userdefault
            if let subscriptionDate = getObjectValueFromUserDefaults_ForKey(UserDefaultKeys.CommanKeys.SubscriptionDate.string) as? Date {
                // check subscription date greater or not
                DLog("Expiry Subscription Date :  \(subscriptionDate)")
                DLog("Current Date :  \(Date())")
                
                if Date().isGreaterThan(subscriptionDate) {
                    setBooleanValueToUserDefaults(false, UserDefaultKeys.CommanKeys.IsSubscribe.string)
                    removeObjectForKey(UserDefaultKeys.CommanKeys.SubscriptionDate.string)
                    return false
                } else {
                    return true//
                }
            }
            return false
        }
        return false
    }
    
}

// MARK: - Product Request Delegate and Payment Transaction Methods

extension IAPHandler: SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    // REQUEST IAP PRODUCTS
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if !response.products.isEmpty {
            // Products are available, you can use them
            productArray = response.products
            
            if let completion = fetchProductComplition {
                completion(response.products)
            }
        } else {
            // No products available
            DLog("No products available.")
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        // Handle error
        DLog("Products request failed with error: \(error.localizedDescription)")
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        CustomLoader.shared.hideLoader()
        print("queue.transactions.countqueue.transactions.count==", queue.transactions.count)

        if queue.transactions.count == 0 {
            _ = CustomAlertController.alert(title: IAPHandlerAlertType.notPurchase.message)
        } else {
            DLog("show another alert")
        }
        
        SKPaymentQueue.default().remove(self)
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        SKPaymentQueue.default().remove(self)
        CustomLoader.shared.hideLoader()
        
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        _ = CustomAlertController.alert(title: error.localizedDescription)
        DLog("error", file: error.localizedDescription)
        SKPaymentQueue.default().remove(self)
        CustomLoader.shared.hideLoader()
        
    }
    
    // IAP PAYMENT QUEUE
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction: AnyObject in transactions {
            if let trans: SKPaymentTransaction = transaction as? SKPaymentTransaction {
                switch trans.transactionState {
                case .purchased:
                    CustomLoader.shared.hideLoader()
                    
                    DLog("Product purchase done : - \(trans.payment.productIdentifier)")
                    
                    if trans.payment.productIdentifier == IAProduct.Product_identifierOneMonth.rawValue ||
                        trans.payment.productIdentifier == IAProduct.Product_identifierYearly.rawValue {
                        
                        setBooleanValueToUserDefaults(true, UserDefaultKeys.CommanKeys.IsSubscribe.string)
//

                    }
                    
                    if let complition = self.purchaseProductComplition {
                        if !isPurchasedAlertDisplayed {
                            complition(IAPHandlerAlertType.restored, self.productToPurchase, trans)
                            isPurchasedAlertDisplayed = true
                        }

                    }
                    
                    if self.isPurchasing {
                        NotificationCenter.default.post(name: .PurchaseSuccess, object: nil)
                    }
                    
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    receiptValidation()
                    
                    break
                    
                case .failed:
                    CustomLoader.shared.hideLoader()
                    DLog("Product purchase failed")
                    receiptValidation()
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    break
                    
                case .restored:
                    CustomLoader.shared.hideLoader()
                    DLog("Product restored")
                    receiptValidation()
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    
                    if !isRestoredAlertDisplayed {
                    
                        _ = CustomAlertController.alert(title: IAPHandlerAlertType.restored.message, message: "", acceptMessage: "OK") {
                            if let completion = self.restorationCompletion {
                                    completion()
                                }
                        }
                        
                        isRestoredAlertDisplayed = true

                    }
                    break
                    
                case .purchasing:
                    isPurchasing = true
                    break
                    
                case .deferred:
                    break

                default:
                    break
                }
            }
        }
    }
}

