//
//  DataTransferViewController.swift
//  SampleApp_Swift
//
//  Created by  Temasys on 4/10/17.
//  Copyright © 2017 Temasys. All rights reserved.
//

import UIKit

class DataTransferViewController: SKConnectableVC, SKYLINKConnectionLifeCycleDelegate, SKYLINKConnectionMessagesDelegate, SKYLINKConnectionRemotePeerDelegate {

    @IBOutlet weak var localColorView: UIView!
    @IBOutlet weak var redSlider: UISlider!
    @IBOutlet weak var greenSlider: UISlider!
    @IBOutlet weak var blueSlider: UISlider!
    @IBOutlet weak var infoTextView: UITextView!
    @IBOutlet weak var isContinuousSwitch: UISwitch!
    @IBOutlet weak var sendColorButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    var timer: Timer?
//MARK: - INIT
    override func initData() {
        super.initData()
        if roomName.count==0{
            roomName = ROOM_DATA_TRANSFER
        }
        joinRoom()
    }
    override func initUI() {
        super.initUI()
        title = "Data Transfer"
        refreshUI()
    }
    override func initSkylinkConnection() -> SKYLINKConnection {
        // Creating configuration
        let config = SKYLINKConnectionConfig()
        config.hasDataTransfer = true
        config.setAudioVideoSend(AudioVideoConfig_NO_AUDIO_NO_VIDEO)
        config.setAudioVideoReceive(AudioVideoConfig_NO_AUDIO_NO_VIDEO)
        // Creating SKYLINKConnection
        if let skylinkConnection = SKYLINKConnection(config: config, callback: nil) {
            skylinkConnection.lifeCycleDelegate = self
            skylinkConnection.remotePeerDelegate = self
            skylinkConnection.messagesDelegate = self
            skylinkConnection.enableLogs = true
            return skylinkConnection
        } else {
            return SKYLINKConnection()
        }
    }
//MARK: -
    fileprivate func refreshUI() {
        localColorView.backgroundColor = slidersUIColor()
        sendColorButton.isHidden = isContinuousSwitch.isOn
    }
    
    
    @objc fileprivate func onTick(timer: Timer) {
        let increment: Float = 0.004
        redSlider.value = (redSlider.value + increment > 1) ? 0 : redSlider.value + increment
        greenSlider.value = (greenSlider.value + 1.9 * increment > 1) ? 0 : greenSlider.value + 1.9 * increment
        blueSlider.value = (blueSlider.value + 3.1 * increment > 1) ? 0 : blueSlider.value + 3.1 * increment
        if isContinuousSwitch.isOn {
            sendCurrentColor()
        }
        refreshUI()
    }
    
    fileprivate func sendCurrentColor() {
        showUIInfo(infoMessage: "Sending current local color...")
        let colorData = NSKeyedArchiver.archivedData(withRootObject: slidersUIColor())
        skylinkConnection.send(colorData, toRemotePeerId: nil, callback: nil)
    }

    fileprivate func showUIInfo(infoMessage: String) {
        infoTextView.text = String(format: "[%.3f] %@\n%@", CFAbsoluteTimeGetCurrent(), infoMessage, infoTextView.text)
    }
    
    fileprivate func alertMessage(msg_title: String, msg:String) {
        let alertController = UIAlertController(title: msg_title , message: msg, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(OKAction)
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func slidersUIColor() -> UIColor {
        return UIColor(red: CGFloat(redSlider.value), green: CGFloat(greenSlider.value), blue: CGFloat(blueSlider.value), alpha: 1)
    }
    
    // MARK: - SKYLINKConnectionLifeCycleDelegate
    func connectionDidConnect(toRoomSuccessful connection: SKYLINKConnection) {
         showUIInfo(infoMessage: "DID CONNECT • success ")
    }
    
    func connection(_ connection: SKYLINKConnection, didConnectToRoomFailed errorMessage: String!) {
        showUIInfo(infoMessage: "Failed to connect")
    }
    
    // MARK: - SKYLINKConnectionRemotePeerDelegate
    func connection(_ connection: SKYLINKConnection, didConnectWithRemotePeer remotePeerId: String!, userInfo: Any!, hasDataChannel: Bool) {
        showUIInfo(infoMessage: "👤 DID JOIN PEER •\npeerID = \(String(describing: remotePeerId)) userInfo = \(userInfo ?? "") hasDataChannel = \(hasDataChannel)")
    }
    
    func connection(_ connection: SKYLINKConnection, didReceiveRemotePeerLeaveRoom remotePeerId: String!, userInfo: Any!, skylinkInfo: [AnyHashable : Any]?) {
        showUIInfo(infoMessage: "✋🏼 DID LEAVE PEER • peerID = " + remotePeerId + ", skylinkInfo = \(skylinkInfo ?? ["":""])")
    }
    // MARK: - SKYLINKConnectionMessagesDelegate
    func connection(_ connection: SKYLINKConnection, didReceive data: Data!, remotePeerId: String!) {
        if data != nil {
            var dataByte = ""
            if let unarchivedData = NSKeyedUnarchiver.unarchiveObject(with: data) as? UIColor {
                dataByte = "UIColor"
                view.backgroundColor = unarchivedData
            } else if let unarchivedData = NSKeyedUnarchiver.unarchiveObject(with: data) as? UIImage {
                dataByte = "UIImage"
                imageView.image = unarchivedData
                UIView.animate(withDuration: 1, delay: 3, options: UIView.AnimationOptions(rawValue: 0), animations: { [weak weakSelf = self] in
                    weakSelf?.imageView.alpha = 0
                    }, completion: { [weak weakSelf = self] (finished) in
                        weakSelf?.imageView.image = nil
                        weakSelf?.imageView.alpha = 1
                })
            } else {
                dataByte = "OTHER"
            }
            showUIInfo(infoMessage: "Received data of type '\(dataByte)' and lenght: \(data.count)")
        }
    }
    
    @IBAction func sendDataTap() {
        sendCurrentColor()
    }
    
    @IBAction func onAnySliderChange() {
        if isContinuousSwitch.isOn {
            sendCurrentColor()
        }
        refreshUI()
    }
    
    @IBAction func isContinuousSwitchChanged(sender: UISwitch) {
        if sender.isOn {
            sendCurrentColor()
        }
        refreshUI()
    }
    
    @IBAction func sendImageTap() {
        if let filePath = Bundle.main.path(forResource: "dataTransferImage", ofType: "png", inDirectory: "DataTransferSamples"), let sampleImage = UIImage(contentsOfFile: filePath), let cgimage = sampleImage.cgImage {
            let sampleImage2 = UIImage(cgImage: cgimage, scale: sampleImage.scale, orientation: sampleImage.imageOrientation)
            showUIInfo(infoMessage: "Sending sample image...")
            skylinkConnection.send(NSKeyedArchiver.archivedData(withRootObject: sampleImage2), toRemotePeerId: nil, callback: nil)
        }
    }
    
    @IBAction func autoChangeColorSwitchChanged(sender: UISwitch) {
        if sender.isOn {
            let d = Date(timeIntervalSinceNow: 0)
            timer = Timer(fireAt: d, interval: 0.04, target: self, selector: #selector(onTick), userInfo: nil, repeats: true)
            RunLoop.current.add(timer!, forMode: .default)
        } else {
            timer?.invalidate()
            timer = nil
        }
    }
    
}
