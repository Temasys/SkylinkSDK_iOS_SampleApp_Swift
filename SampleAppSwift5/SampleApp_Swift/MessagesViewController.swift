//
//  MessagesViewController.swift
//  SampleApp
//
//  Created by  Temasys on 26/7/17.
//  Copyright © 2017  Temasys. All rights reserved.
//

import UIKit
import AVFoundation
import SKYLINK_MESSAGE_CACHE

struct SAMessage {
    var data: String?
    var timeStamp: Int64?
    var sender: String?
    var target: String?
    var type: MessageType?
    
    
    enum MessageType {
        case Signaling
        case P2P
        func toString() -> String{
            switch self {
            case .Signaling:
                return "Signaling"
            default:
                return "P2P"
            }
        }
    }
    
    func isPublic() -> Bool{
        return (target == nil)
    }
    func timeStapmString() -> String?{
        if let timeStamp = timeStamp {
            let dateTS = Date.datefrom(timeStamp: timeStamp)
            return Date.skylinkString(from: dateTS)
        }
        return nil
    }
}
class MessagesViewController: SKConnectableVC, SKYLINKConnectionLifeCycleDelegate, SKYLINKConnectionMessagesDelegate, SKYLINKConnectionRemotePeerDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {

    
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
    @IBOutlet weak var pickerViewContainer: UIView!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var persistSwitch: UISwitch!
    var messages: [SAMessage] = []
    var encryptSecretIds: [String] = ["No Key"]
//MARK: - INIT
    override func initData() {
        super.initData()
        if roomName.count==0{
            roomName = ROOM_MESSAGES
        }
        nicknameTextField.delegate = self
        messageTextField.delegate = self
        joinRoom()
        
    }
    override func initUI() {
        super.initUI()
        title = "Messaging"
        updatePeersButtonTitle()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 70
        loadStoredMessage()
        messageTypeSegmentControl.selectedSegmentIndex = 1
        encryptSecretIds.append(contentsOf: Array(ENCRYPTION_SECRETS.keys).sorted(by:<))
        encryptKeyTextField.text = encryptSecretIds.first
//        skylinkConnection.selectedSecretId = encryptKeyTextField.text
    }
    
    
    override func initSkylinkConnection() -> SKYLINKConnection {
        let config = SKYLINKConnectionConfig()

        config.setAudioVideoSend(AudioVideoConfig_NO_AUDIO_NO_VIDEO)
        config.setAudioVideoReceive(AudioVideoConfig_NO_AUDIO_NO_VIDEO)
        config.hasP2PMessaging = true
        config.setTimeout(3, skylinkAction: SkylinkAction_CONNECT_TO_ROOM)
        config.isMessageCacheEnabled = true;
//        config.hasDataTransfer = true
//        config.dataChannel = true // for data chanel messages
        if let skylinkConnection = SKYLINKConnection(config: config, callback: nil){
            skylinkConnection.lifeCycleDelegate = self
            skylinkConnection.messagesDelegate = self
            skylinkConnection.remotePeerDelegate = self
            skylinkConnection.enableLogs = true;
            skylinkConnection.encryptSecrets = ENCRYPTION_SECRETS
            skylinkConnection.messagePersist = true
            return skylinkConnection
        }else{
            return SKYLINKConnection()
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
            saAlert(title: msgTitle, msg: msg)
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
    func connection(_ connection: SKYLINKConnection, didReceiveError error: Error!) {
        if let error = error {
            saAlert(title: "Error: \(error.code)", msg: error.localizedDescription)
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
        print("SIG message ---> ", message ?? "nil")
        print("SIG timeStamp ---> ", timeStamp)
        
        if let message = message as? String{
            let receivedMessage = SAMessage(data: message,
                                            timeStamp: timeStamp,
                                            sender: self.getUserNameFrom(peerId: remotePeerId),
                                            target: (isPublic ? nil : skylinkConnection.localPeerId),
                                            type: .Signaling)
            messages.append(receivedMessage)
        }
        tableView.reloadSections(IndexSet(integer: 0), with: .fade)
    }
    
    func connection(_ connection: SKYLINKConnection, didReceiveP2PMessage message: Any!, isPublic: Bool, timeStamp: Int64, remotePeerId: String!) {
        print("P2P message ---> ", message ?? "nil")
        print("P2P timeStamp ---> ", timeStamp)
        
        if let message = message as? String{
            let receivedMessage = SAMessage(data: message,
                                            timeStamp: timeStamp,
                                            sender: self.getUserNameFrom(peerId: remotePeerId),
                                            target: (isPublic ? nil : skylinkConnection.localPeerId),
                                            type: .P2P)
            messages.append(receivedMessage)
        }
        tableView.reloadSections(IndexSet(integer: 0), with: .fade)
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath)
        let msg = messages[messages.count - indexPath.row - 1]
        cell.textLabel?.text = (msg.timeStapmString() ?? "") + "~~~" + (msg.data ?? "")
        cell.detailTextLabel?.text = "From \(msg.sender ?? "") via \(msg.type?.toString() ?? "") • " + (msg.isPublic() ? "Public" : "Private")
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let message = messages[messages.count - indexPath.row - 1]
        let msg = String(format:"Message \n %@ \n\n From: \n %@ \n\n %@", message.data ?? "", (message.sender == USER_NAME) ? "me" : (message.sender ?? ""), message.isPublic() ? "Public" : "Private")
        let msgTitle = "Message Details"
        saAlert(title: msgTitle, msg: msg)
    }
    
    // MARK: - Utils
    
    private func loadStoredMessage(){
        // Message caching is enabled?
        if (SkylinkMessageCache.instance().isEnabled) {
            // Display caches messages if available
            DispatchQueue.main.async {
                let cachedMessages = SkylinkMessageCache.instance().getReadableCacheSession(forRoomName: self.roomName).cachedMessages()
                if (!cachedMessages.isEmpty) {
                    for m in cachedMessages {
                        if let dict = m as? [String: Any] {
                            let message = SAMessage(data: dict["data"] as? String,
                                                    timeStamp: (dict["timeStamp"] as? Int64),
                                                    sender: self.getUserNameFrom(peerId: dict["peerId"] as? String),
                                                    target: nil,
                                                    type: .Signaling)
                            self.messages.append(message)
                        }
                    }
                    self.tableView.reloadSections(IndexSet(integer: 0), with: .fade)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.skylinkConnection.getStoredMessages { storedMessages, errorMap in
                guard let _ = self.view.window else{
                    return
                }
                if let errorMap = errorMap{
                    saAlert(title: "Error map", msg: errorMap.description)
                }

                // Remove messages retrieved from cache before append messages from server
                self.messages.removeAll()

                for item in storedMessages ?? []{
                    print("storedMessage: \(storedMessages ?? [])")
                    if let dict = item as? [String: Any] {
                        let message = SAMessage(data: dict["data"] as? String,
                                                timeStamp: (dict["timeStamp"] as? Int64),
                                                sender: self.getUserNameFrom(peerId: dict["peerId"] as? String),
                                                target: nil,
                                                type: .Signaling)
                        self.messages.append(message)
                    }
                }
                self.tableView.reloadSections(IndexSet(integer: 0), with: .fade)
            }
        }
    }
    func sendMessage(message: String, forPeerId peerId: String?) {
        //Message as JSON
//        let message = ["senderId" : USER_NAME,
//                          "data" : message]
        
        if messageTypeSegmentControl.selectedSegmentIndex == 0{
            //Send P2P Message
            skylinkConnection.sendP2PMessage(message, toRemotePeerId: peerId) { (error) in
                processResponse(error: error, type: .P2P)
            }
        }else{
            //Send Server Message
            skylinkConnection.sendServerMessage(message, toRemotePeerId: peerId) { (error) in
                processResponse(error: error, type: .Signaling)
            }
        }
        func processResponse(error: Error?, type: SAMessage.MessageType){
            if let error = error{
                saAlert(title:"ERROR: \(error.code)", msg: error.localizedDescription)
            }else{
                let sentMessage = SAMessage(data: message, timeStamp: Date().toTimeStamp(), sender: USER_NAME, target: peerId, type: type)
                messages.append(sentMessage)
                self.messageTextField.text = ""
                self.tableView.reloadSections(IndexSet(integer: 0), with: .fade)
                saAlert(title: message, msg: (peerId != nil) ? peerId : "All")
            }
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
            skylinkConnection.sendLocalUserData(["nickname" : nicknameTextField.text], callback: nil)
        } else {
            let msgTitle = "Empty nickname"
            let msg = "\nType the nickname to set."
            saAlert(title: msgTitle, msg: msg)
        }
    }
    
    func hideKeyboardIfNeeded() {
        messageTextField.resignFirstResponder()
        nicknameTextField.resignFirstResponder()
    }
    private func getUserNameFrom(peerId: String?) -> String?{
        if let userInfo = skylinkConnection.getUserInfo(peerId) as? [String: Any]{
            return userInfo["userData"] as? String
        }
        return peerId
    }
    // MARK: - UITextField delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nicknameTextField {
            updateNickname()
        }
        hideKeyboardIfNeeded()
        return true
    }
    func textFieldDidChangeSelection(_ textField: UITextField) {
        print("change")
        if textField == encryptKeyTextField{
//            ENCRYPTION_SECRETS = textField.text!
//            skylinkConnection.encryptSecret = ENCRYPTION_SECRET
        }
    }
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == encryptKeyTextField {
            hideKeyboardIfNeeded()
            pickerViewContainer.isHidden = false
            return false
        }
        return true
    }
    // MARK: IBFuction
    @IBAction func sendTap() {
        skylinkConnection.messagePersist = persistSwitch.isOn
        guard let message = messageTextField.text else {
            saAlert(title: "Empty message", msg: "\nType the message to be sent.");
            return
        }
        if peers.count<=0{
            saAlert(title: "No peer connected.", msg: "nYou can't define a private recipient since there is no peer connected.")
        }
        if isPublicSwitch.isOn {
            //Send to all peer
            sendMessage(message: message, forPeerId: nil)
        } else {
            //Send to a specific peer
            let alert = UIAlertController(title: "Choose a private recipient.", message: "\nYou're about to send a private message\nWho do you want to send it to ?", preferredStyle: .alert)
            let noAction = UIAlertAction(title: "Cancel", style: .default)
            for peerDicKey in peers.keys {
                let yesAction = UIAlertAction(title: peers[peerDicKey] as? String, style: .default) { [weak weakSelf = self] _ in
                    weakSelf?.sendMessage(message: message, forPeerId: peerDicKey)
                }
                alert.addAction(yesAction)
            }
            alert.addAction(noAction)
            present(alert, animated: true, completion: nil)
        }
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
    @IBAction func doneEncryptSecret(sender: UIButton) {
        pickerViewContainer.isHidden = true
    }
}
extension MessagesViewController: UIPickerViewDataSource, UIPickerViewDelegate{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return encryptSecretIds.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return encryptSecretIds[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedEncryptSecret: String? = (row == 0) ? nil : encryptSecretIds[row]
        skylinkConnection.selectedSecretId = selectedEncryptSecret
        encryptKeyTextField.text = encryptSecretIds[row]
    }
}
