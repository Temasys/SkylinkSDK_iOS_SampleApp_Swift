//
//  MultiVideoCallViewController.swift
//  SampleApp
//
//  Created by Yuxi on 26/7/17.
//  Copyright © 2017 Yuxi. All rights reserved.
//

import UIKit
import AVFoundation

class MultiVideoCallViewController: UIViewController, SKYLINKConnectionLifeCycleDelegate, SKYLINKConnectionMediaDelegate, SKYLINKConnectionRemotePeerDelegate {
    
    @IBOutlet weak var localVideoContainerView: UIView!
    @IBOutlet weak var firstPeerVideoContainerView: UIView!
    @IBOutlet weak var secondPeerVideoContainerView: UIView!
    @IBOutlet weak var thirdPeerVideoContainerView: UIView!
    @IBOutlet weak var firstPeerLabel: UILabel!
    @IBOutlet weak var secondPeerLabel: UILabel!
    @IBOutlet weak var thirdPeerLabel: UILabel!
    @IBOutlet weak var lockButton: UIButton!
    @IBOutlet weak var btnAudioTap: UIButton!
    @IBOutlet weak var btnFlipCamera: UIButton!
    @IBOutlet weak var btnCameraTap: UIButton!
    @IBOutlet weak var videoAspectSegmentControl: UISegmentedControl!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
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
    lazy var peerIds = [String]()
    lazy var peersInfos = [String : Any]()
    let skylinkApiKey = SKYLINK_APP_KEY
    let skylinkApiSecret = SKYLINK_SECRET
    
