//
//  InviteFriendTableViewCell.swift
//  PIA VPN
//
//  Created by Jose Antonio Blaya Garcia on 03/07/2019.
//  Copyright © 2019 London Trust Media. All rights reserved.
//

import UIKit
import PIALibrary

class InviteFriendTableViewCell: UITableViewCell, FriendReferralCell {

    @IBOutlet private weak var labelFullName: UILabel!
    
    @IBOutlet private weak var textFullName: BorderedTextField!

    @IBOutlet private weak var labelEmail: UILabel!
    
    @IBOutlet private weak var textEmail: BorderedTextField!
    
    @IBOutlet private weak var textAgreement: UITextView!

    @IBOutlet private weak var sendButton: PIAButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        labelFullName.text = L10n.Friend.Referrals.fullName
        labelEmail.text = L10n.Account.Email.placeholder
        textAgreement.attributedText = Theme.current.agreementText(
            withMessage: L10n.Friend.Referrals.Invitation.terms,
            tos: L10n.Friend.Referrals.Family.Friends.program,
            tosUrl: AppConstants.Web.friendReferralTerms,
            privacy: "",
            privacyUrl: "")
        sendButton.setTitle(L10n.Friend.Referrals.Send.invite.uppercased(),
                              for: [])
        
        Theme.current.applySecondaryBackground(self)
        Theme.current.applySecondaryBackground(self.contentView)

        textEmail.placeholder = L10n.Account.Email.placeholder
        textFullName.placeholder = L10n.Friend.Referrals.fullName

        sendButton.setRounded()
        sendButton.style(style: TextStyle.Buttons.piaGreenButton)
        
        textEmail.delegate = self
        textFullName.delegate = self

    }
    
    func setupCell(withInviteInformation inviteInformation: InvitesInformation) {
        Theme.current.applySubtitle(labelFullName)
        Theme.current.applySubtitle(labelEmail)
        Theme.current.applyInput(textFullName)
        Theme.current.applyInput(textEmail)
        Theme.current.applyLinkAttributes(textAgreement)
    }

    override func touchesBegan(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        self.endEditing(true)
    }

    @IBAction func sendInvitation(_ sender: Any) {
        
        self.applyNormalStatusForEmailTextfield()

        guard let email = textEmail.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            Validator.validate(email: email),
            !email.isEmpty else {
                let errorMessage = L10n.Friend.Referrals.Email.validation
                self.applyErrorStatusForEmailTextfield()
                Macros.displayImageNote(withImage: Asset.iconWarning.image,
                                    message: errorMessage)
            return
        }

        self.contentView.showLoadingAnimation()
        self.isUserInteractionEnabled = false
        Client.providers.accountProvider.invite(name: self.textFullName.text ?? "",
                                                email: email,
                                                { [weak self] error in
                                                    if let weakSelf = self {
                                                        weakSelf.isUserInteractionEnabled = true
                                                        weakSelf.contentView.hideLoadingAnimation()
                                                        if let _ = error {
                                                            Macros.displayImageNote(withImage: Asset.iconWarning.image,
                                                                                    message: L10n.Friend.Referrals.Invite.error)
                                                        } else {
                                                            weakSelf.textEmail.text = ""
                                                            weakSelf.textFullName.text = ""
                                                            Macros.displaySuccessImageNote(withImage: Asset.iconWarning.image,
                                                                                    message: L10n.Friend.Referrals.Invite.success)
                                                            Macros.postNotification(.FriendInvitationSent)
                                                        }
                                                    }
        })
        
    }
    
    private func applyErrorStatusForEmailTextfield() {
        Theme.current.applyInputError(self.textEmail)
        let iconWarning = UIImageView(image:Asset.iconWarning.image.withRenderingMode(.alwaysTemplate))
        iconWarning.tintColor = .piaRed
        self.textEmail.rightView = iconWarning
    }
    
    private func applyNormalStatusForEmailTextfield() {
        Theme.current.applyInput(self.textEmail)
        self.textEmail.rightView = nil
    }
}

extension InviteFriendTableViewCell: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
