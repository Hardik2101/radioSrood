

import Foundation
import UIKit

extension UITableView {

    func registerAndGet<T:UITableViewCell>(cell identifier:T.Type) -> T?{
        let cellID = String(describing: identifier)

        if let cell = self.dequeueReusableCell(withIdentifier: cellID) as? T {
            return cell
        } else {
            //regiser
            self.register(UINib(nibName: cellID, bundle: nil), forCellReuseIdentifier: cellID)
            return self.dequeueReusableCell(withIdentifier: cellID) as? T

        }
    }

    func register<T:UITableViewCell>(cell identifier:T.Type) {
        let cellID = String(describing: identifier)
        self.register(UINib(nibName: cellID, bundle: nil), forCellReuseIdentifier: cellID)
    }

    func getCell<T:UITableViewCell>(identifier:T.Type) -> T?{
        let cellID = String(describing: identifier)
        guard let cell = self.dequeueReusableCell(withIdentifier: cellID) as? T else {
            print("cell not exist")
            return nil
        }
        return cell
    }
    
}

extension UIScrollView {
    func scrollToTop(_ animated : Bool = true) {
        let desiredOffset = CGPoint(x: 0, y: -contentInset.top)
        setContentOffset(desiredOffset, animated: animated)
   }
}

public extension Optional where Wrapped == UIStoryboard {
    func vc<T: UIViewController>(_ type: T.Type, id: String? = nil) -> T {
        guard let storyboard = self else {
            fatalError("Storyboard is nil.")
        }
        return storyboard.vc(type, id: id)
    }
}
public extension UIStoryboard {
    func vc<T: UIViewController>(_ type: T.Type, id: String? = nil) -> T {
        let identifier = id ?? String(describing: T.self)
        guard let viewController = self.instantiateViewController(withIdentifier: identifier) as? T else {
            fatalError("ViewController with identifier \(identifier) not found. id: \(String(describing: T.self))")
        }
        return viewController
    }
}

extension UIViewController {
    @objc func popToBack() {
        self.navigationController?.popViewController(animated: true)
    }
    @objc func popToBack2() {
        self.navigationController?.popViewController(animated: false)
    }
}
