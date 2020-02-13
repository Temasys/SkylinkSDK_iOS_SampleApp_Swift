//
//  AudioCallViewController.swift
//  SampleApp
//
//  Created by  Temasys on 26/7/17.
//  Copyright © 2017  Temasys. All rights reserved.
//

import UIKit

class AudioCallViewController: SKConnectableVC, SKYLINKConnectionLifeCycleDelegate, SKYLINKConnectionMediaDelegate, SKYLINKConnectionRemotePeerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var muteMicrophone: UIButton!
    
    var remotePeerArray = [[String : Any]]()
    var remotePeerIdArray = [String]()
    
//MARK: - INIT
    override func initData() {
        super.initData()
        roomName = ROOM_AUDIO
        let credInfos: [String : Any] = ["startTime": Date(), "duration": 24.0]
        skylinkLog("This is credInfos \(credInfos.description)")
        if let _ = credInfos["duration"] as? Double {
            joinRoom()
        }
    }
    override func initUI() {
        title = "Audio Call"
    }
    override func initSkylinkConnection() -> SKYLINKConnection {
        let config = SKYLINKConnectionConfig()
        config.setAudioVideoSend(AudioVideoConfig_AUDIO_ONLY)
        config.setAudioVideoReceive(AudioVideoConfig_AUDIO_ONLY)
        if let skylinkConnection = SKYLINKConnection(config: config, callback: nil) {
            
            skylinkConnection.lifeCycleDelegate = self
            skylinkConnection.mediaDelegate = self
            skylinkConnection.remotePeerDelegate = self
            skylinkConnection.enableLogs = true
            return skylinkConnection
        } else {
            return SKYLINKConnection()
        }
    }
    
    // MARK: - SKYLINKConnectionLifeCycleDelegate
    func connectionDidConnect(toRoomSuccessful connection: SKYLINKConnection) {
        DispatchQueue.main.async { [weak weakSelf = self] in
            weakSelf?.activityIndicator.stopAnimating()
            weakSelf?.muteMicrophone.isEnabled = true
            weakSelf?.startLocalAudio()
        }
        DispatchQueue.main.async { [weak weakSelf = self] in
            weakSelf?.activityIndicator.stopAnimating()
            weakSelf?.muteMicrophone.isEnabled = true
            weakSelf?.startLocalAudio()
        }
    }
    
    
    
    func connection(_ connection: SKYLINKConnection, didConnectToRoomFailed errorMessage: String!) {
        let alert = UIAlertController(title: "Connection failed", message: errorMessage, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - SKYLINKConnectionMediaDelegate
    func connection(_ connection: SKYLINKConnection, didToggleAudio isMuted: Bool, peerId: String!) {
        for (index, peerDic) in remotePeerArray.enumerated() {
            if let id = peerDic["id"] as? String, id == peerId {
                remotePeerArray.remove(at: index)
                remotePeerArray.append(["id": peerId ?? "nil", "isAudioMuted": isMuted])
            }
        }
        tableView.reloadData()
    }
    
    // MARK: - SKYLINKConnectionRemotePeerDelegate
    
    func connection(_ connection: SKYLINKConnection, didReceiveRemotePeerInRoomWithRemotePeerId remotePeerId: String, userInfo: Any!) {
        if remotePeerId != skylinkConnection.localPeerId && !remotePeerIdArray.contains(remotePeerId) {
            remotePeerArray.append(["id": remotePeerId, "isAudioMuted": false])
            remotePeerIdArray.append(remotePeerId)
        }
        tableView.reloadData()
    }
    
    func connection(_ connection: SKYLINKConnection, didReceiveRemotePeerLeaveRoom remotePeerId: String!, userInfo: Any!, skylinkInfo: [AnyHashable : Any]?) {
        for (index, peerDic) in remotePeerArray.enumerated() {
            if let id = peerDic["id"] as? String, id == remotePeerId {
                remotePeerArray.remove(at: index)
            }
        }
        remotePeerIdArray.remove(remotePeerId)
        tableView.reloadData()
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
        sender.setTitle(!skylinkConnection.isAudioMuted() ? "Unmute microphone" : "Mute microphone", for: .normal)
        skylinkConnection.muteAudio(!skylinkConnection.isAudioMuted())
    }
    
    fileprivate func startLocalAudio() {
        skylinkConnection.createLocalMedia(with: SKYLINKMediaDeviceMicrophone, mediaMetadata: USER_NAME, callback: nil);
    }
    
    func connection(_ connection: SKYLINKConnection, didChange skylinkMedia: SKYLINKMedia, peerId: String!) {
        if skylinkMedia.skylinkMediaType() == SKYLINKMediaTypeAudio {
            
        }
    }
}
