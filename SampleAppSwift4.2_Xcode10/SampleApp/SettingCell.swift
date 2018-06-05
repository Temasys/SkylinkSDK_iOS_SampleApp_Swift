//
//  SettingCell.swift
//  SampleApp_Swift
//
//  Created by Yuxi Liu on 21/3/18.
//  Copyright © 2018 Temasys. All rights reserved.
//

import UIKit

let CELL_IDENTIFIER = String(describing: SettingCell.self)

class SettingCell: UITableViewCell {

    @IBOutlet weak var keyLabel: UILabel!
    @IBOutlet weak var valueField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        NotificationCenter.default.addObserver(self, selector: #selector(textChanged), name: UITextField.textDidChangeNotification, object: nil)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {}
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}
    
    func setupCell(key: String, value: String) {
        keyLabel.text = key
        valueField.text = value
    }
    
    @objc func textChanged() {
        if valueField.text == nil || valueField.text!.contains(" ") {
            print("Room name not valid")
            return
        } else {
            switch keyLabel.text! {
            case "App Key":
                APP_KEY = valueField.text!
            case "App Secret":
                APP_SECRET = valueField.text!
            case "1-1 video call":
                ROOM_ONE_TO_ONE_VIDEO = valueField.text!
            case "Multi video call":
                ROOM_MULTI_VIDEO = valueField.text!
            case "Audio call":
                ROOM_AUDIO = valueField.text!
            case "Messages":
                ROOM_MESSAGES = valueField.text!
            case "File transfer":
                ROOM_FILE_TRANSFER = valueField.text!
            case "Data transfer":
                ROOM_DATA_TRANSFER = valueField.text!
            default:
                break
            }
        }
    }
}
