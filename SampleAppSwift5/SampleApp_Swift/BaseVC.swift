//
//  BaseVC.swift
//  SampleApp_Swift
//
//  Created by Charlie on 3/12/19.
//  Copyright © 2019 Temasys. All rights reserved.
//

import Foundation
import UIKit
import SKYLINK

class BaseVC: UIViewController {
    var _roomName: String = ""
    lazy var _skylinkConnection: SKYLINKConnection = {
        return initSkylinkConnection()
    }()
    func initSkylinkConnection() -> SKYLINKConnection{
        return SKYLINKConnection()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }
    func initUI(){
        title = String(describing: type(of: self))
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Cancel"), style: .plain, target: self, action: #selector(disconnect))
        
        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(showInfo), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
    }
    @objc fileprivate func showInfo() {
        let title = String(describing: type(of: self)) + " infos"
        let message = "\nRoom name:\n\(_roomName)\n\nLocal ID:\n\(_skylinkConnection.localPeerId ?? "")\n\nKey: •••••" + (APP_KEY as NSString).substring(with: NSRange(location: 0, length: APP_KEY.count - 7)) + "\n\nSkylink version \(SKYLINKConnection.getSkylinkVersion())"
        let infosAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        infosAlert.addAction(cancelAction)
        present(infosAlert, animated: true, completion: nil)
    }
    @objc fileprivate func disconnect() {
        _skylinkConnection.disconnect { [unowned self] error in
            guard let _ = error else{
                skylinkLog("viewControllers before:\(String(describing: self.navigationController!.viewControllers))")
                self.navigationController?.popViewController(animated: true)
                skylinkLog("viewControllers after:\(String(describing: self.navigationController!.viewControllers))")
                return
            }
        }
    }
}
