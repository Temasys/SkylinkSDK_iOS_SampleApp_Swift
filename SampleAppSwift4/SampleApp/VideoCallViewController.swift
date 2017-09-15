//
//  VideoCallViewController.swift
//  SampleApp
//
//  Created by Yuxi on 26/7/17.
//  Copyright © 2017 Yuxi. All rights reserved.
//

import UIKit

class VideoCallViewController: UIViewController, SKYLINKConnectionLifeCycleDelegate, SKYLINKConnectionMediaDelegate, SKYLINKConnectionRemotePeerDelegate {

    @IBOutlet weak var localVideoContainerView: UIView!
    @IBOutlet weak var remotePeerVideoContainerView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var btnFlipCamera: UIButton!
    @IBOutlet weak var btnAudioTap: UIButton!
    @IBOutlet weak var btnVideoTap: UIButton!
    @IBOutlet weak var refreshButton: UIButton!
    
    
    var peerVideoSize: CGSize!
    var peerVideoView: UIView!
    weak var topView: UIView!
    let ROOM_NAME = "VIDEO-CALL-ROOM"
    
    var remotePeerId: String?
    let skylinkApiKey = SKYLINK_APP_KEY
    let skylinkApiSecret = SKYLINK_SECRET
    lazy var skylinkConnection: SKYLINKConnection = {
        // Creating configuration
        let config = SKYLINKConnectionConfig()
        config.video = true
        config.audio = true
        // Creating SKYLINKConnection
        if let skylinkConnection = SKYLINKConnection(config: config, appKey: skylinkApiKey) {
            skylinkConnection.lifeCycleDelegate = self
            skylinkConnection.mediaDelegate = self
            skylinkConnection.remotePeerDelegate = self
            SKYLINKConnection.setVerbose(true)
            return skylinkConnection
        } else {
            return SKYLINKConnection()
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupInfo()
    }
    
    fileprivate func setupUI() {
        skylinkLog("SKYLINKConnection version = \(SKYLINKConnection.getSkylinkVersion())")
        title = "1-1 Video Call"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Cancel"), style: .plain, target: self, action: #selector(disconnect))
        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(showInfo), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
        //Disable Btn
        btnAudioTap.isEnabled = false
        refreshButton.isEnabled = false
        btnVideoTap.isEnabled = false
        btnFlipCamera.isEnabled = false
    }
    
    fileprivate func setupInfo() {
        // Connecting to a room
        DispatchQueue.global().async { [weak weakSelf = self] in
            weakSelf?.skylinkConnection.connectToRoom(withSecret: weakSelf?.skylinkApiSecret, roomName: weakSelf?.ROOM_NAME, userInfo: nil)
        }
    }

    @objc fileprivate func disconnect() {
        activityIndicator.startAnimating()
        skylinkConnection.unlockTheRoom()
        skylinkConnection.disconnect { [weak weakSelf = self] in
            weakSelf?.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc fileprivate func showInfo() {
        let title = "Infos"
        let message = "\nRoom name:\n\(ROOM_NAME)\n\nLocal ID:\n\(skylinkConnection.myPeerId)\n\nKey: •••••" + (skylinkApiKey as NSString).substring(with: NSRange(location: 0, length: skylinkApiKey.count - 7)) + "\n\nSkylink version \(SKYLINKConnection.getSkylinkVersion() ?? "0.0")"
        alertMessage(msg_title: title, msg: message)
    }
    
    fileprivate func alertMessage(msg_title: String, msg:String) {
        let alertController = UIAlertController(title: msg_title , message: msg, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(OKAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - SKYLINKConnectionLifeCycleDelegate
    func connection(_ connection: SKYLINKConnection!, didConnectWithMessage errorMessage: String!, success isSuccess: Bool) {
        if isSuccess {
            skylinkLog("Inside \(#function)")
        } else {
            let msgTitle = "Connection failed"
            let msg = errorMessage
            alertMessage(msg_title: msgTitle, msg:msg!)
            navigationController?.popViewController(animated: true)
        }
        DispatchQueue.main.async { [weak weakSelf = self] in
            //Enable Btn
            weakSelf?.btnAudioTap.isEnabled = true
            weakSelf?.btnVideoTap.isEnabled = true
            weakSelf?.refreshButton.isEnabled = true
            weakSelf?.btnFlipCamera.isEnabled = true
        }
        activityIndicator.stopAnimating()
    }
    
    func connection(_ connection: SKYLINKConnection!, didDisconnectWithMessage errorMessage: String!) {
        let alert = UIAlertController(title: "Disconnected", message: errorMessage, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        present(alert, animated: true) { [weak weakSelf = self] in
            weakSelf?.disconnect()
        }
    }
    
    func connection(_ connection: SKYLINKConnection!, didRenderUserVideo userVideoView: UIView!) {
        addRenderedVideo(videoView: peerVideoView, insideContainer: remotePeerVideoContainerView, mirror: false)
    }
    
    func connection(_ connection: SKYLINKConnection!, didLeavePeerWithMessage errorMessage: String!, peerId: String!) {
        remotePeerId = nil
        skylinkConnection.unlockTheRoom()
        alertMessage(msg_title: "Peer Left", msg: "\nPeer ID:\(peerId)\n has been left")
    }
    
    // MARK: - SKYLINKConnectionMediaDelegate
    func connection(_ connection: SKYLINKConnection!, didChangeVideoSize videoSize: CGSize, videoView: UIView!) {
        if videoSize.height > 0 && videoSize.width > 0 {
            var correspondingContainerView: UIView
            if videoView.isDescendant(of: localVideoContainerView) {
                correspondingContainerView = localVideoContainerView
            } else {
                correspondingContainerView = remotePeerVideoContainerView
                peerVideoView = videoView
                peerVideoSize = videoSize
            }
            videoView.frame = aspectFillRectForSize(insideSize: videoSize, containedInRect: correspondingContainerView.frame)
            viewWillLayoutSubviews()
            // for aspect fit, use AVMakeRectWithAspectRatioInsideRect(videoSize, correspondingContainerView.bounds);
        }
    }
    
    // MARK: - Other
    
    // for didRender.. Delegates
    func addRenderedVideo(videoView: UIView, insideContainer containerView: UIView, mirror shouldMirror: Bool) {
        videoView.frame = containerView.bounds
        _ = containerView.subviews.map { $0.removeFromSuperview() }
        containerView.insertSubview(videoView, at: 0)
    }
    
    func aspectFillRectForSize(insideSize: CGSize, containedInRect containerRect: CGRect) -> CGRect {
        let maxFloat = max(containerRect.size.height, containerRect.size.width)
        let aspectRatio = insideSize.width / insideSize.height
        var frame = CGRect(x: 0, y: 0, width: containerRect.size.width, height: containerRect.size.height)
        if insideSize.width < insideSize.height {
            frame.size.width = maxFloat
            frame.size.height = frame.size.width / aspectRatio
        } else {
            frame.size.height = maxFloat;
            frame.size.width = frame.size.height * aspectRatio
        }
        frame.origin.x = (containerRect.size.width - frame.size.width) / 2
        frame.origin.y = (containerRect.size.height - frame.size.height) / 2
        return frame
    }
    
    // MARK: IBAction TouchUp
    @IBAction func toogleVideoTap(sender: AnyObject) {
        skylinkConnection.muteVideo(!skylinkConnection.isVideoMuted())
        sender.setImage(UIImage(named: ((skylinkConnection.isVideoMuted()) ? "NoVideoFilled.png" : "VideoCall.png")), for: .normal)
        localVideoContainerView.isHidden = skylinkConnection.isVideoMuted()
    }
    
    @IBAction func toogleSoundTap(sender: AnyObject) {
        self.skylinkConnection.muteAudio(!skylinkConnection.isAudioMuted())
        sender.setImage(UIImage(named: ((skylinkConnection.isAudioMuted()) ? "NoMicrophoneFilled.png" : "Microphone.png")), for: .normal)
    }
    
    @IBAction func switchCameraTap() {
        skylinkConnection.switchCamera()
    }
    
    @IBAction func refreshTap() {
        if (remotePeerId != nil) {
            activityIndicator.startAnimating()
            skylinkConnection.unlockTheRoom()
            skylinkConnection.refreshConnection(remotePeerId!)
        } else {
            let msgTitle = "No peer connexion to refresh"
            let msg = "Tap this button to refresh the peer connexion if needed."
            alertMessage(msg_title: msgTitle, msg:msg)
        }
    }
}
