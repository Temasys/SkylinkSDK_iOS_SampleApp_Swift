//
//  DataTransferViewController.swift
//  SampleApp_Swift
//
//  Created by Yuxi Liu on 4/10/17.
//  Copyright © 2017 Temasys. All rights reserved.
//

import UIKit

class DataTransferViewController: UIViewController, SKYLINKConnectionLifeCycleDelegate, SKYLINKConnectionMessagesDelegate, SKYLINKConnectionRemotePeerDelegate {

    let skylinkApiKey = SKYLINK_APP_KEY
    let skylinkApiSecret = SKYLINK_SECRET
    
    let ROOM_NAME = "ROOMNAME_DATATRANSFER"
    
    @IBOutlet weak var localColorView: UIView!
    @IBOutlet weak var redSlider: UISlider!
    @IBOutlet weak var greenSlider: UISlider!
    @IBOutlet weak var blueSlider: UISlider!
    @IBOutlet weak var infoTextView: UITextView!
    @IBOutlet weak var isContinuousSwitch: UISwitch!
    @IBOutlet weak var sendColorButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    var timer: Timer?
    lazy var skylinkConnection: SKYLINKConnection = {
        // Creating configuration
        let config = SKYLINKConnectionConfig()
        config.dataChannel = true
        config.receiveAudio = true
        // Creating SKYLINKConnection
        SKYLINKConnection.setVerbose(true)
        if let skylinkConnection = SKYLINKConnection(config: config, appKey: skylinkApiKey) {
            skylinkConnection.lifeCycleDelegate = self
            skylinkConnection.remotePeerDelegate = self
            skylinkConnection.messagesDelegate = self
            return skylinkConnection
        } else {
            return SKYLINKConnection()
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupInfo()
        refreshUI()
    }
    
    fileprivate func refreshUI() {
        localColorView.backgroundColor = slidersUIColor()
        sendColorButton.isHidden = isContinuousSwitch.isOn
    }
    
    fileprivate func onTick(timer: Timer) {
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
        skylinkConnection.sendBinaryData(colorData, peerId: nil)
    }

    fileprivate func showUIInfo(infoMessage: String) {
        infoTextView.text = String(format: "[%.3f] %@\n%@", CFAbsoluteTimeGetCurrent(), infoMessage, infoTextView.text)
    }
    
    fileprivate func setupUI() {
        skylinkLog("imat_viewDidLoad")
        skylinkLog("SKYLINKConnection version = \(SKYLINKConnection.getSkylinkVersion())")
        title = "Messages"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Cancel"), style: .plain, target: self, action: #selector(disconnect))
        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(showInfo), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
    }
    
    fileprivate func setupInfo() {
        // Connecting to a room
        skylinkConnection.connectToRoom(withSecret: skylinkApiSecret, roomName: ROOM_NAME, userInfo: ["sampleUserDataKey":"sampleUserDataStringValue"])
    }
    
    @objc fileprivate func disconnect() {
        skylinkLog("imat_disConnect")
        skylinkConnection.disconnect { [weak weakSelf = self] in
            weakSelf?.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc fileprivate func showInfo() {
        let title = "Infos"
        let message = "\nRoom name:\n\(ROOM_NAME)\n\nLocal ID:\n\(skylinkConnection.myPeerId)\n\nKey: •••••" + (skylinkApiKey as NSString).substring(with: NSRange(location: 0, length: skylinkApiKey.count - 7)) + "\n\nSkylink version \(SKYLINKConnection.getSkylinkVersion())"
        alertMessage(msg_title: title, msg: message)
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
    func connection(_ connection: SKYLINKConnection, didConnectWithMessage errorMessage: String!, success isSuccess: Bool) {
        showUIInfo(infoMessage: (isSuccess ? "🔵" : "🔴") + " DID CONNECT • success = " + (isSuccess ? "YES" : "NO"))
    }
    
    // MARK: - SKYLINKConnectionRemotePeerDelegate
    func connection(_ connection: SKYLINKConnection, didJoinPeer userInfo: Any!, mediaProperties pmProperties: SKYLINKPeerMediaProperties!, peerId: String!) {
        showUIInfo(infoMessage: "👤 DID JOIN PEER •\npeerID = " + peerId + ", properties = " + pmProperties.description)
    }
    
    func connection(_ connection: SKYLINKConnection, didLeavePeerWithMessage errorMessage: String!, peerId: String!) {
        showUIInfo(infoMessage: "✋🏼 DID LEAVE PEER • peerID = " + peerId + ", properties = " + errorMessage)
    }
    
    // MARK: - SKYLINKConnectionMessagesDelegate
    func connection(_ connection: SKYLINKConnection, didReceiveBinaryData data: Data!, peerId: String!) {
        if data != nil {
            var dataByte = ""
            if let unarchivedData = NSKeyedUnarchiver.unarchiveObject(with: data) as? UIColor {
                dataByte = "UIColor"
                view.backgroundColor = unarchivedData
            } else if let unarchivedData = NSKeyedUnarchiver.unarchiveObject(with: data) as? UIImage {
                dataByte = "UIImage"
                imageView.image = unarchivedData
                UIView.animate(withDuration: 1, delay: 3, options: UIViewAnimationOptions(rawValue: 0), animations: { [weak weakSelf = self] in
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
            skylinkConnection.sendBinaryData(NSKeyedArchiver.archivedData(withRootObject: sampleImage2), peerId: nil)
        }
    }
    
    @IBAction func autoChangeColorSwitchChanged(sender: UISwitch) {
        if sender.isOn {
            let d = Date(timeIntervalSinceNow: 0)
            timer = Timer(fireAt: d, interval: 0.04, target: self, selector: Selector(("onTick:")), userInfo: nil, repeats: true)
            RunLoop.current.add(timer!, forMode: .defaultRunLoopMode)
        } else {
            timer?.invalidate()
            timer = nil
        }
    }
    
}
