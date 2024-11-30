
import UIKit

class SroodApplication {
    
    class var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    class var name: String {
        return Bundle.main.infoDictionary!["CFBundleName"] as! String
    }
    class var version: String {
        return Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    }
    class var buildVersion: String {
        return Bundle.main.infoDictionary!["CFBundleVersion"] as! String
    }
    class var rootViewController: UIViewController {
        return shared.window!.rootViewController!
    }
    class var windows: [UIWindow] {
        return UIApplication.shared.windows
    }
}
