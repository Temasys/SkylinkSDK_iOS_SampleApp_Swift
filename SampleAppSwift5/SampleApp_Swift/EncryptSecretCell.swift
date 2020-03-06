//
//  EncryptSecretCell.swift
//  SampleApp_Swift
//
//  Created by Charlie on 18/2/20.
//  Copyright © 2020 Temasys. All rights reserved.
//

import UIKit
let CELL_IDENTIFIER_ENCRYPT_SECRET = String(describing: EncryptSecretCell.self)
class EncryptSecretCell: UITableViewCell, UITextFieldDelegate {
    @IBOutlet weak var secretIdField: UITextField!
    @IBOutlet weak var secretField: UITextField!
        
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
//        NotificationCenter.default.addObserver(self, selector: #selector(self.textChanged(sender:)), name: UITextField.textDidChangeNotification, object: nil)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {}
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}
    
    func setupCell(secretId: String, secret: String) {
        secretIdField.text = secretId
        secretField.text = secret
    }
     
    func textFieldDidChangeSelection(_ textField: UITextField) {
            if textField == secretField{
                print("secret")
                ENCRYPTION_SECRETS[secretIdField.text ?? ""] = textField.text
            }
            if textField == secretIdField{
                print("secretId")
            }
            print("textchanged")
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        print("replacement: \(string)")
        let updatedString = (textField.text as NSString?)?.replacingCharacters(in: range, with: string)
        if textField == secretField{
            print("secret")
            ENCRYPTION_SECRETS[secretIdField.text ?? ""] = updatedString
        }
        return true
    }
}
