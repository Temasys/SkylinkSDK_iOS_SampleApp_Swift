//
//  Constants.swift
//  SampleApp
//
//  Created by Yuxi on 26/7/17.
//  Copyright © 2017 Yuxi. All rights reserved.
//

import Foundation
import UIKit

let SCREEN_WIDTH = UIScreen.main.bounds.width
let SCREEN_HEIGHT = UIScreen.main.bounds.height

let iPhone4 = UIScreen.main.bounds.height == 480
let iPhone5 = UIScreen.main.bounds.height == 568
let iPhone6 = UIScreen.main.bounds.height == 667
let iPhone6Plus = UIScreen.main.bounds.height == 736

var APP_KEY = ""
var APP_SECRET = ""
var ROOM_ONE_TO_ONE_VIDEO = "VIDEO-CALL-ROOM"
var ROOM_MULTI_VIDEO = "MULTI-VIDEO-CALL-ROOM"
var ROOM_AUDIO = "AUDIO-CALL-ROOM"
var ROOM_MESSAGES = "MESSAGES-ROOM"
var ROOM_FILE_TRANSFER = "FILE-TRANSFER-ROOM"
var ROOM_DATA_TRANSFER = "ROOMNAME_DATATRANSFER"

/// <#Description#>
///
/// - Parameters:
///   - r: <#r description#>
///   - g: <#g description#>
///   - b: <#b description#>
/// - Returns: <#return value description#>
func UIRGBColor(r:CGFloat, g:CGFloat, b:CGFloat) -> UIColor {
    return UIColor(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: 1.0)
}

/// 封装的日志输出功能
///
/// - Parameters:
///   - message: <#message description#>
///   - file: <#file description#>
///   - function: <#function description#>
///   - line: <#line description#>
func skylinkLog<T>(_ message: T, file: String = #file, function: String = #function,
            line: Int = #line) {
    #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        let consoleStr = "\(fileName) : line\(line) \(function) | \(message)" 
        print(consoleStr)
        let dformatter = DateFormatter()
        dformatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let datestr = dformatter.string(from: Date())
        let cachePath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let logURL = cachePath.appendingPathComponent("skylinkLog.txt")
        appendText(fileURL: logURL, string: "\(datestr) \(consoleStr)")
    #endif
}

/// 在文件末尾追加新内容
///
/// - Parameters:
///   - fileURL: <#fileURL description#>
///   - string: <#string description#>
func appendText(fileURL: URL, string: String) {
    do {
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        }
        let fileHandle = try FileHandle(forWritingTo: fileURL)
        let stringToWrite = "\n" + string
        fileHandle.seekToEndOfFile()
        fileHandle.write(stringToWrite.data(using: String.Encoding.utf8)!)
    } catch {
        print("failed to append: \(error.localizedDescription)")
    }
}


extension UIAlertController {
    class func showAlertWithAutoDisappear(title: String?, message: String, duration: Double, onViewController vc: UIViewController) {
        let alertVc = UIAlertController(title: title, message: message, preferredStyle: .alert)
        vc.present(alertVc, animated: true, completion: {
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: { [weak weakSelf = vc] in
            weakSelf?.presentedViewController?.dismiss(animated: true, completion: {
            })
        })
    }
}

extension Array where Element: Equatable {
    // Remove first collection element that is equal to the given `object`:
    mutating func remove(_ object: Element) {
        if let index = index(of: object) {
            remove(at: index)
        }
    }
}