    let ROOM_NAME = "MULTI-VIDEO-CALL-ROOM"
    var isRoomLocked = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupInfo()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updatePeersVideosFrames()
    }
    
    fileprivate func setupUI() {
        skylinkLog("imat_viewDidLoad")
        skylinkLog("SKYLINKConnection version = \(SKYLINKConnection.getSkylinkVersion())")
        title = "Messages"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Cancel"), style: .plain, target: self, action: #selector(disconnect))
        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(showInfo), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
        //Disable Button
        btnFlipCamera.isEnabled = false
        btnAudioTap.isEnabled = false
        btnCameraTap.isEnabled = false
        lockButton.isEnabled = false
    }
    
    fileprivate func setupInfo() {
        // Connecting to a room
        skylinkConnection.connectToRoom(withSecret: skylinkApiSecret, roomName: ROOM_NAME, userInfo: nil)
    }
    
    @objc fileprivate func disconnect() {
        skylinkLog("imat_disConnect")
        activityIndicator.startAnimating()
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
    
    //End of Skylink SDK functions
    
    // MARK: Utils
    fileprivate func updatePeersVideosFrames() {
        for i in 0..<min(peerIds.count, 3) {
            guard let dict = peersInfos[peerIds[i]] as? [String : AnyObject], let pvView = dict["videoView"] as? UIView, let pvSize = dict["videoSize"] as? CGSize else { return }
            pvView.frame = (videoAspectSegmentControl.selectedSegmentIndex == 0) ? aspectFillRectForSize(insideSize: pvSize, containedInRect: containerViewForVideoView(videoView: pvView).frame) : AVMakeRect(aspectRatio: pvSize, insideRect: containerViewForVideoView(videoView: pvView).bounds)
        }
    }
    
    fileprivate func lockRoom(shouldLock: Bool) {
        (shouldLock) ? skylinkConnection.lockTheRoom() : skylinkConnection.unlockTheRoom()
        isRoomLocked = shouldLock
        lockButton.setImage(UIImage(named: ((isRoomLocked) ? "LockFilled" : "Unlock.png")), for: .normal)
    }
    
    fileprivate func containerViewForVideoView(videoView: UIView) -> UIView {
        var correspondingContainerView: UIView!
        if videoView.isDescendant(of: localVideoContainerView) {
            correspondingContainerView = localVideoContainerView
        } else if videoView.isDescendant(of: firstPeerVideoContainerView) {
            correspondingContainerView = firstPeerVideoContainerView
        } else if videoView.isDescendant(of: secondPeerVideoContainerView) {
            correspondingContainerView = secondPeerVideoContainerView
        } else if videoView.isDescendant(of: thirdPeerVideoContainerView) {
            correspondingContainerView = thirdPeerVideoContainerView
        }
        return correspondingContainerView
    }
    
    fileprivate func aspectFillRectForSize(insideSize: CGSize, containedInRect containerRect: CGRect) -> CGRect {
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
    
    fileprivate func addRenderedVideo(videoView: UIView, insideContainer containerView: UIView, mirror shouldMirror: Bool) {
        skylinkLog("I_addRenderedVideo")
        videoView.frame = containerView.bounds
        if shouldMirror {
            videoView.transform = CGAffineTransform(scaleX: -1, y: 1)
        }
        _ = containerView.subviews.map { $0.removeFromSuperview() }
        containerView.insertSubview(videoView, at: 0)
    }
    
    fileprivate func indexForContainerView(v: UIView) -> Int {
        return ([firstPeerVideoContainerView, secondPeerVideoContainerView, thirdPeerVideoContainerView] as NSArray).index(of: v)
    }
    
    fileprivate func refreshPeerViews() {
        let peerContainerViews = [firstPeerVideoContainerView ?? UIView(), secondPeerVideoContainerView ?? UIView(), thirdPeerVideoContainerView ?? UIView()]
        var peerLabels = [firstPeerLabel ?? UILabel(), secondPeerLabel ?? UILabel(), thirdPeerLabel ?? UILabel()]
        _ = peerContainerViews.map { $0.subviews.map { $0.removeFromSuperview() } }

        for i in 0..<peersInfos.count  {
            guard let index = peerIds.index(of: peerIds[i]), let dict = peersInfos[peerIds[i]] as? [String : AnyObject] else { return }
            let videoView = dict["videoView"] as? UIView
            if (index < peerContainerViews.count) {
                if videoView == nil {
                    alertMessage(msg_title: "Warning", msg: "Cannot render the video view. Camera not found")
                } else {
                    addRenderedVideo(videoView: videoView!, insideContainer: peerContainerViews[index], mirror: false)
                }
            }
            // refresh the label
            guard let audioMuted = dict["isAudioMuted"], let videoMuted = dict["isVideoMuted"] else { return }
            
            var mutedInfos = ""
            if audioMuted is NSNumber && CBool(truncating: audioMuted as! NSNumber) {
                mutedInfos = "Audio muted"
            }
            if videoMuted is NSNumber && CBool(truncating: videoMuted as! NSNumber) {
                mutedInfos = mutedInfos.count != 0 ? "Video & ".appending(mutedInfos) : "Video muted"
            }
            if index < peerLabels.count {
                peerLabels[index].text = mutedInfos
            }
            if index < peerLabels.count {
                peerLabels[index].isHidden = !(mutedInfos.count != 0)
            }
        }
        for i in peerIds.count..<peerLabels.count {
            ((peerLabels[i] as UILabel)).isHidden = true
        }
        updatePeersVideosFrames()
    }

    // SKYLINK SDK Delegates methods
    
    // MARK: SKYLINKConnectionMediaDelegate
    func connection(_ connection: SKYLINKConnection!, didChangeVideoSize videoSize: CGSize, videoView: UIView!) {
        if videoSize.height > 0 && videoSize.width > 0 {
            let correspondingContainerView = containerViewForVideoView(videoView: videoView)
            if correspondingContainerView != localVideoContainerView {
                let i = indexForContainerView(v: correspondingContainerView)
                guard let dict = peersInfos[peerIds[i]] as? [String : AnyObject], let videoSize = dict["videoSize"] as? CGSize, let videoView = dict["videoView"], let isAudioMuted = dict["isAudioMuted"], let isVideoMuted = dict["isVideoMuted"] else { return }
                if i != NSNotFound {
                    peersInfos[peerIds[i]] = ["videoView" : videoView, "videoSize" : videoSize, "isAudioMuted" : isAudioMuted, "isVideoMuted" : isVideoMuted]
                }
            }
            
            videoView.frame = (videoAspectSegmentControl.selectedSegmentIndex == 0 || correspondingContainerView.isEqual(localVideoContainerView)) ? aspectFillRectForSize(insideSize: videoSize, containedInRect: correspondingContainerView.frame): AVMakeRect(aspectRatio: videoSize, insideRect: correspondingContainerView.bounds)
        }
        updatePeersVideosFrames()
    }
    
    func connection(_ connection: SKYLINKConnection!, didToggleAudio isMuted: Bool, peerId: String!) {
        let bool = peersInfos.keys.contains { _ in return true }
        if bool {
            guard let dict = peersInfos[peerId] as? [String : AnyObject], let videoSize = dict["videoSize"], let videoView = dict["videoView"], let isVideoMuted = dict["isVideoMuted"] else { return }
            let isAudioMuted = isMuted
            peersInfos[peerId] = ["videoView" : videoView, "videoSize" : videoSize, "isAudioMuted" : isAudioMuted, "isVideoMuted" : isVideoMuted]
        }
        refreshPeerViews()
    }
    
    func connection(_ connection: SKYLINKConnection!, didToggleVideo isMuted: Bool, peerId: String!) {
        skylinkLog("imat_didToggleVideo")
        let bool = peersInfos.keys.contains { _ in return true }
        if bool {
            guard let dict = peersInfos[peerId] as? [String : AnyObject], let videoSize = dict["videoSize"], let videoView = dict["videoView"], let isAudioMuted = dict["isAudioMuted"] else { return }
            let isVideoMuted = isMuted
            peersInfos[peerId] = ["videoView" : videoView, "videoSize" : videoSize, "isAudioMuted" : isAudioMuted, "isVideoMuted" : isVideoMuted]
        }
        refreshPeerViews()
    }
    
    // MARK: SKYLINKConnectionLifeCycleDelegate
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
            weakSelf?.activityIndicator.stopAnimating()
            //Enable Btn
            weakSelf?.btnAudioTap.isEnabled = true
            weakSelf?.btnFlipCamera.isEnabled = true
            weakSelf?.btnCameraTap.isEnabled = true
            weakSelf?.lockButton.isEnabled = true
        }
    }
    
    func connection(_ connection: SKYLINKConnection!, didLockTheRoom lockStatus: Bool, peerId: String!) {
        isRoomLocked = lockStatus
        lockButton.setImage(UIImage(named: (isRoomLocked ? "LockFilled" : "Unlock.png")), for: .normal)
    }
    
    func connection(_ connection: SKYLINKConnection!, didRenderUserVideo userVideoView: UIView!) {
        addRenderedVideo(videoView: userVideoView, insideContainer: localVideoContainerView, mirror: true)
    }
    
    func connection(_ connection: SKYLINKConnection!, didDisconnectWithMessage errorMessage: String!) {
        let alert = UIAlertController(title: "Disconnected", message: errorMessage, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        present(alert, animated: true) { [weak weakSelf = self] in
            weakSelf?.disconnect()
        }
    }
    
    // MARK: SKYLINKConnectionRemotePeerDelegate
    func connection(_ connection: SKYLINKConnection!, didJoinPeer userInfo: Any!, mediaProperties pmProperties: SKYLINKPeerMediaProperties!, peerId: String!) {
        if !peerIds.contains(peerId) {
            peerIds.append(peerId)
        }
        if peerIds.count >= 4 {
            lockRoom(shouldLock: true)
        }
        var bool = false
        _ = peersInfos.keys.map {
            if $0 == peerId { bool = true }
        }
        if !bool {
            (peersInfos as! NSMutableDictionary).addEntries(from: [peerId: ["videoView": NSNull(), "videoSize": NSNull(), "isAudioMuted": NSNull(), "isVideoMuted": NSNull()]])
        }
        guard let dict = peersInfos[peerId] as? [String : AnyObject], let videoView = dict["videoView"] else { return }
        let size = CGSize(width: pmProperties.videoWidth, height: pmProperties.videoHeight)
        let videoSize = NSValue(cgSize: size)
        let isAudioMuted = NSNumber(value: pmProperties.isAudioMuted)
        let isVideoMuted = NSNumber(value: pmProperties.isVideoMuted)
        peersInfos[peerId] = ["videoView" : videoView, "videoSize" : videoSize, "isAudioMuted" : isAudioMuted, "isVideoMuted" : isVideoMuted]
        refreshPeerViews()
    }
    
    func connection(_ connection: SKYLINKConnection!, didLeavePeerWithMessage errorMessage: String!, peerId: String!) {
        skylinkLog("Peer with id \(peerId) left the room with message: \(errorMessage)")
        if peerIds.count != 0 {
            peerIds.remove(at: peerIds.index(of: peerId)!)
            peersInfos.removeValue(forKey: peerId)
        }
        lockRoom(shouldLock: false)
        refreshPeerViews()
    }
    
    func connection(_ connection: SKYLINKConnection!, didRenderPeerVideo peerVideoView: UIView!, peerId: String!) {
        if !peerIds.contains(peerId) {
            peerIds.append(peerId)
        }
        var bool = false
        _ = peersInfos.keys.map {
            if $0 == peerId { bool = true }
        }
        if !bool {
            (peersInfos as! NSMutableDictionary).addEntries(from: [peerId: ["videoView": NSNull(), "videoSize": NSNull(), "isAudioMuted": NSNull(), "isVideoMuted": NSNull()]])
        }
        guard let dict = peersInfos[peerId] as? [String : AnyObject], let videoSize = dict["videoSize"], let isAudioMuted = dict["isAudioMuted"], let isVideoMuted = dict["isVideoMuted"] else { return }
        
        peersInfos[peerId] = ["videoView" : peerVideoView, "videoSize" : videoSize, "isAudioMuted" : isAudioMuted, "isVideoMuted" : isVideoMuted]
        refreshPeerViews()
    }
    
    // MARK: IB Action Function
    @IBAction func toogleVideoTap(sender: AnyObject) {
        skylinkConnection.muteVideo(!skylinkConnection.isVideoMuted())
        sender.setImage(UIImage(named: ((skylinkConnection.isVideoMuted()) ? "NoVideoFilled.png" : "VideoCall.png")), for: .normal)
        localVideoContainerView.isHidden = (skylinkConnection.isVideoMuted)()
    }
    
    @IBAction func toogleSoundTap(sender: AnyObject) {
        skylinkConnection.muteAudio(!skylinkConnection.isAudioMuted())
        sender.setImage(UIImage(named: ((skylinkConnection.isAudioMuted()) ? "NoMicrophoneFilled.png" : "Microphone.png")), for: .normal)
    }
    
    @IBAction func switchCameraTap() {
        skylinkConnection.switchCamera()
    }
    
    @IBAction func switchLockTap() {
        lockRoom(shouldLock: !isRoomLocked)
    }
    
    @IBAction func videoAspectSegmentControlChanged() {
        updatePeersVideosFrames()
    }
}
