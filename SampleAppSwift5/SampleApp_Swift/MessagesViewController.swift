//
//  MessagesViewController.swift
//  SampleApp
//
//  Created by  Temasys on 26/7/17.
//  Copyright © 2017  Temasys. All rights reserved.
//

import UIKit
import AVFoundation
import SKYLINK

class MessagesViewController: UIViewController, SKYLINKConnectionLifeCycleDelegate, SKYLINKConnectionMessagesDelegate, SKYLINKConnectionRemotePeerDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {

    
    let ROOM_NAME = ROOM_MESSAGES
    lazy var messages = [[String : Any]]()
    lazy var peers = [String : Any]()
    let skylinkApiKey = SKYLINK_APP_KEY
    let skylinkApiSecret = SKYLINK_SECRET
    weak var topView: UIView!
    lazy var skylinkConnection: SKYLINKConnection = {
        let config = SKYLINKConnectionConfig()

        config.setAudioVideoSend(AudioVideoConfig_NO_AUDIO_NO_VIDEO)
        config.setAudioVideoReceive(AudioVideoConfig_NO_AUDIO_NO_VIDEO)
        config.hasP2PMessaging = true
//        config.hasDataTransfer = true
//        config.dataChannel = true // for data chanel messages
//        SKYLINKConnection.setVerbose(true)
        if let skylinkConnection = SKYLINKConnection(config: config, callback: nil){
            skylinkConnection.lifeCycleDelegate = self
            skylinkConnection.messagesDelegate = self
            skylinkConnection.remotePeerDelegate = self
            skylinkConnection.enableLogs = true;
            return skylinkConnection
        }else{
            return SKYLINKConnection()
        }
    }()
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var peersButton: UIButton!
    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTypeSegmentControl: UISegmentedControl!
    @IBOutlet weak var isPublicSwitch: UISwitch!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupInfo()
    }
    
    fileprivate func setupUI() {
        nicknameTextField.delegate = self
        messageTextField.delegate = self
        skylinkLog("SKYLINKConnection version = \(SKYLINKConnection.getSkylinkVersion())")
        title = "Messages"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Cancel"), style: .plain, target: self, action: #selector(disconnect))
        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(showInfo), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
        updatePeersButtonTitle()
    }
    
    fileprivate func setupInfo() {
//        skylinkConnection.connectToRoom(withSecret: skylinkApiSecret, roomName: ROOM_NAME, userInfo: nil)
        skylinkConnection.connectToRoom(withAppKey: skylinkApiKey, secret: skylinkApiSecret, roomName: ROOM_NAME, userData: USER_NAME, callback: nil)
    }
    
    @objc fileprivate func disconnect() {
        skylinkConnection.disconnect({[unowned self] error in
            guard let _ = error else{
                self.navigationController?.popViewController(animated: true)
                return
            }
        })
    }
    
    @objc fileprivate func showInfo() {
        let title = "Infos"
        let message = "\nRoom name:\n\(ROOM_NAME)\n\nLocal ID:\n\(skylinkConnection.localPeerId ?? "")\n\nKey: •••••" + (skylinkApiKey as NSString).substring(with: NSRange(location: 0, length: skylinkApiKey.count - 7)) + "\n\nSkylink version \(SKYLINKConnection.getSkylinkVersion())"
//        alertMessage(msg_title: title, msg: message)
        let alertController = UIAlertController(title: title , message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(OKAction)
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func alertMessage(msg_title: String, msg:String) {
        let alertController = UIAlertController(title: msg_title , message: msg, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(OKAction)
        present(alertController, animated: true) {
            self.sendMessage(message: msg_title, forPeerId: msg)
        }
    }
    
    // MARK: SKYLINKConnectionLifeCycleDelegate
    func connectionDidConnect(toRoomSuccessful connection: SKYLINKConnection){
        skylinkLog("Inside \(#function)")
        DispatchQueue.main.async { [unowned self] in
            self.messageTextField.isEnabled = true
            self.messageTextField.isHidden = false
            self.nicknameTextField.isEnabled = true
            self.nicknameTextField.isHidden = false
            self.sendButton.isEnabled = true
            self.sendButton.isHidden = false
            self.messageTextField.becomeFirstResponder()
        }
        self.activityIndicator.stopAnimating()
    }
    func connection(_ connection: SKYLINKConnection, didConnectWithMessage errorMessage: String!, success isSuccess: Bool) {
        if isSuccess {
            skylinkLog("Inside \(#function)")
            DispatchQueue.main.async { [weak weakSelf = self] in
                weakSelf?.messageTextField.isEnabled = true
                weakSelf?.messageTextField.isHidden = false
                weakSelf?.nicknameTextField.isEnabled = true
                weakSelf?.nicknameTextField.isHidden = false
                weakSelf?.sendButton.isEnabled = true
                weakSelf?.sendButton.isHidden = false
                weakSelf?.messageTextField.becomeFirstResponder()
            }
        } else {
            let msgTitle = "Connection failed"
            let msg = errorMessage
            alertMessage(msg_title: msgTitle, msg:msg!)
            disconnect()
        }
        activityIndicator.stopAnimating()
    }
    
    func connection(_ connection: SKYLINKConnection, didDisconnectWithMessage errorMessage: String!) {
        let alert = UIAlertController(title: "Disconnected", message: errorMessage, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        present(alert, animated: true) { [weak weakSelf = self] in
            weakSelf?.disconnect()
        }
    }
    
    // MARK: SKYLINKConnectionRemotePeerDelegate
    func connection(_ connection: SKYLINKConnection, didConnectWithRemotePeer remotePeerId: String!, userInfo: Any!, hasDataChannel: Bool) {
        var displayNickName = "ID: \(String(describing: remotePeerId ?? "No name"))"
        if let dict = userInfo as? [String : Any], let name = dict["nickname"] as? String {
            displayNickName = name
        }
        if remotePeerId != nil {
            peers[remotePeerId] = displayNickName
            updatePeersButtonTitle()
        }
        tableView.reloadData()
        self.activityIndicator.stopAnimating()
    }
    
    func connection(_ connection: SKYLINKConnection, didReceiveRemotePeerLeaveRoom remotePeerId: String!, userInfo: Any!, skylinkInfo: [AnyHashable : Any]?) {
        peers.removeValue(forKey: remotePeerId)
        updatePeersButtonTitle()
    }
    
    // MARK: SKYLINKConnectionMessagesDelegate

    func connection(_ connection: SKYLINKConnection, didReceiveServerMessage message: Any!, isPublic: Bool, remotePeerId peerId: String!) {
        if skylinkConnection.localPeerId != peerId {
             messages.insert(["message" : message ?? "nil", "isPublic" : isPublic, "peerId" : peerId ?? "nil", "type" : "signaling server"], at: 0)
                   tableView.reloadSections(IndexSet(integer: 0), with: .fade)
        }
    }
    
    func connection(_ connection: SKYLINKConnection, didReceiveP2PMessage message: Any!, isPublic: Bool, remotePeerId peerId: String!) {
        if skylinkConnection.localPeerId != peerId {
            messages.insert(["message" : message ?? "nil", "isPublic" : isPublic, "peerId" : peerId ?? "nil", "type" : "P2P"], at: 0)
            tableView.reloadSections(IndexSet(integer: 0), with: .fade)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath)
        let message = messages[indexPath.row]
        cell.textLabel?.text = message["message"] as? String
        let equalStr = skylinkConnection.localPeerId
        if message["peerId"] as? String == equalStr {
            cell.detailTextLabel?.text = (message["isPublic"] as? Bool ?? false) ? "Sent to all" : "Sent privately"
            cell.backgroundColor = .lightText// UIRGBColor(r: 0.71, g: 1, b: 0.5)
        } else {
            cell.detailTextLabel?.text = "From \(peers[message["peerId"] as? String ?? ""] ?? "") via \(message["type"] as? String ?? "") • \(message["isPublic"] as? Bool ?? false ? "Public" : "Private")"
            cell.backgroundColor = .white
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let message = messages[indexPath.row]
        let messageDetails = String(format:"Message \n %@ \n\n From: \n %@ \n\n %@", message["message"] as? String ?? "", (message["peerId"] as? String ?? "") == (skylinkConnection.localPeerId as String) ? "me" : (message["peerId"] as? String ?? ""), (message["isPublic"] as? Bool ?? false) ? "Public" : "Private")
        let msgTitle = "Message Details"
        let msg = messageDetails
        alertMessage(msg_title: msgTitle, msg: msg)
    }
    
    // MARK: - Utils
    func processMessage() {
        if isPublicSwitch.isOn && messageTypeSegmentControl.selectedSegmentIndex == 2 {
            let msgTitle = "Binary data is private."
            let msg = "\nTo send your message as binary data, uncheck the \"Public\" UISwitch."
            alertMessage(msg_title: msgTitle, msg: msg)
            hideKeyboardIfNeeded()
        } else if messageTextField.hasText {
            let message = messageTextField.text
            if !(isPublicSwitch.isOn) {
                if peers.count != 0 {
                    let alert = UIAlertController(title: "Choose a private recipient.", message: "\nYou're about to send a private message\nWho do you want to send it to ?", preferredStyle: .alert)
                    let noAction = UIAlertAction(title: "Cancel", style: .default)
                    for peerDicKey in peers.keys {
                        let yesAction = UIAlertAction(title: peers[peerDicKey] as? String, style: .default) { [weak weakSelf = self] _ in
                            weakSelf?.alertMessage(msg_title: message ?? "", msg: peerDicKey)
                        }
                        alert.addAction(yesAction)
                    }
                    alert.addAction(noAction)
                    present(alert, animated: true, completion: nil)
                } else {
                    let msgTitle = "No peer connected."
                    let msg = "\nYou can't define a private recipient since there is no peer connected."
                    alertMessage(msg_title: msgTitle, msg: msg)
                }
            } else {
                sendMessage(message: message ?? "", forPeerId: nil)
            }
        } else {
            let msgTitle = "Empty message"
            let msg = "\nType the message to be sent."
            alertMessage(msg_title: msgTitle, msg: msg)
        }
    }
    
    func sendMessage(message: String, forPeerId peerId: String?) {
        print("send message: \(message)")
        print("to peer: \(peerId ?? "")")
        var showSentMessage = true
        switch messageTypeSegmentControl.selectedSegmentIndex {
        case 0:
//            skylinkConnection.sendDCMessage(message, peerId: peerId)
            skylinkConnection.sendP2PMessage(message, toRemotePeerId: peerId, callback: nil)
            skylinkLog("Finish DCMessage")
        case 1:
//            skylinkConnection.sendCustomMessage(message, peerId: peerId)
            skylinkConnection.sendServerMessage(message, toRemotePeerId: peerId, callback: nil)
            break
        case 2:
            if peerId != nil {
                let data = message.data(using: .utf8)
                if data != nil {
//                    skylinkConnection.sendBinaryData(data, peerId: peerId)
//                    skylinkConnection.sendData(toRemotePeerId: peerId, data: data, callback: nil)
                    skylinkConnection.send(data, toRemotePeerId: peerId, callback: nil)
                } else {
                    let msgTitle = "Exeption when sending binary data"
                    let msg = "MCU can be enabled/disabled in Key configuration on the developer portal: http://developer.temasys.com.sg/"
                    alertMessage(msg_title: msgTitle, msg: msg)
                    showSentMessage = false
                }
            }
        default:
            break
        }
        if showSentMessage {
            messageTextField.text = ""
            messages.insert(["message": message, "isPublic": peerId == nil, "peerId": skylinkConnection.localPeerId ?? "nil"], at: 0)
            tableView.reloadSections(IndexSet(integer: 0), with: .fade)
        } else {
            hideKeyboardIfNeeded()
        }
    }
    
    fileprivate func updatePeersButtonTitle() {
        let peersCount = peers.count
        if peersCount == 0 {
            peersButton.setTitle("No Peer", for: .normal)
        } else {
            peersButton.setTitle("\(peersCount) peer" + (peersCount > 1 ? "s " : ""), for: .normal)
        }
    }
    
    func updateNickname() {
        if nicknameTextField.hasText {
//            skylinkConnection.sendUserInfo(["nickname" : nicknameTextField.text])
            skylinkConnection.sendLocalUserData(["nickname" : nicknameTextField.text], callback: nil)
        } else {
            let msgTitle = "Empty nickname"
            let msg = "\nType the nickname to set."
            alertMessage(msg_title: msgTitle, msg: msg)
        }
    }
    
    func hideKeyboardIfNeeded() {
        messageTextField.resignFirstResponder()
        nicknameTextField.resignFirstResponder()
    }
    
    // MARK: - UITextField delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nicknameTextField {
            updateNickname()
        } else if textField == messageTextField {
            processMessage()
        }
        hideKeyboardIfNeeded()
        return true
    }
    
    // MARK: IBFuction
    @IBAction func sendTap() {
        processMessage()
    }
    
    @IBAction func diswmissKeyboardTap() {
        hideKeyboardIfNeeded()
    }
    
    @IBAction func peersTap(sender: UIButton) {
        let msgTitle = sender.titleLabel?.text
        let msg = peers.keys.description
        let alertController = UIAlertController(title: msgTitle , message: msg, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(OKAction)
        present(alertController, animated: true) {
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
}
