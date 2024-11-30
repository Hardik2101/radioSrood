
import UIKit

extension UICollectionView {
    
    func registerAndGet<T:UICollectionViewCell>(_ identifier:T.Type, indexPath: IndexPath) -> T? {
        let cellID = String(describing: identifier)
        self.register(UINib(nibName: cellID, bundle: nil), forCellWithReuseIdentifier: cellID)
        return self.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as? T
    }
    
}
