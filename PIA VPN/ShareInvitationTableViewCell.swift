//
//  ShareInvitationTableViewCell.swift
//  PIA VPN
//
//  Created by Jose Antonio Blaya Garcia on 03/07/2019.
//  Copyright © 2019 London Trust Media. All rights reserved.
//

import UIKit
import PIALibrary

class ShareInvitationTableViewCell: UITableViewCell, FriendReferralCell {

    @IBOutlet private weak var labelDescription: UILabel!
        
    @IBOutlet private weak var textUniqueCode: BorderedTextField!

    @IBOutlet private weak var textAgreement: UITextView!
    
    @IBOutlet private weak var copyButton: PIAButton!

    @IBOutlet private weak var shareButton: PIAButton!

    @IBOutlet private weak var copiedView: UIView!
    @IBOutlet private weak var copiedLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        labelDescription.text = "Share your unique referral link"
        textAgreement.attributedText = Theme.current.agreementText(
            withMessage: "By sharing this link, you agree to all of the terms and conditions of the Family and Friends Referral Program.",
            tos: "Family and Friends Referral Program",
            tosUrl: "https://www.privateinternetaccess.com/pages/invites/terms_and_conditions",
            privacy: "",
            privacyUrl: "")
        copyButton.setTitle("COPY",
                            for: [])
        shareButton.setTitle("SHARE",
                             for: [])
        copiedLabel.text = "COPIED TO CLIPBOARD"
        copiedView.alpha = 0
        
        Theme.current.applySecondaryBackground(self)
        Theme.current.applySecondaryBackground(self.contentView)

        copyButton.setRounded()
        copyButton.setButtonImage()
        copyButton.setImage(Asset.copyIcon.image.withRenderingMode(.alwaysTemplate), for: .normal)
        copyButton.tintColor = .white
        copyButton.style(style: TextStyle.Buttons.piaGreenButton)
        shareButton.setRounded()
        shareButton.setButtonImage()
        shareButton.setImage(Asset.shareIcon.image.withRenderingMode(.alwaysTemplate), for: .normal)
        shareButton.tintColor = .white
        shareButton.style(style: TextStyle.Buttons.piaGreenButton)
        
        textUniqueCode.delegate = self

    }

    func setupCell() {
        Theme.current.applyInputOverlay(copiedView)
        Theme.current.applyFriendReferralsMessageLabel(copiedLabel)
        Theme.current.applySubtitle(labelDescription)
        Theme.current.applyInput(textUniqueCode)
        Theme.current.applyLinkAttributes(textAgreement)
    }
    
    @IBAction func copyToClipboard() {
        let pasteboard = UIPasteboard.general
        pasteboard.string = textUniqueCode.text
        UIView.animate(withDuration: AppConfiguration.Animations.duration, animations: { [weak self] in
            self?.copiedView.alpha = 0.75
            }, completion: { [weak self] finished in
                UIView.animate(withDuration: AppConfiguration.Animations.duration, animations: { [weak self] in
                    self?.copiedView.alpha = 0
                })
        })

    }
    
    @IBAction func shareInApps() {
        Macros.postNotification(.ShareFriendReferralCode)
    }

    override func touchesBegan(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        self.endEditing(true)
    }

}

extension ShareInvitationTableViewCell: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}