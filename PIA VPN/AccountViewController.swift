//
//  AccountViewController.swift
//  PIA VPN
//
//  Created by Davide De Rosa on 12/7/17.
//  Copyright © 2017 London Trust Media. All rights reserved.
//

import UIKit
import PIALibrary
import SwiftyBeaver

private let log = SwiftyBeaver.self

class AccountViewController: AutolayoutViewController {
    private enum Secion: Int {
        case uncredited

        case info
    }

    @IBOutlet private weak var scrollView: UIScrollView!

    @IBOutlet private weak var viewSafe: UIView!

    @IBOutlet private weak var labelEmail: UILabel!

    @IBOutlet private weak var textEmail: BorderedTextField!
    
    @IBOutlet private weak var labelUsername: UILabel!
    
    @IBOutlet private weak var textUsername: UITextField!
    
    @IBOutlet private weak var labelFooterOther: UILabel!

    @IBOutlet weak var labelExpiryInformation: UILabel!
    
    @IBOutlet private weak var itemUpdate: UIBarButtonItem!
    
    @IBOutlet private weak var viewAccountInfo: UIView!
    
    @IBOutlet private weak var viewUncredited: UIView!
    
    @IBOutlet private weak var labelRestoreTitle: UILabel!
    
    @IBOutlet private weak var labelRestoreInfo: UILabel!
    
    @IBOutlet private weak var buttonRestore: UIButton!
    
    @IBOutlet private weak var labelSubscriptions: UILabel!

    @IBOutlet weak var labelSubscriptionTopConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var viewFriendReferral: UIView!
    
    @IBOutlet private weak var labelFriendReferralTitle: UILabel!
    
    @IBOutlet private weak var labelFriendReferralInfo: UILabel!

    @IBOutlet private weak var buttonFriendReferral: PIAButton!

    private var currentUser: UserAccount?

