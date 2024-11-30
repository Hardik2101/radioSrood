
import UIKit

struct Common {
    
    static var screenSize: CGSize {
        return UIScreen.main.bounds.size
    }
    static var appName: String {
        return Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? ""
    }
    static var rootViewController: UIViewController? {
        return SroodApplication.shared.window?.rootViewController
    }
    
}
