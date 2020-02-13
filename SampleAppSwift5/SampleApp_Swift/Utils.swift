//
//  Utils.swift
//  SampleApp_Swift
//
//  Created by Charlie on 6/2/20.
//  Copyright © 2020 Temasys. All rights reserved.
//

import Foundation
func convertToDictionary(text: String) -> [String: Any]? {
    if let data = text.data(using: .utf8) {
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
    }
    return nil
}
func setAudioOutput() {
    if #available(iOS 10.0, *) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: AVAudioSession.Mode.videoChat, options: [.allowBluetooth, .mixWithOthers, .defaultToSpeaker, .duckOthers, .interruptSpokenAudioAndMixWithOthers, .allowBluetoothA2DP, .allowAirPlay])
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("AVAudioSession.sharedInstance setting error ---> ", error.localizedDescription)
        }
    } else {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.allowBluetooth, .mixWithOthers, .defaultToSpeaker, .duckOthers, .interruptSpokenAudioAndMixWithOthers])
            try AVAudioSession.sharedInstance().setMode(.videoChat)
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("AVAudioSession.sharedInstance setting error ---> ", error.localizedDescription)
        }
    }
}

func isBluetoothConnected() -> Bool {
    if let availableInputs = AVAudioSession.sharedInstance().availableInputs {
        for input in availableInputs {
            if input.portType.rawValue.lowercased().contains("bluetooth") { return true }
        }
    }
    return false
}

func switchOutput() {
    var builtInPortDescription = AVAudioSessionPortDescription()
    var bluetoothPortDescription = AVAudioSessionPortDescription()
    var isBluetoothPortDescriptionAssigned = false
    if let availableInputs = AVAudioSession.sharedInstance().availableInputs {
        _ = availableInputs.map {
            if $0.portType == .builtInMic { builtInPortDescription = $0 }
            if $0.portType == .bluetoothHFP || $0.portType == .bluetoothLE || $0.portType == .bluetoothA2DP {
                bluetoothPortDescription = $0
                isBluetoothPortDescriptionAssigned = true
            }
        }
        if let dataSources = builtInPortDescription.dataSources {
            for source in dataSources {
                if source.orientation!.rawValue == AVAudioSession.Location.orientationFront.rawValue || source.orientation!.rawValue == AVAudioSession.Location.orientationBottom.rawValue || source.orientation!.rawValue == AVAudioSession.Location.orientationBack.rawValue {
                    do {
                        try bluetoothPortDescription.setPreferredDataSource(source)
                    } catch {
                        print("bluetoothPortDescription setPreferredDataSource error --->", error.localizedDescription)
                    }
                    break
                }
            }
        }
        do {
            isBluetoothPortDescriptionAssigned ? try AVAudioSession.sharedInstance().setPreferredInput(bluetoothPortDescription) : try AVAudioSession.sharedInstance().setPreferredInput(builtInPortDescription)
        } catch {
            print("bluetoothPortDescription setPreferredInput error --->", error.localizedDescription)
        }
    }
}
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func UIRGBColor(r:CGFloat, g:CGFloat, b:CGFloat) -> UIColor {
    return UIColor(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: 1.0)
}

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
        if let index = firstIndex(of: object) {
            remove(at: index)
        }
    }
}
