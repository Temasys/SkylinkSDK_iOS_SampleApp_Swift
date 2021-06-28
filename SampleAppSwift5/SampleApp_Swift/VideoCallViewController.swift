//
//  VideoCallViewController.swift
//  SampleApp
//
//  Created by  Temasys on 26/7/17.
//  Copyright © 2017  Temasys. All rights reserved.
//

import UIKit
import ReplayKit

@available(iOS 10.0, *)
class VideoCallViewController: SKConnectableVC, SKYLINKConnectionLifeCycleDelegate, SKYLINKConnectionMediaDelegate, SKYLINKConnectionRemotePeerDelegate, RPBroadcastControllerDelegate {

    @IBOutlet weak var localVideoContainerView: UIView!
    @IBOutlet weak var localVideoContainerView2: UIView!
    @IBOutlet weak var remotePeerVideoContainerView: UIView!
    @IBOutlet weak var remotePeerVideoContainerView2: UIView!
    @IBOutlet var videoViews: [UIView]!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var btnFlipCamera: UIButton!
    @IBOutlet weak var btnAudioTap: UIButton!
    @IBOutlet weak var btnVideoTap: UIButton!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var muteCameraSwitch: UISwitch!
    @IBOutlet weak var muteAudioSwitch: UISwitch!
    @IBOutlet weak var toggleCameraSwitch: UISwitch!
    @IBOutlet weak var toggleScreenSwitch: UISwitch!
    @IBOutlet weak var muteScreenSwitch: UISwitch!
    @IBOutlet weak var startScreenButton: UIButton!
    @IBOutlet weak var bottomView: UIVisualEffectView!
    
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var screenViewStack: UIStackView!
    
    var isJoinRoom: Bool = false
    
    weak var statsView: StatsView!
    weak var inAppBtn: UIButton!
    weak var systemBtn: UIButton!
    var peerVideoSize: CGSize!
    var peerVideoView: UIView!
    weak var topView: UIView!
    lazy var receivedFps = 0
    lazy var sentFps = 0
    var cameraMediaID = ""
    var screenMediaID = ""
    var audioMediaID = ""
    var localMedias = [SKYLINKMedia]()
    var remoteMedias = [SKYLINKMedia]()
    var localMedia : SKYLINKMedia!
    var remoteCameraMediaId = ""

