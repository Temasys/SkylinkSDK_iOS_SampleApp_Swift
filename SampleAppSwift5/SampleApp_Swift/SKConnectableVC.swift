//
//  SKConnectableVC.swift
//  SampleApp_Swift
//
//  Created by Charlie on 3/12/19.
//  Copyright © 2019 Temasys. All rights reserved.
//

import Foundation

class SKConnectableVC: UIViewController {
    var roomName: String = ""
    var userName: String = ""
    lazy var skylinkConnection: SKYLINKConnection = {
        return initSkylinkConnection()
    }()
    
//MARK: - INIT
    func initSkylinkConnection() -> SKYLINKConnection{
        return SKYLINKConnection()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        initData()
        initUI()
    }
    func initUI(){
        skylinkLog("SKYLINKConnection version = \(SKYLINKConnection.getSkylinkVersion())")
        title = String(describing: type(of: self))
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Cancel"), style: .plain, target: self, action: #selector(dismissVC))
        
        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(showInfo), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
    }
    func initData(){
        roomName = ROOM_NAME
        userName = USER_NAME
    }
    
//MARK: - Navigation action
    @objc fileprivate func showInfo() {
        let title = String(describing: type(of: self)) + " infos"
        let message = "\nRoom name:\n\(roomName)\n\nLocal ID:\n\(skylinkConnection.localPeerId ?? "")\n\nKey: •••••" + (APP_KEY as NSString).substring(with: NSRange(location: 0, length: APP_KEY.count - 7)) + "\n\nSkylink version \(SKYLINKConnection.getSkylinkVersion())"
        let infosAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        infosAlert.addAction(cancelAction)
        present(infosAlert, animated: true, completion: nil)
    }
    @objc func dismissVC() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        leaveRoom {
            skylinkLog("viewControllers before:\(String(describing: self.navigationController!.viewControllers))")
            self.navigationController?.popViewController(animated: true)
            skylinkLog("viewControllers after:\(String(describing: self.navigationController!.viewControllers))")
        }
    }
//MARK: - ROOM
    func joinRoom(){
        skylinkConnection.connectToRoom(withAppKey: SKYLINK_APP_KEY, secret: SKYLINK_SECRET, roomName: roomName, userData: userName, callback: nil)
    }
    func leaveRoom(complete:@escaping ()->()){
        skylinkConnection.disconnect { error in
            guard let _ = error else{
                complete()
                return
            }
        }
    }
}
