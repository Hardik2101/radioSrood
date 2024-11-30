///// Add Tabbar View 5

//  IAPVC.swift
//  Radio Srood
//
//  Created by Hardik Chotaliya on 19/12/23.
//  Copyright © 2023 Appteve. All rights reserved.
//

import UIKit
import StoreKit

class IAPVC: UIViewController {
    
    @IBOutlet weak var btnBack: UIButton!
    
    @IBOutlet weak var vwYearly: UIView!
    @IBOutlet weak var vwMonthly: UIView!
    
    @IBOutlet weak var lblYearly: UILabel!
    @IBOutlet weak var lblYearlyPrice: UILabel!
    
    @IBOutlet weak var lblMonthly: UILabel!
    @IBOutlet weak var lblMonthlyPrice: UILabel!

    
    @IBOutlet weak var lblSrood: UILabel!
    @IBOutlet weak var lblPlus: UILabel!
    @IBOutlet weak var vwFeatures: UIView!
    
    @IBOutlet weak var lblFeature1: UILabel!
    @IBOutlet weak var lblFeature2: UILabel!
    @IBOutlet weak var lblFeature3: UILabel!
    
    @IBOutlet weak var imsSelectedMonthly: UIImageView!
    
    @IBOutlet weak var imgSelectedYearly: UIImageView!
    
    @IBOutlet weak var lblSubscriptionAndPrivacyPolicy: UILabel!

    @IBOutlet weak var btnRestore: UIButton!
    
    @IBOutlet weak var btnUpgradePremium: UIButton!

    @IBOutlet weak var txtView: UITextView!
    private var isYearly: Bool = false
     var isshowbackButton: Bool = false

//    private var selectedProduct = enumSelectedProduct.oneYearProd

    private let subScriptionAgreementRange = ("\(NSLocalizedString("Terms Of Use", comment: ""))    \(NSLocalizedString("Privacy Policy", comment: ""))" as NSString).range(of: NSLocalizedString("Terms Of Use", comment: ""))
    
    private let privacyPolicyRange = ("\(NSLocalizedString("Terms Of Use", comment: ""))    \(NSLocalizedString("Privacy Policy", comment: ""))" as NSString).range(of: NSLocalizedString("Privacy Policy", comment: ""))

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.btnBack.isHidden = !self.isshowbackButton
    }
    
    private func setUpUI() {
        btnBack.isHidden = self.isshowbackButton

        navigationController?.setNavigationBarHidden(true, animated: false)

        lblSrood.text = "SROOD"
        lblPlus.text = "PLUS"
        lblFeature1.text = "Ad-free music: Enjoy music without interruptions and unlimited skips."
        lblFeature2.text = "Download songs: Offline playback anytime, anywhere."
        lblFeature3.text = "HQ sounds: Enjoy audio quality ranging from 192 to 320 kbps."
        
        configAgreementText()
        
        self.vwMonthly.backgroundColor = UIColor.white
        self.vwYearly.backgroundColor = UIColor(hex: "4A565F")
        
        self.vwYearly.layer.cornerRadius = 16
        self.vwMonthly.layer.cornerRadius = 16

        btnUpgradePremium.setTitle("Upgrade Your Plan", for: .normal)
        btnRestore.setTitle("Restore", for: .normal)
        
        btnUpgradePremium.backgroundColor = .white
        btnUpgradePremium.layer.cornerRadius = 16
        
        btnUpgradePremium.setTitleColor(.black, for: .normal)
        
        imsSelectedMonthly.image = UIImage(named: "ic_selected")
        imgSelectedYearly.image = UIImage(named: "")
        
        txtView.text = """
* Subscriptions are auto-renewable in-app-purchases.\n\n• Payment will be charged to iTunes Account at confirmation of purchase.\n\n• Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period \n\n• Account will be charged for renewal within 24-hours prior to the end of the current period and identify the cost of the renewal \n\n• Subscriptions may be managed by the user and auto-renewal may be turned off by going to the user’s Account Settings after purchase.
"""
        
//        lblPrice.text = "$4.99/Month"
        
        for product in IAPHandler.shared.productArray {
            if let productIden = IAProduct(rawValue: product.productIdentifier) {
                switch productIden {
                case .Product_identifierOneMonth:
                    let currencySymbol = product.priceLocale.currencySymbol ?? ""
                    let price = "\(currencySymbol)\(product.price.floatValue)"
                    let currencyCode = product.priceLocale.currencyCode ?? ""

                    print("Monthly price", "\(currencySymbol)" + "\(product.price.floatValue)")
                    lblMonthlyPrice.text = "\(price) \(currencyCode)"
                    break

                case .Product_identifierYearly:
                    print("Yearly price","\(product.price.floatValue)" )
                    let currencySymbol = product.priceLocale.currencySymbol ?? ""
                    let price = "\(currencySymbol)\(product.price.floatValue)"
                    let currencyCode = product.priceLocale.currencyCode ?? ""

                    lblYearlyPrice.text = "\(price) \(currencyCode)"

                    break

                }
            }
        }
        if Reachability.isConnectedToNetwork() {
            
            if let product = IAPHandler.shared.productArray.first(where: { $0.productIdentifier == IAProduct.Product_identifierOneMonth.rawValue }) {
                updatePriceLabel(product)
            }
        } else {
            CustomLoader.shared.hideLoader()
            _ = CustomAlertController.alert(title: "Internet is not connected. Please check internet connectivity." )
        }

    }
    
    
