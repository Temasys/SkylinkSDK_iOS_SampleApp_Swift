//
//  AppDelegate.swift
//  SampleApp
//
//  Created by  Temasys on 26/7/17.
//  Copyright © 2017  Temasys. All rights reserved.
//

import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func applicationDidFinishLaunching(_ application: UIApplication) {
        #if DEBUG
        #else
        signal(SIGPIPE, SIG_IGN)
        #endif
        print("NSTemporaryDirectory ---> ", NSTemporaryDirectory())
        createFolder()
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        skylinkLog("applicationDidEnterBackground ~~~ started")
        backgroundStarted()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    fileprivate func registerDefaultsFromSettingsBundle() {
        guard let settingsBundle = Bundle.main.path(forResource: "Settings", ofType: "bundle") else {
            skylinkLog("Could not find Settings.bundle")
            return
        }
        
        if let settings = NSDictionary(contentsOfFile: (settingsBundle as NSString).appendingPathComponent("Root.plist")) as? [String : AnyObject], let preferences = settings["PreferenceSpecifiers"] as? [[String : String]] {
            var defaultsToRegister: [String : Any] = Dictionary(minimumCapacity: preferences.count)
            for prefSpecification in preferences {
                if let key = prefSpecification["Key"] {
                    // check if value readable in userDefaults
                    let currentObject = UserDefaults.standard.object(forKey: "Key")
                    if currentObject == nil {
                        // not readable: set value from Settings.bundle
                        let objectToSet = prefSpecification["DefaultValue"]
                        defaultsToRegister[key] = objectToSet
                    } else {
                        // already readable
                        skylinkLog("Key \(key) is readable (value: \(String(describing: currentObject)), nothing written to defaults.")
                    }
                }
            }
            UserDefaults.standard.register(defaults: defaultsToRegister)
        }
    }
    
    fileprivate func createFolder() {
        do {
            let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            appFilesFolder = (documentDirectory as NSString).appendingPathComponent("app_files")
            if !FileManager.default.fileExists(atPath: appFilesFolder) {
                try FileManager.default.createDirectory(at: URL(fileURLWithPath: appFilesFolder), withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
            skylinkLog(error.localizedDescription)
        }
    }
    
    func backgroundStarted() {
        var bgtask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier(rawValue: 0)
        bgtask = UIBackgroundTaskIdentifier(rawValue: convertFromUIBackgroundTaskIdentifier(UIApplication.shared.beginBackgroundTask(expirationHandler: {
            DispatchQueue.main.async {
                if bgtask.rawValue != convertFromUIBackgroundTaskIdentifier(UIBackgroundTaskIdentifier.invalid) {
                    bgtask = UIBackgroundTaskIdentifier(rawValue: convertFromUIBackgroundTaskIdentifier(UIBackgroundTaskIdentifier.invalid))
                }
            }
        })))
        DispatchQueue.global(qos: .default).async {
            DispatchQueue.main.async {
                if bgtask.rawValue != convertFromUIBackgroundTaskIdentifier(UIBackgroundTaskIdentifier.invalid) {
                    bgtask = UIBackgroundTaskIdentifier(rawValue: convertFromUIBackgroundTaskIdentifier(UIBackgroundTaskIdentifier.invalid))
                }
            }
        }
    }
    
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIBackgroundTaskIdentifier(_ input: UIBackgroundTaskIdentifier) -> Int {
    return input.rawValue
}
