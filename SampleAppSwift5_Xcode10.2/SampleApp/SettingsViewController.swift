//
//  SettingsViewController.swift
//  SampleApp_Swift
//
//  Created by Temasys on 6/10/17.
//  Copyright © 2017 Temasys. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    let appkey_secret_keys = ["App Key", "App Secret"]
    let appkey_secret_values = [SKYLINK_APP_KEY, SKYLINK_SECRET]
    let room_name_keys = ["1-1 video call", "Multi video call", "Audio call", "Messages", "File transfer", "Data transfer"]
    let room_name_values = [ROOM_ONE_TO_ONE_VIDEO, ROOM_MULTI_VIDEO, ROOM_AUDIO, ROOM_MESSAGES, ROOM_FILE_TRANSFER, ROOM_DATA_TRANSFER]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Settings"
        tableView.register(UINib(nibName: "SettingCell", bundle: nil), forCellReuseIdentifier: CELL_IDENTIFIER)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return appkey_secret_keys.count
        } else {
            return room_name_keys.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_IDENTIFIER) as! SettingCell
        if indexPath.section == 0 {
            cell.setupCell(key: appkey_secret_keys[indexPath.row], value: appkey_secret_values[indexPath.row])
        } else {
            cell.setupCell(key: room_name_keys[indexPath.row], value: room_name_values[indexPath.row])
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Skylink developer credentials"
        } else {
            return "Sample room names"
        }
    }
}

