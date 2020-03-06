//
//  Constants.swift
//  SampleApp
//
//  Created by  Temasys on 26/7/17.
//  Copyright © 2017  Temasys. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import SKYLINK

let SCREEN_WIDTH = UIScreen.main.bounds.width
let SCREEN_HEIGHT = UIScreen.main.bounds.height

let iPhone4 = UIScreen.main.bounds.height == 480
let iPhone5 = UIScreen.main.bounds.height == 568
let iPhone6 = UIScreen.main.bounds.height == 667
let iPhone6Plus = UIScreen.main.bounds.height == 736
let iPhoneX = UIScreen.main.bounds.height == 812
let iPhoneXR_XSMAX = UIScreen.main.bounds.height == 896

var APP_KEY = ""
var APP_SECRET = ""
var APP_KEYS: [String: String] = ["APP_KEY1": "APP_SECRET1",
                                  "APP_KEY2": "APP_SECRET2"]

var ROOM_NAME = ""
var ROOM_ONE_TO_ONE_VIDEO = "One to one Media"
var ROOM_MULTI_VIDEO = "Multiparty"
var ROOM_AUDIO = "Audio"
var ROOM_MESSAGES = "Chat"
var ROOM_FILE_TRANSFER = "File Transfer"
var ROOM_DATA_TRANSFER = "Data Streaming"
var appFilesFolder = ""

var USER_NAME = UIDevice.current.name
var ENCRYPTION_SECRETS = ["key1": "secret1", "key2": "secret2", "key3": "secret3"]