    private var canSaveAccount = false {
        didSet {
            itemUpdate.isEnabled = canSaveAccount
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.Menu.Item.account
        labelEmail.text = L10n.Account.Email.caption
        textEmail.placeholder = L10n.Account.Email.placeholder
        labelUsername.text = L10n.Account.Username.caption
        itemUpdate.title = L10n.Account.Save.item
        labelFooterOther.text = L10n.Account.Other.footer
        labelRestoreTitle.text = L10n.Account.Restore.title
        labelRestoreInfo.text = L10n.Account.Restore.description
        buttonRestore.setTitle(L10n.Account.Restore.button.uppercased(), for: .normal)
        labelSubscriptions.attributedText = Theme.current.textWithColoredLink(
            withMessage: L10n.Account.Subscriptions.message,
            link: L10n.Account.Subscriptions.linkMessage)
        labelSubscriptions.isUserInteractionEnabled = true

        viewSafe.layoutMargins = .zero
        textEmail.isEditable = true
        textUsername.isUserInteractionEnabled = false
        canSaveAccount = false

        buttonFriendReferral.setTitle("  \(L10n.Friend.Referrals.title)  >  ", for: .normal)
        labelFriendReferralInfo.text = L10n.Friend.Referrals.Friends.Family.title
        labelFriendReferralTitle.text = L10n.Friend.Referrals.Description.short

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(redisplayAccount), name: .PIAAccountDidRefresh, object: nil)
        nc.addObserver(self, selector: #selector(viewHasRotated), name: UIDevice.orientationDidChangeNotification, object: nil)

        let tap = UITapGestureRecognizer(target: self, action: #selector(openManageSubscription))
        labelSubscriptions.addGestureRecognizer(tap)

        Client.providers.accountProvider.retrieveAccount()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        // update local state immediately
        styleNavigationBarWithTitle(L10n.Menu.Item.account)
        redisplayAccount()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        view.endEditing(true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        if textEmail.text?.isEmpty ?? true {
            textEmail.becomeFirstResponder()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        buttonFriendReferral.layoutIfNeeded()
        establishUncreditedVisibility()
    }

    @objc private func viewHasRotated() {
        styleNavigationBarWithTitle(L10n.Menu.Item.settings)
    }
    
    // MARK: Actions

    @IBAction private func saveChanges(_ sender: Any?) {
        
        textEmail.resignFirstResponder()
        
        guard canSaveAccount else {
            return
        }
    
        guard let email = self.textEmail.text else {
            return
        }
        
        let alert = Macros.alertController(L10n.Account.Update.Email.Require.Password.title,
                                           L10n.Account.Update.Email.Require.Password.message)

        alert.addCancelAction(L10n.Global.cancel)
        let action = UIAlertAction(title: L10n.Account.Update.Email.Require.Password.button,
                                   style: .default) { [weak self] (alertAction) in
            
            if let weakSelf = self {
                if let textField = alert.textFields?.first,
                    let password = textField.text {
                    
                    log.debug("Account: Modifying account email...")
                    
                    let request = UpdateAccountRequest(email: email)

                    
                    Client.providers.accountProvider.update(with: request,
                                                            andPassword: password) { (info, error) in
                                                                weakSelf.hideLoadingAnimation()
                                                                
                                                                guard let _ = info else {
                                                                    if let error = error {
                                                                        log.error("Account: Failed to modify account email (error: \(error))")
                                                                    } else {
                                                                        log.error("Account: Failed to modify account email")
                                                                    }
                                                                    
                                                                    weakSelf.textEmail.text = ""
                                                                    let alert = Macros.alert(L10n.Global.error, L10n.Account.Error.unauthorized)
                                                                    alert.addDefaultAction(L10n.Global.close)
                                                                    self?.present(alert, animated: true, completion: nil)
                                                                    
                                                                    return
                                                                }
                                                                
                                                                log.debug("Account: Email successfully modified")
                                                                let alert = Macros.alert(nil, L10n.Account.Save.success)
                                                                alert.addDefaultAction(L10n.Global.ok)
                                                                weakSelf.present(alert, animated: true, completion: nil)
                                                                weakSelf.textEmail.text = email
                                                                weakSelf.textEmail.endEditing(true)
                                                                weakSelf.canSaveAccount = false
                    }
                    
                }

            }
        }
        alert.addTextField { (textField) in
            textField.isSecureTextEntry = true
        }
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
        
    }
    
    @IBAction private func renewSubscriptionWithUncreditedPurchase(_ sender: Any?) {
        Client.providers.accountProvider.restorePurchases { (error) in
            if let error = error {
                self.handleReceiptFailureWithError(error)
                return
            }
            self.handleReceiptRefresh()
        }
    }
    
    private func handleReceiptRefresh() {
        log.debug("IAP: Restored payment receipt, redeeming...")

        Client.providers.accountProvider.renew(with: RenewRequest(transaction: nil)) { (user, error) in
            if let clientError = error as? ClientError, (clientError == .badReceipt) {
                self.handleBadReceipt()
                return
            }
            self.handleReceiptSubmissionWithError(error)
        }
    }
        
    private func handleReceiptFailureWithError(_ error: Error?) {
        log.error("IAP: Failed to restore payment receipt (error: \(error?.localizedDescription ?? ""))")

        let alert = Macros.alert(L10n.Global.error, error?.localizedDescription)
        alert.addDefaultAction(L10n.Global.close)
        present(alert, animated: true, completion: nil)
    }
    
    private func handleReceiptSubmissionWithError(_ error: Error?) {
        if let error = error {
            let alert = Macros.alert(L10n.Global.error, error.localizedDescription)
            alert.addDefaultAction(L10n.Global.close)
            present(alert, animated: true, completion: nil)
            return
        }

        log.debug("Account: Renewal successfully completed")
        
        let alert = Macros.alert(
            L10n.Renewal.Success.title,
            L10n.Renewal.Success.message
        )
        alert.addDefaultAction(L10n.Global.close)
        present(alert, animated: true, completion: nil)

        redisplayAccount()
    }
    
    private func handleBadReceipt() {
        let alert = Macros.alert(
            L10n.Account.Restore.Failure.title,
            L10n.Account.Restore.Failure.message
        )
        alert.addDefaultAction(L10n.Global.close)
        present(alert, animated: true, completion: nil)
    }

    // MARK: Notifications
    @objc private func openManageSubscription() {
        if let url = URL(string: AppConstants.AppleUrls.subscriptions) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }

    }
    
    @objc private func redisplayAccount() {
        currentUser = Client.providers.accountProvider.currentUser

        textEmail.endEditing(true)
        textEmail.text = currentUser?.info?.email
        textEmail.isEnabled = !(currentUser?.info?.isExpired ?? true)
        textUsername.text =  Client.providers.accountProvider.publicUsername ?? ""
        
        if let userInfo = currentUser?.info {
            if userInfo.isExpired {
                labelExpiryInformation.text = L10n.Account.ExpiryDate.expired
            } else {
                labelExpiryInformation.text = L10n.Account.ExpiryDate.information(userInfo.humanReadableExpirationDate())
            }
            styleExpirationDate()
            
            if userInfo.plan == .monthly || userInfo.plan == .yearly || userInfo.plan == .trial {
                labelSubscriptions.isHidden = false
                labelSubscriptionTopConstraint.constant = 20
            } else {
                labelSubscriptions.isHidden = true
                labelSubscriptionTopConstraint.constant = 0
            }
            viewFriendReferral.isHidden = !userInfo.canInvite
        }
        
        establishUncreditedVisibility()
    }
    
    private func establishUncreditedVisibility() {
        if let info = currentUser?.info, info.isRenewable {
            viewUncredited.isHidden = false
            viewFriendReferral.removeFromSuperview()
        } else {
            viewUncredited.isHidden = true
        }
    }

    // MARK: Restylable
    
    override func viewShouldRestyle() {
        super.viewShouldRestyle()
        
        styleNavigationBarWithTitle(L10n.Menu.Item.account)

        if let viewContainer = viewContainer {
            Theme.current.applyPrincipalBackground(view)
            Theme.current.applyPrincipalBackground(viewContainer)
        }
        
        Theme.current.applySecondaryBackground(viewAccountInfo)
        Theme.current.applySubtitle(labelEmail)
        Theme.current.applySubtitle(labelUsername)
        
        Theme.current.applyInput(textEmail)
        Theme.current.applyClearTextfield(textUsername)

        for label in [labelFooterOther!, labelExpiryInformation!] {
            Theme.current.applySubtitle(label)
        }
        Theme.current.applyTitle(labelRestoreTitle, appearance: .dark)
        Theme.current.applySubtitle(labelRestoreInfo)
        buttonRestore.style(style: TextStyle.textStyle9)

        Theme.current.applyFriendReferralsTitle(labelFriendReferralTitle)
        Theme.current.applyFriendReferralsSubtitle(labelFriendReferralInfo)
        Theme.current.applyFriendReferralsView(viewFriendReferral, appearance: .dark)
        Theme.current.applyFriendReferralsButton(buttonFriendReferral, appearance: .dark)
        buttonRestore.style(style: TextStyle.textStyle9)

        styleExpirationDate()
        
    }
    
    private func styleExpirationDate() {
        if let userInfo = currentUser?.info {
            Theme.current.makeSmallLabelToStandOut(labelExpiryInformation,
                                                   withTextToStandOut: userInfo.humanReadableExpirationDate())
        }
    }
}

extension AccountViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let hitEnter = (string == "\n")
        if !hitEnter {
            if let currentText = textField.text {
                let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
                canSaveAccount = ((newText != currentUser?.info?.email) && Validator.validate(email: newText))
            }
        }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField == textEmail) {
            textField.resignFirstResponder()
            saveChanges(textField)
        }
        return true
    }
}
