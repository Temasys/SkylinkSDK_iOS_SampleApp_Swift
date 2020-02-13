//
//  MessagesViewController.swift
//  SampleApp
//
//  Created by  Temasys on 26/7/17.
//  Copyright © 2017  Temasys. All rights reserved.
//

import UIKit
import AVFoundation

class MessagesViewController: SKConnectableVC, SKYLINKConnectionLifeCycleDelegate, SKYLINKConnectionMessagesDelegate, SKYLINKConnectionRemotePeerDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {

    
    lazy var messages = [[String : Any]]()
    lazy var peers = [String : Any]()
    weak var topView: UIView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var peersButton: UIButton!
    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var encryptKeyTextField: UITextField!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTypeSegmentControl: UISegmentedControl!
    @IBOutlet weak var isPublicSwitch: UISwitch!
    
//MARK: - INIT
    override func initData() {
        super.initData()
        roomName = ROOM_MESSAGES
        nicknameTextField.delegate = self
        messageTextField.delegate = self
        joinRoom()
    }
    override func initUI() {
        super.initUI()
        title = "Messaging"
        updatePeersButtonTitle()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//            let historyMessages = self.skylinkConnection.getPublicMessageHistory()
//            print("history: --->", historyMessages)
//            if !historyMessages.isEmpty {
//                for item in historyMessages {
//                    if let dataStr = item["data"], let dict = convertToDictionary(text: dataStr) {
//                        self.messages.insert(["message" : (dict["timeStamp"] as? String ?? "") + "~~" + (dict["data"]  as? String ?? ""), "isPublic" : true, "peerId" : dict["senderId"] as? String ?? "", "type" : dict["senderId"] as? String ?? ""], at: 0)
//                    }
//                }
//                self.tableView.reloadSections(IndexSet(integer: 0), with: .fade)
//            }
//        }
        messageTypeSegmentControl.selectedSegmentIndex = 1
//        encryptKeyTextField.text = ENCRYPTION_SECRET
    }
    override func initSkylinkConnection() -> SKYLINKConnection {
        let config = SKYLINKConnectionConfig()

        config.setAudioVideoSend(AudioVideoConfig_NO_AUDIO_NO_VIDEO)
        config.setAudioVideoReceive(AudioVideoConfig_NO_AUDIO_NO_VIDEO)
        config.hasP2PMessaging = true
        config.setTimeout(3, skylinkAction: SkylinkAction_CONNECT_TO_ROOM)
//        config.hasDataTransfer = true
//        config.dataChannel = true // for data chanel messages
//        SKYLINKConnection.setVerbose(true)
        if let skylinkConnection = SKYLINKConnection(config: config, callback: nil){
            skylinkConnection.lifeCycleDelegate = self
            skylinkConnection.messagesDelegate = self
            skylinkConnection.remotePeerDelegate = self
            skylinkConnection.enableLogs = true;
//            skylinkConnection.encryptSecret = ENCRYPTION_SECRET
            return skylinkConnection
        }else{
            return SKYLINKConnection()
        }
    }
//MARK: -
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
            dismissVC()
        }
        activityIndicator.stopAnimating()
    }
    
    func connection(_ connection: SKYLINKConnection, didDisconnectWithMessage errorMessage: String!) {
        let alert = UIAlertController(title: "Disconnected", message: errorMessage, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        present(alert, animated: true) { [unowned self] in
            self.dismissVC()
        }
    }
    
    // MARK: SKYLINKConnectionRemotePeerDelegate
    func connection(_ connection: SKYLINKConnection, didConnectWithRemotePeer remotePeerId: String!, userInfo: Any!, hasDataChannel: Bool) {
        var displayNickName = "\(String(describing: remotePeerId ?? "No name"))"
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

    func connection(_ connection: SKYLINKConnection, didReceiveServerMessage message: Any!, isPublic: Bool, timeStamp: Int64, remotePeerId: String!) {
        print("message ---> ", message ?? "nil")
        print("timeStamp ---> ", timeStamp)
        
        if let dict = message as? [String : String], let data = dict["data"] {
            messages.insert(["message" : data, "isPublic" : isPublic, "peerId" : remotePeerId ?? "nil", "type" : "signaling server", "timeStamp": timeStamp, "senderId": dict["senderId"] ?? ""], at: 0)
        } else if let jsonStr = message as? String {
            if let dict = convertToDictionary(text: jsonStr), let data = dict["data"] as? String, let timeStamp = dict["timeStamp"] as? String {
                messages.insert(["message" : timeStamp + "~~" + data, "isPublic" : isPublic, "peerId" : remotePeerId ?? "nil", "type" : "signaling server", "timeStamp": timeStamp, "senderId": dict["senderId"] ?? ""], at: 0)
            } else {
                messages.insert(["message" : message ?? "nil", "isPublic" : isPublic, "peerId" : remotePeerId ?? "nil", "type" : "signaling server", "timeStamp": timeStamp], at: 0)
            }
        } else {
            messages.insert(["message" : message ?? "nil", "isPublic" : isPublic, "peerId" : remotePeerId ?? "nil", "type" : "signaling server", "timeStamp": timeStamp], at: 0)
        }
        tableView.reloadSections(IndexSet(integer: 0), with: .fade)
    }
    
    func connection(_ connection: SKYLINKConnection, didReceiveP2PMessage message: Any!, isPublic: Bool, timeStamp: Int64, remotePeerId: String!) {
        print("P2P message ---> ", message ?? "nil")
        print("P2P timeStamp ---> ", timeStamp)
        if skylinkConnection.localPeerId != remotePeerId {
            messages.insert(["message" : message ?? "nil", "isPublic" : isPublic, "peerId" : remotePeerId ?? "nil", "type" : "P2P", "timeStamp": timeStamp], at: 0)
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
            var userName = message["senderId"]
            if userName == nil{
                userName = peers[message["peerId"] as? String ?? ""] ?? ""
            }
            cell.detailTextLabel?.text = "From \(userName as! String) via \(message["type"] as? String ?? "") • \(message["isPublic"] as? Bool ?? false ? "Public" : "Private")"
            cell.backgroundColor = .white
            var timeStamp = (message["timeStamp"] as? Int64)
            if timeStamp == nil {
                cell.detailTextLabel?.text = (cell.detailTextLabel?.text ?? "") + "\n" + (message["timeStamp"] as? String ?? "")
            }else{
                timeStamp = (timeStamp ?? 0)/1000
                let timeStampDate = Date(timeIntervalSince1970: TimeInterval(timeStamp!))
                let timeStampString = Date.skylinkString(from: timeStampDate) ?? ""
                cell.detailTextLabel?.text = (cell.detailTextLabel?.text ?? "") + "\n" + timeStampString
            }
        }
        cell.detailTextLabel?.text = (cell.detailTextLabel?.text ?? "")
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
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
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
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.0'Z'"
        let dateString = dateFormatter.string(from: Date())
//        let newMessage = ["timeStamp" : dateString, "senderId" : "iOS-\(UIDevice.current.name)", "data" : message]
        switch messageTypeSegmentControl.selectedSegmentIndex {
        case 0:
            skylinkConnection.sendP2PMessage(message, toRemotePeerId: peerId, callback: nil)
            skylinkLog("Finish DCMessage")
        case 1:
            skylinkConnection.sendServerMessage(message, toRemotePeerId: peerId, callback: nil)
            break
        case 2:
            if peerId != nil {
                let data = message.data(using: .utf8)
                if data != nil {
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
    func textFieldDidChangeSelection(_ textField: UITextField) {
        print("change")
        if textField == encryptKeyTextField{
            ENCRYPTION_SECRET = textField.text!
//            skylinkConnection.encryptSecret = ENCRYPTION_SECRET
        }
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