//    @objc func segmentedControlChanged(_ sender: UISegmentedControl) {
//        if sender.selectedSegmentIndex == 0 {
//            if let product = IAPHandler.shared.productArray?.first(where: { $0.productIdentifier == IAProduct.Product_identifierOneMonth.rawValue }) {
//                updatePriceLabel(product)
//                lblSingleAccount.text = "A Single account with access to the full Radio Srood experience."
//                isYearly = false
//            }
//        } else {
//            if let product = IAPHandler.shared.productArray?.first(where: { $0.productIdentifier == IAProduct.Product_identifierYearly.rawValue }) {
//                updatePriceLabel(product)
//                lblSingleAccount.text = "Save 16.5% by paying 12 months upfront."
//                isYearly = true
//            }
//        }
//    }

    private func updatePriceLabel(_ product: SKProduct) {
        let currencySymbol = product.priceLocale.currencySymbol ?? ""
        let price = "\(currencySymbol)\(product.price.floatValue)"
        let currencyCode = product.priceLocale.currencyCode ?? ""

        if product.productIdentifier == IAProduct.Product_identifierOneMonth.rawValue {
            lblMonthlyPrice.text = "\(price) \(currencyCode)"
        }
        
        if product.productIdentifier == IAProduct.Product_identifierYearly.rawValue {
            lblYearlyPrice.text = "\(price) \(currencyCode)"
        }
    }

    
    private func getProductDetails(productIdn: String) {
        
        if Reachability.isConnectedToNetwork() {
            if IAPHandler.shared.productArray == nil {
                IAPHandler.shared.fetchAvailableProducts { [self](products)   in
                    
                    if products.count != 0 {
                        guard let product = IAPHandler.shared.findPaymentIndex(productIdentifier: productIdn) else {
                            return
                        }
                        self.purchaseProduct(IAPHandler.shared.productArray[product])
                    }
                }
            } else {
                guard let product = IAPHandler.shared.findPaymentIndex(productIdentifier: productIdn) else {
                    return
                }
                self.purchaseProduct(IAPHandler.shared.productArray[product])
            }
        } else {
            CustomLoader.shared.hideLoader()
            _ = CustomAlertController.alert(title: "Internet is not connected. Please check internet connectivity." )
        }
        
    }
    
    private func purchaseProduct(_ product: SKProduct) {
        if Reachability.isConnectedToNetwork() {
            CustomLoader.shared.showLoader(in: self.view)
            IAPHandler.shared.purchase(product: product) { [weak self](alert, product, transaction) in
                if let tran = transaction, let prod = product {
                    
                    // use transaction details and purchased product as you want
                    print("\(tran.description)")
                    print("\(prod.productIdentifier)")
                    guard let sSelf = self else {return}
                    NotificationCenter.default.post(name: .PurchaseSuccess, object: nil)
                    sSelf.dismiss(animated: true, completion: {
                        CustomLoader.shared.hideLoader()
                        
                    })
                } else {
                    CustomLoader.shared.hideLoader()
                    guard let sSelf = self else {return}
                    runOnAfterTime(afterTime: 1, block: {
                        _ = CustomAlertController.alert(title: "\(alert.message)")
                    })
                }
            }
        } else {
            CustomLoader.shared.hideLoader()
            _ = CustomAlertController.alert(title: "Internet is not connected. Please check internet connectivity.")
        }
    }
    
    
    @IBAction func clickOn_btnBack(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
//    @IBAction func clickOn_btnUpgradeToPlan(_ sender: Any) {
//
//        if isYearly {
//            self.getProductDetails(productIdn: IAProduct.Product_identifierYearly.rawValue)
//
//        } else {
//            self.getProductDetails(productIdn: IAProduct.Product_identifierOneMonth.rawValue)
//
//        }
//    }
    
    private func configAgreementText() {
        
        lblSubscriptionAndPrivacyPolicy.textColor = UIColor.white
        
        let themeAttributedString = NSMutableAttributedString(string: "\(NSLocalizedString("Terms Of Use", comment: ""))    \(NSLocalizedString("Privacy Policy", comment: ""))")
        themeAttributedString.addAttributes([NSAttributedString.Key.font: UIFont(name: "", size: 12) ?? UIFont.systemFont(ofSize: 12, weight: .medium),
                                             NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue], range: subScriptionAgreementRange)
        themeAttributedString.addAttributes([NSAttributedString.Key.font: UIFont(name: "", size: 12) ?? UIFont.systemFont(ofSize: 12, weight: .medium),
                                             NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue], range: privacyPolicyRange)
        self.lblSubscriptionAndPrivacyPolicy.attributedText = themeAttributedString
        self.lblSubscriptionAndPrivacyPolicy.isUserInteractionEnabled = true
        self.lblSubscriptionAndPrivacyPolicy.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(agreement_Tapped)))
    }
    
    
    @objc func agreement_Tapped(gesture: UITapGestureRecognizer) {
        if gesture.didTapAttributedTextInLabel(label: self.lblSubscriptionAndPrivacyPolicy, inRange: subScriptionAgreementRange) {
            openURL(URL(string: "https://radiosrood.com/policies/terms.html")!)
        }
        
        if gesture.didTapAttributedTextInLabel(label: self.lblSubscriptionAndPrivacyPolicy, inRange: privacyPolicyRange) {
            openURL(URL(string: "https://radiosrood.com/policies/privacy.html")!)
        }
    }
    
    func openURL(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    
    // MARK: - Action Methods
    
    @IBAction func clickOn_btnYearly(_ sender: Any) {
                
        self.vwYearly.backgroundColor = UIColor.white
        self.vwMonthly.backgroundColor = UIColor(hex: "4A565F")

        imsSelectedMonthly.image = UIImage(named: "")
        imgSelectedYearly.image = UIImage(named: "ic_selected")

        isYearly = true
//        selectedProduct = enumSelectedProduct.oneYearProd
        
    }
    
    @IBAction func clickOn_btnMonthly(_ sender: Any) {
        
        self.vwYearly.backgroundColor = UIColor(hex: "4A565F")
        self.vwMonthly.backgroundColor = UIColor.white

        imsSelectedMonthly.image = UIImage(named: "ic_selected")
        imgSelectedYearly.image = UIImage(named: "")

        isYearly = false
//        selectedProduct = enumSelectedProduct.oneMonthProd
    }
    
    @IBAction func clickOn_btnRestore(_ sender: Any) {
        
        if Reachability.isConnectedToNetwork() {
            CustomLoader.shared.showLoader(in: self.view)
            IAPHandler.shared.restorePurchase(complition: {[weak self] (alert, _, _) in
                guard let sSelf = self else {return}
                runOnAfterTime(afterTime: 1, block: {
                    _ = CustomAlertController.alert(title: "\(alert.message)", message: "", buttons: ["Ok"], buttonStyle: [.default], tapBlock: { (_, ind) in
                        if ind == 0 {
                            sSelf.dismiss(animated: true, completion: nil)
                        }
                    })
                })
            })
            
            IAPHandler.shared.restorationCompletion = { [weak self] in
                guard let sSelf = self else { return }
                CustomLoader.shared.hideLoader()
                sSelf.dismiss(animated: true, completion: nil)
            }
            
        } else {
            CustomLoader.shared.hideLoader()
            _ = CustomAlertController.alert(title: "No Internet connection")
        }
        
    }
    
    @IBAction func clickOn_btnUpgradePremium(_ sender: Any) {
                if isYearly {
                    self.getProductDetails(productIdn: IAProduct.Product_identifierYearly.rawValue)
                } else {
                    self.getProductDetails(productIdn: IAProduct.Product_identifierOneMonth.rawValue)
                }
    }

}


extension UIColor {
    convenience init(hex: String) {
        var hexString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if hexString.hasPrefix("#") {
            hexString.remove(at: hexString.startIndex)
        }

        if hexString.count != 6 {
            self.init(white: 1.0, alpha: 0.0)
            return
        }

        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)

        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    static var primaryDark = #colorLiteral(red: 0.06666666667, green: 0.06666666667, blue: 0.06666666667, alpha: 1) //UIColor(red: 17/255, green: 17/255, blue: 17/255, alpha: 1)
}


extension UITapGestureRecognizer {
    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
        guard let attributedText = label.attributedText else { return false }

        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: .zero)
        let textStorage = NSTextStorage(attributedString: attributedText)

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize

        let locationOfTouchInLabel = self.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let textContainerOffset = CGPoint(
            x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
            y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y
        )
        let locationOfTouchInTextContainer = CGPoint(
            x: locationOfTouchInLabel.x - textContainerOffset.x,
            y: locationOfTouchInLabel.y - textContainerOffset.y
        )
        let indexOfCharacter = layoutManager.characterIndex(
            for: locationOfTouchInTextContainer,
            in: textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil
        )
        return NSLocationInRange(indexOfCharacter, targetRange)
    }
}
