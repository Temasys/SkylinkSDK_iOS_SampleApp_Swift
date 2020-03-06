//
//  SettingsViewController.swift
//  SampleApp_Swift
//
//  Created by  Temasys on 6/10/17.
//  Copyright © 2017 Temasys. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var tableView: UITableView!
    
    let appkey_secret_keys = ["App Key", "App Secret"]
    var appkey_secret_values = [APP_KEY, APP_SECRET]
    
    let encryption_secrets = Array(ENCRYPTION_SECRETS.keys).sorted(by: <)
    let room_name_keys = ["1-1 video call", "Multi video call", "Audio call", "Messages", "File transfer", "Data transfer"]
    let room_name_values = [ROOM_ONE_TO_ONE_VIDEO, ROOM_MULTI_VIDEO, ROOM_AUDIO, ROOM_MESSAGES, ROOM_FILE_TRANSFER, ROOM_DATA_TRANSFER]
    let allAppKey = Array(APP_KEYS.keys).sorted(by:<)
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Settings"
        tableView.register(UINib(nibName: "SettingCell", bundle: nil), forCellReuseIdentifier: CELL_IDENTIFIER)
        tableView.register(UINib(nibName: "EncryptSecretCell", bundle: nil), forCellReuseIdentifier: CELL_IDENTIFIER_ENCRYPT_SECRET)
    }
    
    deinit {
        print(ROOM_ONE_TO_ONE_VIDEO, ROOM_MULTI_VIDEO, ROOM_AUDIO, ROOM_MESSAGES, ROOM_FILE_TRANSFER, ROOM_DATA_TRANSFER)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return appkey_secret_keys.count+1
        } else if section == 1{
            return encryption_secrets.count
        }else {
            return room_name_keys.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_IDENTIFIER) as! SettingCell
        if indexPath.section == 0 {
            if indexPath.row == 2 {
                let _normalCell = UITableViewCell(style: .default, reuseIdentifier: nil)
                _normalCell.textLabel?.text = "Select App Key"
                _normalCell.textLabel?.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                _normalCell.backgroundColor = #colorLiteral(red: 0.1764705926, green: 0.01176470611, blue: 0.5607843399, alpha: 1)
                return _normalCell
            }
            cell.setupCell(key: appkey_secret_keys[indexPath.row], value: appkey_secret_values[indexPath.row])
            
        }else if indexPath.section == 1{
            let encryptSecretCell = tableView.dequeueReusableCell(withIdentifier: CELL_IDENTIFIER_ENCRYPT_SECRET) as! EncryptSecretCell
            encryptSecretCell.setupCell(secretId: encryption_secrets[indexPath.row], secret: ENCRYPTION_SECRETS[encryption_secrets[indexPath.row]] ?? "")
            return encryptSecretCell
        } else {
            cell.setupCell(key: room_name_keys[indexPath.row], value: room_name_values[indexPath.row])
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Skylink developer credentials"
        }else if section == 1{
            return "Encrypt Secrets"
        } else {
            return "Room names"
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.section == 0) && (indexPath.row == 2){
            selectAppKey()
        }
    }
    private func selectAppKey(){
        let alert = UIAlertController(title: "Choose a Secret App", message: nil, preferredStyle: .alert)
        let noAction = UIAlertAction(title: "Cancel", style: .default)
        for appKey in allAppKey {
//            let index = APP_KEYS.firstIndex(of: secret)
            let yesAction = UIAlertAction(title: appKey, style: .default) { [unowned self] _ in
                self.selectedAppKey(key: appKey)
            }
            alert.addAction(yesAction)
        }
        alert.addAction(noAction)
        present(alert, animated: true, completion: nil)
    }
    private func selectedAppKey(key: String){
        APP_KEY = key
        APP_SECRET = APP_KEYS[key] ?? ""
        appkey_secret_values = [APP_KEY, APP_SECRET]
        tableView.reloadData()
    }
}
