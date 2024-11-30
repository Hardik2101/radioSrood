//
//  CustomAlertController.swift
//  Radio Srood
//
//  Created by Hardik Chotaliya on 20/12/23.
//  Copyright © 2023 Appteve. All rights reserved.
//

import UIKit

public class CustomAlertController {
    
    class var instance: CustomAlertController {
        struct Static {
            static let inst: CustomAlertController = CustomAlertController()
        }
        return Static.inst
    }
    
    func topMostController() -> UIViewController? {
        var presentedVC = UIApplication.shared.keyWindow?.rootViewController
        while let pVC = presentedVC?.presentedViewController {
            presentedVC = pVC
        }
        
        if presentedVC == nil {
            // DLog(" You don't have any views set. You may be calling in viewdidload. Try viewdidappear.")
        }
        return presentedVC
    }
    
    public class func alert(title: String) -> UIAlertController {
        return alert(title: title, message: "")
    }
    
    public class func alert(title: String, message: String) -> UIAlertController {
        
        return alert(title: title, message: message, buttons: ["OK"], buttonStyle: [.default], tapBlock: nil)
    }
    
    public class func alert(title: String, message: String, acceptMessage: String, acceptBlock: @escaping () -> Void) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        let acceptButton = UIAlertAction(title: acceptMessage, style: .default, handler: { (_: UIAlertAction) in
            acceptBlock()
        })
        alert.addAction(acceptButton)
        
        instance.topMostController()?.present(alert, animated: true, completion: nil)
        return alert
    }
    
    public class func alert(title: String, message: String, buttons: [String], buttonStyle: [UIAlertAction.Style], tapBlock: ((UIAlertAction, Int) -> Void)?) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert, buttons: buttons, buttonStyle: buttonStyle, tapBlock: tapBlock)
        instance.topMostController()?.present(alert, animated: true, completion: nil)
        return alert
    }
    
    public class func actionSheet(title: String, message: String, sourceView: UIView, actions: [UIAlertAction]) -> UIAlertController {
        let alert = UIAlertController(title: ((title.length == 0) ? nil : title), message: ((message.length == 0) ? nil : message), preferredStyle: UIAlertController.Style.actionSheet)
        for action in actions {
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        
        alert.popoverPresentationController?.sourceView = sourceView
        alert.popoverPresentationController?.sourceRect = sourceView.bounds
        instance.topMostController()?.present(alert, animated: true, completion: nil)
        return alert
    }
    
    public class func actionSheet(title: String, message: String, sourceView: UIView, buttons: [String], buttonStyle: [UIAlertAction.Style], tapBlock: ((UIAlertAction, Int) -> Void)?) -> UIAlertController {
        let alert = UIAlertController(title: ((title.length == 0) ? nil : title), message: ((message.length == 0) ? nil : message), preferredStyle: .actionSheet, buttons: buttons, buttonStyle: buttonStyle, tapBlock: tapBlock)
        alert.popoverPresentationController?.sourceView = sourceView
        alert.popoverPresentationController?.sourceRect = sourceView.bounds
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        
        instance.topMostController()?.present(alert, animated: true, completion: nil)
        return alert
    }
    
}

private extension UIAlertController {
    convenience init(title: String?, message: String?, preferredStyle: UIAlertController.Style, buttons: [String], buttonStyle: [UIAlertAction.Style], tapBlock: ((UIAlertAction, Int) -> Void)?) {
        self.init(title: title, message: message, preferredStyle: preferredStyle)
        var buttonIndex = 0
        for buttonTitle in buttons {
            let action = UIAlertAction(title: buttonTitle, preferredStyle: buttonStyle[buttonIndex], buttonIndex: buttonIndex, tapBlock: tapBlock)
            buttonIndex += 1
            self.addAction(action)
        }
    }
}

private extension UIAlertAction {
    convenience init(title: String?, preferredStyle: UIAlertAction.Style, buttonIndex: Int, tapBlock: ((UIAlertAction, Int) -> Void)?) {
        self.init(title: title, style: preferredStyle) { (action: UIAlertAction) in
            if let block = tapBlock {
                block(action, buttonIndex)
            }
        }
    }
}
