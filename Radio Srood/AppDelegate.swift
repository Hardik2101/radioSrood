import UIKit
import CoreData
import OneSignal
import GoogleMobileAds
import AVKit
import StoreKit
import UserMessagingPlatform
import AppTrackingTransparency
//import AppReview//AppReview.requestIf(//https://github.com/mezhevikin/AppReview.git

#if DEBUG
let debugDeveloperSkipAds = false
#else
let debugDeveloperSkipAds = false
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        UserDefaults.standard.removeObject(forKey: "NowPlayData")

        IAPHandler.shared.setProductIds(ids: [
            IAProduct.Product_identifierOneMonth.rawValue,
            IAProduct.Product_identifierYearly.rawValue])
        
        IAPHandler.shared.fetchAvailableProducts { (products) in
            if products.count != 0 {
                IAPHandler.shared.productArray = products
            }
        }
        
        if let exprDate = getObjectValueFromUserDefaults_ForKey(UserDefaultKeys.CommanKeys.SubscriptionDate.string) as? Date {
            if Date().isGreaterThan(exprDate) {
                IAPHandler.shared.receiptValidation()
            } else {
                IAPHandler.shared.receiptValidation()
            }
        } else {
            IAPHandler.shared.receiptValidation()
        }

        OneSignal.initWithLaunchOptions(launchOptions)
        OneSignal.setAppId(ONESIGNAL_APP_KEY)
//       OneSignal.inFocusDisplayType = OSNotificationDisplayType.notification
        
        AppOpenAdManager.shared.loadAd()
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        UIApplication.shared.registerUserNotificationSettings(settings)
        
        UIApplication.shared.registerForRemoteNotifications()
        application.registerForRemoteNotifications()
        
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        // Initialize Google Mobile Ads SDK
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.requestPermission()
        }
        AppReview.requestIf(launches: 4)
        // Initialize UMP SDK and request user consent
        requestUserConsent()
        
        return true
    }

    private func requestUserConsent() {
        // Requesting consent information update
        let parameters = UMPRequestParameters()
        parameters.tagForUnderAgeOfConsent = false
        
        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) { error in
            if let error = error {
                print(error)
                return
            }
            
            // Check the consent status
            let consentStatus = UMPConsentInformation.sharedInstance.consentStatus
            let formStatus = UMPConsentInformation.sharedInstance.formStatus
            
            if formStatus == .available {
                UMPConsentForm.load { form, loadError in
                    if let loadError = loadError {
                        print(loadError)
                        return
                    }
                    
                    if let form = form {
                        form.present(from: self.window?.rootViewController ?? UIViewController()) { dismissError in
                            if let dismissError = dismissError {
                                return
                            }
                            
                        }
                    }
                }
            } else {
                // Directly request ads if no consent form is needed
            }
        }
    }


    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        let rootViewController = application.windows.first(where: { $0.isKeyWindow })?.rootViewController
        if let rootViewController = rootViewController {
            AppOpenAdManager.shared.showAdIfAvailable(viewController: rootViewController)
        }
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
    }

    override func remoteControlReceived(with event: UIEvent?) {
        super.remoteControlReceived(with: event)
        // Handle remote control events
    }
    
    func requestPermission() {
        if #available(iOS 15.0, *) {
            ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
                switch status {
                case .authorized:
                    // Tracking authorization dialog was shown
                    // and we are authorized
                    print("Authorized")
                case .denied:
                    // Tracking authorization dialog was
                    // shown and permission is denied
                    print("Denied")
                case .notDetermined:
                    // Tracking authorization dialog has not been shown
                    print("Not Determined")
                case .restricted:
                    print("Restricted ")
                @unknown default: break
                    
                }
            })
        }
    }
}
