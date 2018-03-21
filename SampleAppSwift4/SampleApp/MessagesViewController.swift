//
//  MessagesViewController.swift
//  SampleApp
//
//  Created by Yuxi on 26/7/17.
//  Copyright © 2017 Yuxi. All rights reserved.
//

import UIKit
import AVFoundation

class MessagesViewController: UIViewController, SKYLINKConnectionLifeCycleDelegate, SKYLINKConnectionMessagesDelegate, SKYLINKConnectionRemotePeerDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {

    
    let ROOM_NAME = ROOM_MESSAGES
    lazy var messages = [[String : Any]]()
    lazy var peers = [String : Any]()
    let skylinkApiKey = SKYLINK_APP_KEY
    let skylinkApiSecret = SKYLINK_SECRET
    weak var topView: UIView!
    lazy var skylinkConnection: SKYLINKConnection = {
        let config = SKYLINKConnectionConfig()
        config.video = false
        config.audio = false
        config.fileTransfer = false
        config.dataChannel = true // for data chanel messages
        SKYLINKConnection.setVerbose(true)
        if let skylinkConnection = SKYLINKConnection(config: config, appKey: skylinkApiKey) {
            skylinkConnection.lifeCycleDelegate = self
            skylinkConnection.messagesDelegate = self
            skylinkConnection.remotePeerDelegate = self
            return skylinkConnection
        } else {
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
        skylinkConnection.connectToRoom(withSecret: skylinkApiSecret, roomName: ROOM_NAME, userInfo: nil)
    }
    
    @objc fileprivate func disconnect() {
        skylinkConnection.disconnect { [weak weakSelf = self] in
            weakSelf?.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc fileprivate func showInfo() {
        let title = "Infos"
        let message = "\nRoom name:\n\(ROOM_NAME)\n\nLocal ID:\n\(skylinkConnection.myPeerId ?? "")\n\nKey: •••••" + (skylinkApiKey as NSString).substring(with: NSRange(location: 0, length: skylinkApiKey.count - 7)) + "\n\nSkylink version \(SKYLINKConnection.getSkylinkVersion())"
        alertMessage(msg_title: title, msg: message)
    }
    
    fileprivate func alertMessage(msg_title: String, msg:String) {
        let alertController = UIAlertController(title: msg_title , message: msg, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(OKAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: SKYLINKConnectionLifeCycleDelegate
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
    func connection(_ connection: SKYLINKConnection, didJoinPeer userInfo: Any!, mediaProperties pmProperties: SKYLINKPeerMediaProperties!, peerId: String!) {
        if let dict = userInfo as? [String : Any] {
            var displayNickName = dict["nickname"] as? String
            if displayNickName == nil {
                displayNickName = "ID: \(peerId)"
            }
            peers[peerId] = displayNickName!
        } else if let arr = userInfo as? [Any] {
            print("arr ---> ", arr)
            peers[peerId] = peerId
        } else if let str = userInfo as? String {
            print("str ---> ", str)
            peers[peerId] = peerId
        } else {
            print("Cannot resolve userinfo")
        }
        updatePeersButtonTitle()
    }
    
    func connection(_ connection: SKYLINKConnection, didLeavePeerWithMessage errorMessage: String!, peerId: String!) {
        peers.removeValue(forKey: peerId)
        updatePeersButtonTitle()
    }
    
    func connection(_ connection: SKYLINKConnection, didReceiveUserInfo userInfo: Any!, peerId: String!) {
        peers.removeValue(forKey: peerId)
        if let dict = userInfo as? [String : Any] {
            var displayNickName = dict["nickname"] as? String
            if displayNickName == nil {
                displayNickName = "ID: \(peerId)"
            }
            peers[peerId] = displayNickName!
        } else if let arr = userInfo as? [Any] {
            print("arr ---> ", arr)
            peers[peerId] = peerId
        } else if let str = userInfo as? String {
            print("str ---> ", str)
            peers[peerId] = peerId
        } else {
            print("Cannot resolve userinfo")
        }
        updatePeersButtonTitle()
        tableView.reloadData()
    }
    
    // MARK: SKYLINKConnectionMessagesDelegate
    func connection(_ connection: SKYLINKConnection, didReceiveCustomMessage message: Any!, public isPublic: Bool, peerId: String!) {
        messages.insert(["message" : message, "isPublic" : isPublic, "peerId" : peerId, "type" : "signaling server"], at: 0)
        tableView.reloadSections(IndexSet(integer: 0), with: .fade)
    }
    
    func connection(_ connection: SKYLINKConnection, didReceiveDCMessage message: Any!, public isPublic: Bool, peerId: String!) {
        messages.insert(["message" : message, "isPublic" : isPublic, "peerId" : peerId, "type" : "P2P"], at: 0)
        tableView.reloadSections(IndexSet(integer: 0), with: .fade)
    }
    
    func connection(_ connection: SKYLINKConnection, didReceiveBinaryData data: Data!, peerId: String!) {
        let maybeString = String(data: data, encoding: .utf8)
        messages.insert(["message" : maybeString ?? "Binary data of length \(UInt(data.count))", "isPublic" : false, "peerId" : peerId, "type" : "binary data"], at: 0)
        tableView.reloadSections(IndexSet(integer: 0), with: .fade)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath)
        let aMessage = messages[indexPath.row]
        cell.textLabel?.text = aMessage["message"] as? String ?? ""
        let equalStr = skylinkConnection.myPeerId
        if aMessage["peerId"] as? String == equalStr {
            cell.backgroundColor = .yellow
            cell.detailTextLabel?.text = (aMessage["isPublic"] as? Bool ?? false) ? "Sent to all" : "Sent privately"
        } else {
            cell.detailTextLabel?.text = "From \(peers[aMessage["peerId"] as? String ?? ""] ?? "") via \(aMessage["type"] as? String ?? "") • \(aMessage["isPublic"] as? Bool ?? false ? "Public" : "Private")"
            cell.backgroundColor = .white
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let message = messages[indexPath.row]
        let messageDetails = String(format:"Message \n %@ \n\n From: \n %@ \n\n %@", message["message"] as? String ?? "", (message["peerId"] as? String ?? "") == (skylinkConnection.myPeerId as String) ? "me" : (message["peerId"] as? String ?? ""), (message["isPublic"] as? Bool ?? false) ? "Public" : "Private")
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
        var showSentMessage = true
        switch messageTypeSegmentControl.selectedSegmentIndex {
        case 0:
            skylinkConnection.sendDCMessage(message, peerId: peerId)
            skylinkLog("Finish DCMessage")
        case 1:
            skylinkConnection.sendCustomMessage(message, peerId: peerId)
        case 2:
            if peerId != nil {
                let data = message.data(using: .utf8)
                if data != nil {
                    skylinkConnection.sendBinaryData(data, peerId: peerId)
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
            messages.insert(["message": message, "isPublic": peerId == nil, "peerId": skylinkConnection.myPeerId], at: 0)
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
            skylinkConnection.sendUserInfo(["nickname" : nicknameTextField.text])
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
        let msg = peers.description
        alertMessage(msg_title: msgTitle ?? "", msg: msg)
    }
}
