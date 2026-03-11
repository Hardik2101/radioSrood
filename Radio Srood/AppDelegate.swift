import UIKit
import CoreData
import OneSignal
import GoogleMobileAds
import AVKit
import StoreKit
import UserMessagingPlatform
import AppTrackingTransparency

#if DEBUG
let debugDeveloperSkipAds = false
#else
let debugDeveloperSkipAds = false
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    private var splashWindow: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
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
        
        AppOpenAdManager.shared.loadAd()
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        UIApplication.shared.registerUserNotificationSettings(settings)
        
        UIApplication.shared.registerForRemoteNotifications()
        application.registerForRemoteNotifications()
        
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.requestPermission()
        }
        
        AppReview.requestIf(launches: 4)
        requestUserConsent()
        
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.urlCache = nil
        
        // ── GIF Splash ───────────────────────────────────────────────────────
        // Shown in its own UIWindow so it appears on top of everything,
        // no matter when the storyboard root VC finishes loading.
        showSplashWindow()
        performBackgroundInit()
        // ────────────────────────────────────────────────────────────────────
        
        return true
    }
    
    // MARK: - GIF Splash (dedicated UIWindow)
    
    private func showSplashWindow() {
        let splashWin = UIWindow(frame: UIScreen.main.bounds)
        splashWin.windowLevel = UIWindow.Level.alert + 1   // above everything
        splashWin.backgroundColor = .clear
        
        let splash = SplashViewController()
        splash.onReady = { [weak self] in
            self?.dismissSplashWindow()
        }
        
        splashWin.rootViewController = splash
        splashWin.makeKeyAndVisible()
        self.splashWindow = splashWin
    }
    
    private func dismissSplashWindow() {
        guard let splashWin = splashWindow else { return }
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            options: .curveEaseInOut
        ) {
            splashWin.alpha = 0
        } completion: { _ in
            splashWin.isHidden = true
            self.splashWindow = nil
            self.window?.makeKeyAndVisible()   // restore the main app window
        }
    }
    
    /// Runs heavy init in the background while the GIF plays.
    /// Add your real work here and call markAppReady() when done.
    private func performBackgroundInit() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            
            // ── Put your real pre-loading here ────────────────────────────
            // e.g. prefetch station list, warm up image caches, etc.
            // The splash waits for BOTH this call AND the GIF to finish.
            Thread.sleep(forTimeInterval: 0.5)   // ← remove once you have real work
            // ─────────────────────────────────────────────────────────────
            
            DispatchQueue.main.async {
                if let splashVC = self?.splashWindow?.rootViewController as? SplashViewController {
                    splashVC.markAppReady()
                }
            }
        }
    }
    
    // MARK: - UMP Consent
    
    private func requestUserConsent() {
        let parameters = UMPRequestParameters()
        parameters.tagForUnderAgeOfConsent = false
        
        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) { error in
            if let error = error {
                print(error)
                return
            }
            
            let formStatus = UMPConsentInformation.sharedInstance.formStatus
            
            if formStatus == .available {
                UMPConsentForm.load { form, loadError in
                    if let loadError = loadError {
                        print(loadError)
                        return
                    }
                    if let form = form {
                        form.present(from: self.window?.rootViewController ?? UIViewController()) { _ in }
                    }
                }
            }
        }
    }
    
    // MARK: - App Lifecycle
    
    func applicationWillResignActive(_ application: UIApplication) {}
    
    func applicationDidEnterBackground(_ application: UIApplication) {}
    
    func applicationWillEnterForeground(_ application: UIApplication) {}
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        URLCache.shared.removeAllCachedResponses()
        
        // Don't show the app-open ad while the splash is still visible
        guard splashWindow == nil else { return }
        
        let rootViewController = application.windows.first(where: { $0.isKeyWindow })?.rootViewController
        if let rootViewController = rootViewController {
            AppOpenAdManager.shared.showAdIfAvailable(viewController: rootViewController)
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {}
    
    override func remoteControlReceived(with event: UIEvent?) {
        super.remoteControlReceived(with: event)
    }
    
    // MARK: - ATT Permission
    
    func requestPermission() {
        if #available(iOS 15.0, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:    print("Authorized")
                case .denied:        print("Denied")
                case .notDetermined: print("Not Determined")
                case .restricted:    print("Restricted")
                @unknown default:    break
                }
            }
        }
    }
}

///Need to change the bundle id
///Premium version
///lyricsview pods
///version