    lazy var stats = Stats(dict: [:])
    var remotePeerId: String?
    var backClosure: (() -> Void)!
    
//MARK: - INIT
    override func initData() {
        super.initData()
        if roomName.count==0{
            roomName = ROOM_ONE_TO_ONE_VIDEO
        }
    }
    override func initUI() {
        super.initUI()
        title = "Room: \(roomName)"
        UIApplication.shared.isIdleTimerDisabled = true
        
        btnAudioTap.isEnabled = false
        refreshButton.isEnabled = false
        btnVideoTap.isEnabled = false
        btnFlipCamera.isEnabled = true
        if let statView = UINib(nibName: "StatsView", bundle: nil).instantiate(withOwner: nil, options: nil).first as? StatsView {
            statView.frame = CGRect(x: 120, y: 100, width: 250, height: 90)
            view.addSubview(statView)
            self.statsView = statView
        }
        screenViewStack.isHidden = false
        //Record
        let startRecButton = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 40))
        startRecButton.setTitle("StartREC", for: .normal)
        startRecButton.titleLabel?.font = UIFont.systemFont(ofSize: 11)
        startRecButton.addTarget(self, action: #selector(startRecording), for: .touchUpInside)
        let stopRecButton = UIButton(frame: CGRect(x: 60, y: 0, width: 50, height: 40))
        stopRecButton.setTitle("StopREC", for: .normal)
        stopRecButton.titleLabel?.font = UIFont.systemFont(ofSize: 11)
        stopRecButton.addTarget(self, action: #selector(stopRecording), for: .touchUpInside)
        let recStackView = UIStackView(frame: CGRect(x: 0, y: view.frame.height - bottomView.frame.height - 70, width: 110, height: 40))
        recStackView.addArrangedSubview(startRecButton)
        recStackView.addArrangedSubview(stopRecButton)
        view.addSubview(recStackView)
    }
    override func initSkylinkConnection() -> SKYLINKConnection {
        // Creating configuration
        let config = SKYLINKConnectionConfig()
        config.setAudioVideoSend(AudioVideoConfig_AUDIO_AND_VIDEO)
        config.setAudioVideoReceive(AudioVideoConfig_AUDIO_AND_VIDEO)
        config.isMultiTrackCreateEnable = true
        config.roomSize = SKYLINKRoomSizeSmall
        config.isMirrorLocalFrontCameraView = true
        // Creating SKYLINKConnection
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
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if peerVideoView != nil {
            peerVideoView.aspectFitRectForSize(insideSize: peerVideoSize, inContainer: remotePeerVideoContainerView)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
        if #available(iOS 11.0, *) {
            backClosure()
        }
    }
    
    // MARK: - SKYLINKConnectionLifeCycleDelegate
    func connectionDidConnect(toRoomSuccessful connection: SKYLINKConnection){
        skylinkLog("Inside \(#function)")
        self.activityIndicator.stopAnimating()
        callButton.setBackgroundImage(UIImage(named: "call_off"), for: .normal)
        DispatchQueue.main.async { [weak weakSelf = self] in
            //Enable Btn
            weakSelf?.btnAudioTap.isEnabled = true
            weakSelf?.btnVideoTap.isEnabled = true
            weakSelf?.refreshButton.isEnabled = true
            weakSelf?.btnFlipCamera.isEnabled = true
        }
        activityIndicator.stopAnimating()

        
    }
    func connection(_ connection: SKYLINKConnection, didConnectToRoomFailed errorMessage: String!) {
        let msgTitle = "Connection failed"
        let msg = errorMessage
        alertMessage(msg_title: msgTitle, msg:msg!)
        navigationController?.popViewController(animated: true)
    }
    
    func connection(_ connection: SKYLINKConnection, didDisconnectWithMessage errorMessage: String!) {
        
        self.activityIndicator.stopAnimating()
        callButton.setBackgroundImage(UIImage(named: "call_on"), for: .normal)
        let alert = UIAlertController(title: "Disconnected", message: errorMessage, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        present(alert, animated: true) { [unowned self] in
            self.activityIndicator.startAnimating()
            self.skylinkConnection.unlockTheRoom(nil)
            self.leaveRoom {
                self.navigationController?.popViewController(animated: true)
                self.remotePeerVideoContainerView.removeSubviews()
                self.remotePeerVideoContainerView2.removeSubviews()
            }
        }
        
        self.remotePeerVideoContainerView.removeSubviews()
        self.remotePeerVideoContainerView2.removeSubviews()
    }
    
    func connection(_ connection: SKYLINKConnection, didJoinPeer userInfo: Any!, mediaProperties pmProperties: SKYLINKPeerMediaProperties!, peerId: String!) {
        activityIndicator.stopAnimating()
        remotePeerId = peerId
    }
    
    func connection(_ connection: SKYLINKConnection, didLeavePeerWithMessage errorMessage: String!, peerId: String!) {
        skylinkConnection.unlockTheRoom(nil)
        alertMessage(msg_title: "Peer Left", msg: "\nPeer ID:\(String(describing: peerId))\n has been left")
        _ = [remotePeerVideoContainerView, remotePeerVideoContainerView2].map{$0?.removeSubviews()}
    }
    
// MARK: - SKYLINKConnectionMediaDelegate
    
    func connection(_ connection: SKYLINKConnection, didCreateLocalMedia localMedia: SKYLINKMedia) {
        self.localMedia = localMedia
        if localMedia.skylinkMediaType() == SKYLINKMediaTypeVideoScreen {
            screenMediaID = localMedia.skylinkMediaID()
        }
        if localMedia.skylinkMediaType() == SKYLINKMediaTypeVideoCamera {
            cameraMediaID = localMedia.skylinkMediaID()
        }
        if localMedia.skylinkMediaType() == SKYLINKMediaTypeAudio {
            audioMediaID = localMedia.skylinkMediaID()
        }
        
        print("saa create local media: \(localMedia.skylinkMediaType())")
        localMedias.append(localMedia)
        if localMedia.skylinkMediaType() == SKYLINKMediaTypeVideoCamera {
            addRenderedVideo(videoView: localMedia.skylinkVideoView() ?? UIView(), insideContainer: localVideoContainerView, mirror: true)
        } else if localMedia.skylinkMediaType() == SKYLINKMediaTypeVideoScreen {
            addRenderedVideo(videoView: localMedia.skylinkVideoView() ?? UIView(), insideContainer: localVideoContainerView2, mirror: true)
        }
        get()
        activityIndicator.stopAnimating()
    }
    
    func connection(_ connection: SKYLINKConnection, didChangeLocalMedia localMedia: SKYLINKMedia) {
        print("saa changed local media: \(localMedia.skylinkMediaType())")
        print("state: \(localMedia.skylinkMediaState())")
        self.activityIndicator.stopAnimating()
    }
    
    func connection(_ connection: SKYLINKConnection, didReceiveRemoteMedia remoteMedia: SKYLINKMedia, remotePeerId: String!) {
        remoteMedias.append(remoteMedia)
        print("SA===>receive remote media: \(remoteMedia.skylinkMediaType()==SKYLINKMediaTypeVideoCamera ? "Video Camera" : (remoteMedia.skylinkMediaType()==SKYLINKMediaTypeVideoScreen ? "Video Screen" : "Audio"))")
        switch remoteMedia.skylinkMediaType() {
        case SKYLINKMediaTypeVideoCamera:
            remoteCameraMediaId = remoteMedia.skylinkMediaID()
            if let videoView = remoteMedia.skylinkVideoView() {
                addRenderedVideo(videoView: videoView, insideContainer: remotePeerVideoContainerView, mirror: false)
            }
        case SKYLINKMediaTypeVideoScreen:
            if let videoView = remoteMedia.skylinkVideoView() {
                addRenderedVideo(videoView: videoView, insideContainer: remotePeerVideoContainerView2, mirror: false)
            }
        case SKYLINKMediaTypeAudio:
            if let videoView = remoteMedia.skylinkVideoView() {
                addRenderedVideo(videoView: videoView, insideContainer: remotePeerVideoContainerView, mirror: false)
            }
        default: return
        }
    }
    
    func connection(_ connection: SKYLINKConnection, didChangeVideoSize videoSize: CGSize, videoView: UIView!, peerId: String, mediaId: String) {
        if videoSize.height > 0 && videoSize.width > 0 {
            _ = [localVideoContainerView, remotePeerVideoContainerView, remotePeerVideoContainerView2].compactMap { $0 }.filter { videoView.isDescendant(of: $0) }.map { videoView.aspectFitRectForSize(insideSize: videoSize, inContainer: $0) }
        }
    }
    
    func connection(_ connection: SKYLINKConnection, didChangeRemoteMedia remoteMedia: SKYLINKMedia, remotePeerId: String!) {
        print("skylinkMedia.skylinkMediaType() ---> ", remoteMedia.skylinkMediaType())
        switch remoteMedia.skylinkMediaType() {
        case SKYLINKMediaTypeVideoCamera:
            remoteCameraMediaId = remoteMedia.skylinkMediaID()
            if(remoteMedia.skylinkMediaState() == SKYLINKMediaStateUnavailable){
                remotePeerVideoContainerView.removeSubviews()
                return
            }
            if let videoView = remoteMedia.skylinkVideoView() {
                if remotePeerId == skylinkConnection.localPeerId {
                    addRenderedVideo(videoView: videoView, insideContainer: localVideoContainerView, mirror: false)
                } else {
                    addRenderedVideo(videoView: videoView, insideContainer: remotePeerVideoContainerView, mirror: false)
                }
            }
        case SKYLINKMediaTypeVideoScreen:
            if remoteMedia.skylinkMediaState() == SKYLINKMediaStateUnavailable {
                remotePeerVideoContainerView2.removeSubviews()
                return
            }
            if let videoView = remoteMedia.skylinkVideoView() {
                addRenderedVideo(videoView: videoView, insideContainer: remotePeerVideoContainerView2, mirror: false)
            } else {
                if remoteMedia.skylinkMediaState() == SKYLINKMediaStateStopped || remoteMedia.skylinkMediaState() == SKYLINKMediaStateUnavailable {
                    remotePeerVideoContainerView2.subviews.forEach { $0.removeFromSuperview() }
                }
            }
        case SKYLINKMediaTypeAudio:
            if let videoView = remoteMedia.skylinkVideoView() {
                addRenderedVideo(videoView: videoView, insideContainer: remotePeerVideoContainerView, mirror: false)
            }
        default: return
        }
    }
    func connection(_ connection: SKYLINKConnection, didDestroyLocalMedia localMedia: SKYLINKMedia) {
        let removeLocalMedia = localMedias.filter{$0.skylinkMediaID() == localMedia.skylinkMediaID()}.first
        if let removeLocalMedia = removeLocalMedia{
            localMedias.remove(removeLocalMedia)
            reloadVideoView()
        }
    }
//MARK: - SKYLINKConnectionRemotePeerDelegate
    
    func connection(_ connection: SKYLINKConnection, didConnectWithRemotePeer remotePeerId: String!, userInfo: Any!, hasDataChannel: Bool) {
        activityIndicator.stopAnimating()
        self.remotePeerId = remotePeerId
    }
    
    func connection(_ connection: SKYLINKConnection, didDisconnectWithRemotePeer remotePeerId: String, userInfo: Any!, hasDataChannel: Bool) {
        remoteMedias.removeAll()
        reloadVideoView()
        
        self.activityIndicator.stopAnimating()
    }
    
    func connection(_ connection: SKYLINKConnection, didReceiveRemotePeerLeaveRoom remotePeerId: String!, infoCode: Int, userInfo: Any!) {
        
    }
    // MARK: - Other
    
    // for didRender.. Delegates
    func addRenderedVideo(videoView: UIView, insideContainer containerView: UIView, mirror shouldMirror: Bool) {
//        videoView.frame = aspectFitRectForSize(insideSize: videoView.frame.size, containedInRect: containerView.frame)
        videoView.aspectFitRectForSize(insideSize: videoView.frame.size, inContainer: containerView)
//        videoView.frame = containerView.bounds
//        _ = containerView.subviews.map { $0.removeFromSuperview() }
        containerView.insertSubview(videoView, at: 0)
    }
    
    // MARK: IBAction TouchUp
    @IBAction func toogleVideoTap(sender: AnyObject) {
        skylinkConnection.muteVideo(!(skylinkConnection.isVideoMuted()))
        sender.setImage(UIImage(named: ((skylinkConnection.isVideoMuted()) ? "NoVideoFilled.png" : "VideoCall.png")), for: .normal)
        localVideoContainerView.isHidden = (skylinkConnection.isVideoMuted())
    }
    
    @IBAction func toogleSoundTap(sender: AnyObject) {
        skylinkConnection.muteAudio(!(skylinkConnection.isAudioMuted()))
        sender.setImage(UIImage(named: ((skylinkConnection.isAudioMuted()) ? "NoMicrophoneFilled.png" : "Microphone.png")), for: .normal)
    }
    
    @IBAction func switchCameraTap() {
        skylinkConnection.switchCamera(nil)
    }
    
    @IBAction func refreshTap() {
        if (remotePeerId != nil) {
            activityIndicator.startAnimating()
            skylinkConnection.unlockTheRoom(nil)
            skylinkConnection.refreshConnection(withRemotePeerId: remotePeerId!, doIceRestart: true, callback: nil)
        } else {
            let msgTitle = "No peer connexion to refresh"
            let msg = "Tap this button to refresh the peer connexion if needed."
            alertMessage(msg_title: msgTitle, msg:msg)
        }
    }
    
    func connection(_ connection: SKYLINKConnection, didGetWebRTCStats stats: [AnyHashable : Any]!, forPeerId peerId: String!, mediaDirection: Int32) {
        skylinkLog("#Stats\nmd=\(mediaDirection) pid=\(String(describing: peerId))\n\(stats.description)")
    }
    
    @IBAction func set() {
        let alertController = UIAlertController(title: "Set stats", message: "Please set params", preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.keyboardType = .numberPad
            textField.placeholder = "Put the width"
        }
        alertController.addTextField { (textField) in
            textField.keyboardType = .numberPad
            textField.placeholder = "Put the height"
        }
        alertController.addTextField { (textField) in
            textField.keyboardType = .numberPad
            textField.placeholder = "Put the frame rate"
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        let localVideo: SKYLINKMedia? = localMedias.filter{$0.skylinkMediaType()==SKYLINKMediaTypeVideoCamera}.first
        let remoteVideo: SKYLINKMedia? = remoteMedias.filter{$0.skylinkMediaType()==SKYLINKMediaTypeVideoCamera}.first
        let okAction = UIAlertAction(title: "OK", style: .default) { [unowned self] (action) in
            if let width = alertController.textFields?.first?.text, let height = alertController.textFields?[1].text, let fps = alertController.textFields?.last?.text {
                self.skylinkConnection.setInputVideoResolutionOfMedia(localVideo?.skylinkMediaID() ?? "", toWidth: UInt(width) ?? 0, height: UInt(height) ?? 0, fps: UInt(fps) ?? 0) { (error) in
                    if let error = error{
                        UIAlertController.showAlertWithAutoDisappear(title: nil, message: error.localizedDescription, duration: 2, onViewController: self)
                    }
                }
                self.get()
            } else {
                return
            }
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }
 
    
    @IBAction func get() {
        skylinkConnection.getInputVideoResolution(withMediaId: cameraMediaID) { [unowned self] (w, h, fps, error) in
            print("getInputVideoResolution ---> ", w, h, fps, error)
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            let stats = Stats(dict: ["FrameWidthInput": w, "FrameHeightInput": h, "FrameRateInput": fps])
            self.statsView.setupView(stats: stats, status: .input)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [unowned self] in
            print("self.remotePeerId ---> ", self.remotePeerId)
            self.skylinkConnection.getSentVideoResolution(ofRemotePeerId: self.remotePeerId ?? "", mediaId: self.cameraMediaID) { (w, h, fps, error) in
                print("getSentVideoResolution ---> ", w, h, fps, error)
                if error != nil {
                   print(error!.localizedDescription)
                   return
                }
                self.sentFps = fps
                let stats = Stats(dict: ["FrameWidthSent": w, "FrameHeightSent": h, "FrameRateSent": fps])
                self.statsView.setupView(stats: stats, status: .sent)
           }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [unowned self] in
            self.skylinkConnection.getReceivedVideoResolution(withMediaId: self.remoteCameraMediaId) { (w, h, fps, error) in
                print("getReceivedVideoResolution ---> ", w, h, fps, error)
                if error != nil {
                    print(error!.localizedDescription)
                    return
                }
                self.receivedFps = fps
                let stats = Stats(dict: ["FrameWidthReceived": w, "FrameHeightReceived": h, "FrameRateReceived": fps])
                self.statsView.setupView(stats: stats, status: .received)
           }
        }
    }
    
    /**
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        skylinkConnection.getFullStatsReport(ofPeerID: nil) { [weak weakSelf = self] (responseObject) in
            print("FullStatsReport ---> ", responseObject)
        }
        skylinkConnection.getCaptureFormatCallback { (format) in
            print("format ---> ", format)
        }
        skylinkConnection.getCaptureFormatsCallback { (formats) in
            print("formats ---> ", formats)
        }
        skylinkConnection.getCurrentVideoDeviceCallback { (device) in
            print("device ---> ", device)
        }
        skylinkConnection.getCurrentCameraNameCallback { (name) in
            print("name ---> ", name)
        }
    }
     */
    
    func connection(_ connection: SKYLINKConnection, didChangeStats statsDict: [String : Any], ofPeerID peerID: String) {
        let stats = Stats(dict: statsDict)
        statsView.setupView(stats: stats, status: .all)
        DispatchQueue.main.async {
            self.screenViewStack.isHidden = false
        }
    }
    
    func connection(_ connection: SKYLINKConnection, didInputVideoResolutionChange statsDict: [String : Any], ofPeerID peerID: String) {
        print("didInputVideoResolutionChange ---> ", statsDict)
    }
    
    func connection(_ connection: SKYLINKConnection, didReceivedVideoResolutionChange statsDict: [String : Any], ofPeerID peerID: String) {
        print("didReceivedVideoResolutionChange ---> ", statsDict)
    }
    
    func connection(_ connection: SKYLINKConnection, didSentVideoResolutionChange statsDict: [String : Any], ofPeerID peerID: String) {
        print("didSentVideoResolutionChange ---> ", statsDict)
    }
    
    func connection(_ connection: SKYLINKConnection, didInputVideoResolutionChange statsDict: [String : Any], width: Int, height: Int, fps: Int, ofPeerID peerID: String) {
        print("didInputVideoResolutionChange ---> ", statsDict, "width ---> ", width, "height ---> ", height, "fps ---> ", fps)
    }
    
    // MARK: - Open file feature
    @IBAction func openFiles() {
        let inAppBtn = UIButton(frame: CGRect(x: 10, y: localVideoContainerView.frame.maxY + 10, width: 250, height: 40))
        inAppBtn.setTitle("Open the files inside your app", for: .normal)
        inAppBtn.addTarget(self, action: #selector(inAppClicked), for: .touchUpInside)
        view.addSubview(inAppBtn)
        self.inAppBtn = inAppBtn
        let systemBtn = UIButton(frame: CGRect(x: 10, y: inAppBtn.frame.maxY + 10, width: 250, height: 40))
        systemBtn.setTitle("Open the files of your device", for: .normal)
        systemBtn.addTarget(self, action: #selector(systemClicked), for: .touchUpInside)
        view.addSubview(systemBtn)
        self.systemBtn = systemBtn
    }
    
    @objc func inAppClicked() {
        let insideVc = InsideFilesViewController(nibName: "InsideFilesViewController", bundle: nil)
        insideVc.view.frame = CGRect(x: 0, y: 70, width: SCREEN_WIDTH, height: SCREEN_HEIGHT - 130)
        inAppBtn.isEnabled = false
        insideVc.backClosure = {
            self.inAppBtn.isEnabled = true
        }
        view.addSubview(insideVc.view)
        addChild(insideVc)
    }
    
    @objc func systemClicked() {
        let outsideVc = WrapViewController(nibName: "WrapViewController", bundle: nil)
        outsideVc.view.frame = CGRect(x: 0, y: 70, width: SCREEN_WIDTH, height: SCREEN_HEIGHT - 130)
        systemBtn.isEnabled = false
        outsideVc.backClosure = {
            self.systemBtn.isEnabled = true
        }
        view.addSubview(outsideVc.view)
        addChild(outsideVc)
    }
    // MARK: -
    @IBAction func tap(_ sender: UITapGestureRecognizer) {
        // switch the video track of remotePeerVideoContainerView and remotePeerVideoContainerView2
        if let videoView1 = remotePeerVideoContainerView.subviews.first, let videoView2 = remotePeerVideoContainerView2.subviews.first, videoView2.isKind(of: UIView.self) {
            addRenderedVideo(videoView: videoView1, insideContainer: remotePeerVideoContainerView2, mirror: false)
            addRenderedVideo(videoView: videoView2, insideContainer: remotePeerVideoContainerView, mirror: false)
            videoView1.aspectFitRectForSize(insideSize: videoView1.frame.size, inContainer: remotePeerVideoContainerView2)
            videoView2.aspectFitRectForSize(insideSize: videoView2.frame.size, inContainer: remotePeerVideoContainerView)
        }
    }
    
// MARK: - Private functions
    private func changeLocalMediaState(mediaId: String, state: SKYLINKMediaState){
        self.activityIndicator.startAnimating()
        skylinkConnection.changeLocalMediaState(withMediaId: mediaId, mediaState: state) { (error) in
            if let error = error {
                UIAlertController.showAlertWithAutoDisappear(title: "Error", message: String(describing: error.localizedDescription), duration: 3, onViewController: self)
            }
            self.activityIndicator.stopAnimating()
        }
    }

    private func destroyLocalMedia(){
        while !localMedias.isEmpty {
            if let media = localMedias.first{
                localMedias.remove(media)
                skylinkConnection.destroyLocalMedia(withMediaId: media.skylinkMediaID(), callback: nil)
            }
        }
    }
    private func reloadVideoView(){
        _ = videoViews.map{$0.removeSubviews()}
        _ = localMedias.map({ (media) -> () in
            addRenderedVideo(videoView: media.skylinkVideoView() ?? UIView(), insideContainer: (media.skylinkMediaType() == SKYLINKMediaTypeVideoCamera) ? localVideoContainerView : localVideoContainerView2, mirror: true)
        })
        _ = remoteMedias.map({ (media) -> () in
            addRenderedVideo(videoView: media.skylinkVideoView() ?? UIView(), insideContainer: (media.skylinkMediaType() == SKYLINKMediaTypeVideoCamera) ? remotePeerVideoContainerView : remotePeerVideoContainerView2, mirror: true)
        })
    }
    @objc fileprivate func startRecording() {
        if !skylinkConnection.isRecording() {
            skylinkConnection.startRecording { (error) in
                if error != nil {
                    print(error!.localizedDescription)
                }
                UIAlertController.showAlertWithAutoDisappear(title: nil, message: "You recording is started", duration: 2, onViewController: self)
            }
        }
    }

    @objc fileprivate func stopRecording() {
        if skylinkConnection.isRecording() {
            skylinkConnection.stopRecording { (error) in
                if error != nil {
                    print(error!.localizedDescription)
                }
                UIAlertController.showAlertWithAutoDisappear(title: nil, message: "You recording is stopped", duration: 2, onViewController: self)
            }
        }
    }
    
    fileprivate func alertMessage(msg_title: String, msg:String) {
        let alertController = UIAlertController(title: msg_title , message: msg, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(OKAction)
        present(alertController, animated: true, completion: nil)
    }
    @objc fileprivate func backToMainMenu() {
        activityIndicator.startAnimating()
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        skylinkConnection.unlockTheRoom(nil)
        skylinkConnection.disconnect({ [unowned self] error in
            guard let _ = error else{
                self.navigationController?.popViewController(animated: true)
                self.remotePeerVideoContainerView.removeSubviews()
                self.remotePeerVideoContainerView2.removeSubviews()
                return
            }
        })
    }
// MARK: - ACTIONS
    @IBAction func joinRoom(_ sender: Any) {
        self.activityIndicator.startAnimating()
        if isJoinRoom {
            NSObject.cancelPreviousPerformRequests(withTarget: self)
            skylinkConnection.unlockTheRoom(nil)
            self.leaveRoom {
                self.remotePeerVideoContainerView.removeSubviews()
                self.remotePeerVideoContainerView2.removeSubviews()
                self.destroyLocalMedia()
                self.callButton.setBackgroundImage(UIImage(named: "call_on"), for: .normal)
                self.activityIndicator.stopAnimating()
            }
        }else{
            self.joinRoom()
        }
        isJoinRoom = !isJoinRoom
    }
    
    @IBAction func startCamera() {
        skylinkConnection.createLocalMedia(with: SKYLINKMediaDeviceCameraFront, mediaMetadata: "", callback: {error in
            if let error = error {
                UIAlertController.showAlertWithAutoDisappear(title: "Error", message: String(describing: error.localizedDescription), duration: 3, onViewController: self)
            }
        });
    }
    
    @IBAction func startAudio() {
        skylinkConnection.createLocalMedia(with: SKYLINKMediaDeviceMicrophone, mediaMetadata: "", callback: {error in
            if let error = error {
                UIAlertController.showAlertWithAutoDisappear(title: "Error", message: String(describing: error.localizedDescription), duration: 3, onViewController: self)
            }
        });
    }
    
    @IBAction func startScreen() {
        skylinkConnection.createLocalMedia(with: SKYLINKMediaDeviceScreen, mediaMetadata: "", callback: {error in
            if let error = error {
                UIAlertController.showAlertWithAutoDisappear(title: "ErrorCode: \(error.code)", message: String(describing: error.localizedDescription), duration: 3, onViewController: self)
            }
        });
    }
    
    
    @IBAction func videoStateChanged(_ sender: UISegmentedControl) {
        if !isJoinRoom {
            sender.selectedSegmentIndex = 0;
            return
        }
        for media in localMedias {
            if media.skylinkMediaType() == SKYLINKMediaTypeVideoCamera {
                changeLocalMediaState(mediaId: media.skylinkMediaID(), state: SKYLINKMediaState(rawValue: SKYLINKMediaState.RawValue(sender.selectedSegmentIndex+1)))
            }
        }
    }
    
    @IBAction func audioStateChanged(_ sender: UISegmentedControl) {
        if !isJoinRoom {
            sender.selectedSegmentIndex = 0;
            return
        }
        for media in localMedias {
            if media.skylinkMediaType() == SKYLINKMediaTypeAudio {
                changeLocalMediaState(mediaId: media.skylinkMediaID(), state: SKYLINKMediaState(rawValue: SKYLINKMediaState.RawValue(sender.selectedSegmentIndex+1)))
            }
        }
    }
    
    @IBAction func screenStateChanged(_ sender: UISegmentedControl) {
        if !isJoinRoom {
            sender.selectedSegmentIndex = 0;
            return
        }
        for media in localMedias {
            if media.skylinkMediaType() == SKYLINKMediaTypeVideoScreen {
                changeLocalMediaState(mediaId: media.skylinkMediaID(), state: SKYLINKMediaState(rawValue: SKYLINKMediaState.RawValue(sender.selectedSegmentIndex+1)))
                }
        }
    }
    @IBAction func removeTrack(_ sender: UIButton) {
        let localVideo: SKYLINKMedia? = localMedias.filter{Int($0.skylinkMediaType().rawValue)==sender.tag}.first
        skylinkConnection.destroyLocalMedia(withMediaId: localVideo?.skylinkMediaID() ?? "") { (error) in
            if let error = error{
                print("failed to remove track \(error)")
            }
        }
    }
    // Call this method when the user has finished interacting with the view controller and a broadcast stream can start
    @available(iOS 11.0, *)
    func userDidFinishSetup() {
        // URL of the resource where broadcast can be viewed that will be returned to the application
        let broadcastURL = URL(string:"https://appr.tc/r/")
        // Dictionary with setup information that will be provided to broadcast extension when broadcast is started
        let setupInfo = [NSLocalizedDescriptionKey: "Skylink" as NSCoding & NSObjectProtocol]
        // Tell ReplayKit that the extension is finished setting up and can begin broadcasting
        extensionContext?.completeRequest(withBroadcast: broadcastURL!, setupInfo: setupInfo)
        print("userDidFinishSetup setupInfo ---> ", setupInfo)
    }
    
    @available(iOS 11.0, *)
    func userDidCancelSetup() {
        let error = NSError(domain: "io.temasys.www", code: -100, userInfo: nil)
        // Tell ReplayKit that the extension was cancelled by the user
        extensionContext?.cancelRequest(withError: error)
    }
}
