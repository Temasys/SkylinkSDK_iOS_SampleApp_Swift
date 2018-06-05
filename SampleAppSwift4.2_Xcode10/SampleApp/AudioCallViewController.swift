//
//  AudioCallViewController.swift
//  SampleApp
//
//  Created by Yuxi on 26/7/17.
//  Copyright © 2017 Yuxi. All rights reserved.
//

import UIKit

class AudioCallViewController: UIViewController, SKYLINKConnectionLifeCycleDelegate, SKYLINKConnectionMediaDelegate, SKYLINKConnectionRemotePeerDelegate, UITableViewDataSource, UITableViewDelegate {

    let ROOM_NAME = ROOM_AUDIO

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var muteMicrophone: UIButton!
    
    var remotePeerArray = [[String : Any]]()
    
    lazy var skylinkConnection: SKYLINKConnection = {
        let config = SKYLINKConnectionConfig()
        config.video = false
        config.audio = true
        SKYLINKConnection.setVerbose(true)
        if let skylinkConnection = SKYLINKConnection(config: config, appKey: skylinkApiKey) {
            skylinkConnection.lifeCycleDelegate = self
            skylinkConnection.mediaDelegate = self
            skylinkConnection.remotePeerDelegate = self
            return skylinkConnection
        } else {
            return SKYLINKConnection()
        }
    }()
    
    let skylinkApiKey = SKYLINK_APP_KEY
    let skylinkApiSecret = SKYLINK_SECRET
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupInfo()
    }

    fileprivate func setupUI() {
        title = "Audio Call"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Cancel"), style: .plain, target: self, action: #selector(disconnect))
        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(showInfo), for: UIControl.Event.touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
    }
    
    fileprivate func setupInfo() {
        let credInfos: [String : Any] = ["startTime": Date(), "duration": 24.0]
        skylinkLog("This is credInfos \(credInfos.description)")
        if let durationString = credInfos["duration"] as? Double {
            let credential = SKYLINKConnection.calculateCredentials(ROOM_NAME, duration: NSNumber(value: durationString), startTime: credInfos["startTime"] as? Date ?? Date(), secret: skylinkApiSecret)
            skylinkLog("This is Credential \(durationString)")
            skylinkConnection.connectToRoom(withCredentials: ["credential": credential, "startTime": credInfos["startTime"] ?? Date(), "duration": credInfos["duration"] ?? 0.0], roomName: ROOM_NAME, userInfo: "Audio call user #\(arc4random() % 1000) - iOS \(UIDevice.current.systemVersion)")
        }
    }
    
    @objc fileprivate func disconnect() {
        skylinkConnection.disconnect { [weak weakSelf = self] in
            weakSelf?.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc fileprivate func showInfo() {
        let title = "\(NSStringFromClass(AudioCallViewController.self)) infos"
        let message = "\nRoom name:\n\(ROOM_NAME)\n\nLocal ID:\n\(skylinkConnection.myPeerId ?? "")\n\nKey: •••••" + (skylinkApiKey as NSString).substring(with: NSRange(location: 0, length: skylinkApiKey.count - 7)) + "\n\nSkylink version \(SKYLINKConnection.getSkylinkVersion())"
        let infosAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        infosAlert.addAction(cancelAction)
        present(infosAlert, animated: true, completion: nil)
    }
    
    // MARK: - SKYLINKConnectionLifeCycleDelegate
    func connection(_ connection: SKYLINKConnection, didConnectWithMessage errorMessage: String!, success isSuccess: Bool) {
        if isSuccess {
            skylinkLog("Inside \(#function)")
        } else {
            let alert = UIAlertController(title: "Connection failed", message: errorMessage, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(cancelAction)
            present(alert, animated: true, completion: nil)
        }
        DispatchQueue.main.async { [weak weakSelf = self] in
            weakSelf?.activityIndicator.stopAnimating()
            weakSelf?.muteMicrophone.isEnabled = true
        }
    }
    
    func connection(_ connection: SKYLINKConnection, didDisconnectWithMessage errorMessage: String!) {
        let alert = UIAlertController(title: "Disconnected", message: errorMessage, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        present(alert, animated: true) { [weak weakSelf = self] in
            weakSelf?.disconnect()
        }
    }
    
    // MARK: - SKYLINKConnectionMediaDelegate
    func connection(_ connection: SKYLINKConnection, didToggleAudio isMuted: Bool, peerId: String!) {
        for (index, peerDic) in remotePeerArray.enumerated() {
            if let id = peerDic["id"] as? String, id == peerId {
                remotePeerArray.remove(at: index)
                remotePeerArray.append(["id": peerId, "isAudioMuted": isMuted])
            }
        }
        tableView.reloadData()
    }
    
    // MARK: - SKYLINKConnectionRemotePeerDelegate
    func connection(_ connection: SKYLINKConnection, didJoinPeer userInfo: Any!, mediaProperties pmProperties: SKYLINKPeerMediaProperties!, peerId: String!) {
        skylinkLog("Peer with id %@ joigned the room.peerId")
        remotePeerArray.append(["id" : peerId, "isAudioMuted" : pmProperties.isAudioMuted, "nickname" : userInfo is String ? userInfo : ""])
        tableView.reloadData()
    }
    
    func connection(_ connection: SKYLINKConnection, didLeavePeerWithMessage errorMessage: String!, peerId: String!) {
        skylinkLog("Peer with id \(peerId) left the room with message: \(errorMessage)")
        var dicToRemove = [String : Any]()
        var idx = 0
        for (index, peerDic) in remotePeerArray.enumerated() {
            if let id = peerDic["id"] as? String, id == peerId {
                dicToRemove = peerDic
                idx = index
            }
        }
        if !remotePeerArray.isEmpty {
            remotePeerArray.remove(at: idx)
            tableView.reloadData()
        }
    }
    
    // MARK: - Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return remotePeerArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ACpeerCell", for: indexPath)
        let peerDic = remotePeerArray[indexPath.row]
        skylinkLog("PeerDic,id: \(peerDic["id"] as? String ?? "" )")
        cell.textLabel?.text = peerDic["nickname"] != nil ? peerDic["nickname"] as! String : "Peer \(indexPath.row)"
        cell.detailTextLabel?.text = "ID: \(peerDic["id"] ?? "") \((peerDic["isAudioMuted"] as? Bool) == true ? " - Audio muted" : "")"
        cell.backgroundColor = UIRGBColor(r: 0.35, g: 0.35, b: 0.35)
        return cell
    }
    
    // MARK: - Table view delegate
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "\(remotePeerArray.count) peer(s) connected"
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @IBAction func switchAudioTap(sender: AnyObject) {
        sender.setTitle(!skylinkConnection.isAudioMuted() ? "Unmute microphone" : "Mute microphone", for: UIControl.State.normal)
        skylinkConnection.muteAudio(!skylinkConnection.isAudioMuted())
    }
}
