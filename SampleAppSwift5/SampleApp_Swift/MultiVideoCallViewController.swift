//
//  MultiVideoCallViewController.swift
//  SampleApp
//
//  Created by  Temasys on 26/7/17.
//  Copyright © 2017  Temasys. All rights reserved.
//

import UIKit
import AVFoundation

struct Usesr{
    let username: String?
    let password: String?
    let address: String?
    let number: String?
}
class MultiVideoCallViewController: SKConnectableVC, SKYLINKConnectionLifeCycleDelegate, SKYLINKConnectionMediaDelegate, SKYLINKConnectionRemotePeerDelegate, SKYLINKConnectionRecordingDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
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
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet var videoContainers: [UIView]!
    @IBOutlet weak var toggleCameraButton: UIButton!
    @IBOutlet weak var partipationsVC: UIViewController!
    @IBOutlet weak var restartButton: UIButton!
    
    @IBOutlet weak var pickerViewContainer: UIView!
    
    
    weak var statsView: StatsView!
    var peerObjects: [SAPeerObject] = []
    var isLocalCameraRunning = true
    lazy var peerIds = [String]()
    lazy var peersInfos = [String : Any]()
    
    var isRoomLocked = false
    var peerToGetStats: String?
    var cameraMediaID = ""
    var audioMediaID = ""
//MARK: - INIT
    override func initData() {
        super.initData()
        if roomName.count==0{
            roomName = ROOM_MULTI_VIDEO
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.skylinkConnection.createLocalMedia(with: SKYLINKMediaDeviceCameraFront, mediaMetadata: USER_NAME, callback: nil)
            self.skylinkConnection.createLocalMedia(with: SKYLINKMediaDeviceMicrophone, mediaMetadata: USER_NAME, callback: nil)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.joinRoom()
        }
    }
    override func initUI() {
        super.initUI()
        title = "Room: \(roomName)"
        let _participantsBtn = UIBarButtonItem(title: "Participants(\(peerObjects.count))", style: .plain, target: self, action: #selector(showParticipants))
        var _currentItems = navigationItem.rightBarButtonItems
        _currentItems?.append(_participantsBtn)
        navigationItem.rightBarButtonItems = _currentItems
        //Disable Button
        btnFlipCamera.isEnabled = false
        btnAudioTap.isEnabled = false
        btnCameraTap.isEnabled = false
        lockButton.isEnabled = false
        if let statView = UINib(nibName: "StatsView", bundle: nil).instantiate(withOwner: nil, options: nil).first as? StatsView {
            statView.frame = CGRect(x: 120, y: 100, width: 250, height: 90)
            view.addSubview(statView)
            self.statsView = statView
        }
    }
    override func initSkylinkConnection() -> SKYLINKConnection {
        // Creating configuration
        let config = SKYLINKConnectionConfig()
        
        config.setAudioVideoSend(AudioVideoConfig_AUDIO_AND_VIDEO)
        config.setAudioVideoReceive(AudioVideoConfig_AUDIO_AND_VIDEO)
        config.isMultiTrackCreateEnable = true
        config.isMirrorLocalFrontCameraView = true
        // Creating SKYLINKConnection
        if let skylinkConnection = SKYLINKConnection(config: config, callback: nil) {
            skylinkConnection.lifeCycleDelegate = self
            skylinkConnection.mediaDelegate = self
            skylinkConnection.remotePeerDelegate = self
            skylinkConnection.recordingDelegate = self
            skylinkConnection.enableLogs = true
            return skylinkConnection
        } else {
            return SKYLINKConnection()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updatePeersVideosFrames()
    }
//MARK: -
    private func setupToolBar(){
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
        toolBar.sizeToFit()
    }
    
    @objc func showParticipants(){
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
            guard let dict = peersInfos[peerIds[i]] as? [String : Any], let _ = dict["videoView"] as? UIView, let _ = dict["videoSize"] as? CGSize else { return }
        }
    }
    
    fileprivate func lockRoom(shouldLock: Bool) {
        (shouldLock) ? skylinkConnection.lockTheRoom(nil) : skylinkConnection.unlockTheRoom(nil)
        isRoomLocked = shouldLock
        lockButton.setImage(UIImage(named: ((isRoomLocked) ? "LockFilled" : "Unlock.png")), for: .normal)
    }
    
    fileprivate func containerViewForVideoView(videoView: UIView) -> UIView {
        var correspondingContainerView = UIView()
        if videoView.isDescendant(of: localVideoContainerView) {
            correspondingContainerView = localVideoContainerView ?? UIView()
        } else if videoView.isDescendant(of: firstPeerVideoContainerView) {
            correspondingContainerView = firstPeerVideoContainerView ?? UIView()
        } else if videoView.isDescendant(of: secondPeerVideoContainerView) {
            correspondingContainerView = secondPeerVideoContainerView ?? UIView()
        } else if videoView.isDescendant(of: thirdPeerVideoContainerView) {
            correspondingContainerView = thirdPeerVideoContainerView ?? UIView()
        }
        return correspondingContainerView
    }
    
    
    fileprivate func addRenderedVideo(videoView: UIView, insideContainer containerView: UIView) {
        skylinkLog("I_addRenderedVideo")
        videoView.frame = containerView.bounds
        _ = containerView.subviews.map { $0.removeFromSuperview() }
        containerView.insertSubview(videoView, at: 0)
        updatePeersVideosFrames()
    }
    
    fileprivate func indexForContainerView(v: UIView) -> Int {
        let viewArr = [firstPeerVideoContainerView, secondPeerVideoContainerView, thirdPeerVideoContainerView]
        var idx = 0
        _ = viewArr.enumerated().map { (index,view) in
            if v == view { idx = index }
        }
        if idx > viewArr.count { idx = 0 }
        return idx
    }
    
    fileprivate func refreshPeerViews() {
        let peerContainerViews = [firstPeerVideoContainerView ?? UIView(), secondPeerVideoContainerView ?? UIView(), thirdPeerVideoContainerView ?? UIView()]        
        let peerLabels = [firstPeerLabel ?? UILabel(), secondPeerLabel ?? UILabel(), thirdPeerLabel ?? UILabel()]
        for i in 0..<peersInfos.count  {
            guard i < peerIds.count, let index = peerIds.firstIndex(of: peerIds[i]), let dict = peersInfos[peerIds[i]] as? [String : Any] else { return }
            let videoView = dict["videoView"] as? UIView
            if (index < peerContainerViews.count) {
                if videoView == nil {
                    print("Cannot render the video view. Camera not found")
                } else {
                    addRenderedVideo(videoView: videoView!, insideContainer: peerContainerViews[index])
                }
            }
            // refresh the label
            guard let audioMuted = dict["isAudioMuted"] as? Bool, let videoMuted = dict["isVideoMuted"] as? Bool else { return }
            
            var mutedInfos = ""
            if audioMuted {
                mutedInfos = "Audio muted"
            }
            if videoMuted {
                mutedInfos = mutedInfos.count != 0 ? "Video & ".appending(mutedInfos) : "Video muted"
            }
            if index < peerLabels.count {
                peerLabels[index].text = mutedInfos
            }
            if index < peerLabels.count {
                peerLabels[index].isHidden = !(mutedInfos.count != 0)
            }
        }
        updatePeersVideosFrames()
        pickerView.reloadAllComponents()
    }
    func reloadParticipants(){
        let participantsBtn = navigationItem.rightBarButtonItems?[1]
        participantsBtn?.title = "Participants(\(peerObjects.count+1))"
    }
    // SKYLINK SDK Delegates methods
    
// MARK: SKYLINKConnectionMediaDelegate
    func connection(_ connection: SKYLINKConnection, didCreateLocalMedia localMedia: SKYLINKMedia){
        if localMedia.skylinkMediaType() == SKYLINKMediaTypeVideoCamera {
            cameraMediaID = localMedia.skylinkMediaID()
        }
        if localMedia.skylinkMediaType() == SKYLINKMediaTypeAudio {
            audioMediaID = localMedia.skylinkMediaID()
        }
        if let videoView = localMedia.skylinkVideoView() {
            addRenderedVideo(videoView: videoView, insideContainer: localVideoContainerView)
        }
        getStats()
        self.activityIndicator.stopAnimating()
        reloadParticipants()
    }
    func connection(_ connection: SKYLINKConnection, didChangeVideoSize videoSize: CGSize, videoView: UIView!, peerId: String) {
        if videoSize.height > 0 && videoSize.width > 0 {
            let correspondingContainerView = containerViewForVideoView(videoView: videoView)
            if correspondingContainerView != localVideoContainerView {
                let i = indexForContainerView(v: correspondingContainerView)
                guard peerIds.count > 0,
                    let dict = peersInfos[peerIds[i]] as? [String : Any],
                    let videoSize = dict["videoSize"] as? CGSize,
                    let videoView = dict["videoView"] as? UIView,
                    let isAudioMuted = dict["isAudioMuted"] as? Bool,
                    let isVideoMuted = dict["isVideoMuted"] as? Bool else { return }
                if i != NSNotFound {
                    peersInfos[peerIds[i]] = ["videoView" : videoView, "videoSize" : videoSize, "isAudioMuted" : isAudioMuted, "isVideoMuted" : isVideoMuted]
                }
            }
            videoView.frame = (videoAspectSegmentControl.selectedSegmentIndex == 0 || correspondingContainerView.isEqual(localVideoContainerView)) ? aspectFillRectForSize(insideSize: videoSize, containedInRect: correspondingContainerView.frame): AVMakeRect(aspectRatio: videoSize, insideRect: correspondingContainerView.bounds)
        }
    }
    func connection(_ connection: SKYLINKConnection, didReceiveRemoteMedia remoteMedia: SKYLINKMedia, remotePeerId: String!) {
        print("CCC == RECEIVE MEDIA peerid: \(String(describing: remotePeerId))")
        let peerObj = peerObjects.filter{$0.peerId == remotePeerId}.first
        if peerObj != nil{
            print("videoView: \(remoteMedia.skylinkVideoView())")
            peerObj?.videoView = remoteMedia.skylinkVideoView()
            reloadVideoViews()
        } else {
            peerObjects.append(SAPeerObject(peerId: remotePeerId, userName: nil, videoView: nil, videoSize: nil))
            reloadParticipants()
        }
        var bool = false
        _ = peersInfos.keys.map {
            if $0 == remotePeerId { bool = true }
        }
        if !bool {
            peersInfos[remotePeerId] = ["videoView": NSNull(), "videoSize": CGSize.zero, "isAudioMuted": false, "isVideoMuted": false]
        }
        guard let dict = peersInfos[remotePeerId] as? [String : Any], let videoSize = dict["videoSize"] as? CGSize, let isAudioMuted = dict["isAudioMuted"] as? Bool, let isVideoMuted = dict["isVideoMuted"] as? Bool else { return }
        
        peersInfos[remotePeerId] = ["videoView" : remoteMedia.skylinkVideoView() ?? "nil", "videoSize" : videoSize, "isAudioMuted" : isAudioMuted, "isVideoMuted" : isVideoMuted]
        refreshPeerViews()
        
        getStats()
    }
    func connection(_ connection: SKYLINKConnection, didToggleAudio isMuted: Bool, peerId: String!) {
        let bool = peersInfos.keys.contains(peerId)
        if bool {
            guard let dict = peersInfos[peerId] as? [String : Any], let videoSize = dict["videoSize"] as? CGSize, let videoView = dict["videoView"] as? UIView, let isVideoMuted = dict["isVideoMuted"] as? Bool else { return }
            let isAudioMuted = isMuted
            peersInfos[peerId] = ["videoView" : videoView, "videoSize" : videoSize, "isAudioMuted" : isAudioMuted, "isVideoMuted" : isVideoMuted]
        }
        refreshPeerViews()
    }
    
    func connection(_ connection: SKYLINKConnection, didToggleVideo isMuted: Bool, peerId: String!) {
        skylinkLog("imat_didToggleVideo")
        let bool = peersInfos.keys.contains { _ in return true }
        if bool {
            guard let dict = peersInfos[peerId] as? [String : Any], let videoSize = dict["videoSize"] as? CGSize, let videoView = dict["videoView"] as? UIView, let isAudioMuted = dict["isAudioMuted"] as? Bool else { return }
            let isVideoMuted = isMuted
            peersInfos[peerId] = ["videoView" : videoView, "videoSize" : videoSize, "isAudioMuted" : isAudioMuted, "isVideoMuted" : isVideoMuted]
        }
        refreshPeerViews()
    }
    
    // MARK: SKYLINKConnectionLifeCycleDelegate
    func connectionDidConnect(toRoomSuccessful connection: SKYLINKConnection) {
        skylinkLog("Inside \(#function)")
        localVideoContainerView.alpha = 1
        DispatchQueue.main.async { [weak weakSelf = self] in
            weakSelf?.activityIndicator.stopAnimating()
            //Enable Btn
            weakSelf?.btnAudioTap.isEnabled = true
            weakSelf?.btnFlipCamera.isEnabled = true
            weakSelf?.btnCameraTap.isEnabled = true
            weakSelf?.lockButton.isEnabled = true
        }
    }
    
    func connection(_ connection: SKYLINKConnection, didConnectToRoomFailed errorMessage: String!) {
        let msgTitle = "Connection failed"
        let msg = errorMessage
        alertMessage(msg_title: msgTitle, msg:msg!)
    }
    
    func connection(_ connection: SKYLINKConnection, didLockTheRoom lockStatus: Bool, remotePeerId peerId: String!) {
        isRoomLocked = lockStatus
        lockButton.setImage(UIImage(named: (isRoomLocked ? "LockFilled" : "Unlock.png")), for: .normal)
    }
// MARK: SKYLINKConnectionRemotePeerDelegate
    func connection(_ connection: SKYLINKConnection, didChangeLocalMedia localMedia: SKYLINKMedia) {
        print("saa changed local media: \(localMedia.skylinkMediaType())")
        print("state: \(localMedia.skylinkMediaState())")
        self.activityIndicator.stopAnimating()
    }
    
    func connection(_ connection: SKYLINKConnection, didChangeRemoteMedia remoteMedia: SKYLINKMedia, remotePeerId: String!) {
        print("CCC == CHANGE MEDIA ROOM peerId: \(String(describing: remotePeerId))")
        _ = peerObjects.filter { $0.peerId == remotePeerId }.map { $0.videoView = remoteMedia.skylinkVideoView() }
        reloadVideoViews()
        
        switch remoteMedia.skylinkMediaType() {
        case SKYLINKMediaTypeVideoCamera:
            if remoteMedia.skylinkMediaState() == SKYLINKMediaStateUnavailable {
                let index = peerIds.firstIndex(of: remotePeerId)
                if index == 0 {
                    firstPeerVideoContainerView.removeSubviews()
                } else if index == 1 {
                    secondPeerVideoContainerView.removeSubviews()
                } else if index == 2 {
                    thirdPeerVideoContainerView.removeSubviews()
                } else {
                    print("No such view")
                }
                return
            }
            if remoteMedia.skylinkMediaState() == SKYLINKMediaStateStopped {
                let index = peerIds.firstIndex(of: remotePeerId)
                if index == 0 {
                    addRenderedVideo(videoView: UIView(), insideContainer: firstPeerVideoContainerView)
                } else if index == 1 {
                    addRenderedVideo(videoView: UIView(), insideContainer: secondPeerVideoContainerView)
                } else if index == 2 {
                    addRenderedVideo(videoView: UIView(), insideContainer: thirdPeerVideoContainerView)
                } else {
                    print("No such view")
                }
            }
            if remoteMedia.skylinkMediaState() == SKYLINKMediaStateMuted {
                
            }
            if remoteMedia.skylinkMediaState() == SKYLINKMediaStateActive {
                if let videoView = remoteMedia.skylinkVideoView() {
                    let index = peerIds.firstIndex(of: remotePeerId)
                    if index == 0 {
                        addRenderedVideo(videoView: videoView, insideContainer: firstPeerVideoContainerView)
                    } else if index == 1 {
                        addRenderedVideo(videoView: videoView, insideContainer: secondPeerVideoContainerView)
                    } else if index == 2 {
                        addRenderedVideo(videoView: videoView, insideContainer: thirdPeerVideoContainerView)
                    } else {
                        print("No such view")
                    }
                }
            }
        case SKYLINKMediaTypeAudio:
            if let videoView = remoteMedia.skylinkVideoView() {
                let index = peerIds.firstIndex(of: remotePeerId)
                if index == 0 {
                    addRenderedVideo(videoView: videoView, insideContainer: firstPeerVideoContainerView)
                } else if index == 1 {
                    addRenderedVideo(videoView: videoView, insideContainer: secondPeerVideoContainerView)
                } else if index == 2 {
                    addRenderedVideo(videoView: videoView, insideContainer: thirdPeerVideoContainerView)
                } else {
                    print("No such view")
                }
            }
        default: break
        }
    }
    
    func connection(_ connection: SKYLINKConnection, didConnectWithRemotePeer remotePeerId: String!, userInfo: Any!, hasDataChannel: Bool) {
        print("CCC == JOIN ROOM peerId: \(String(describing: remotePeerId))")
        let peerObj = peerObjects.filter { $0.peerId == remotePeerId }.first
        if peerObj == nil{
            var userData: String?
            if let userInfo = userInfo as? [String:Any]{
                userData = userInfo["userData"] as? String
            }
            peerObjects.append(SAPeerObject(peerId: remotePeerId, userName: userData ?? "USER_NAME", videoView: nil, videoSize: nil))
            reloadParticipants()
        } else {
            peerObj?.userName = userInfo as? String
            var userData: String?
            if let userInfo = userInfo as? [String:Any]{
                userData = userInfo["userData"] as? String
            }
            peerObj?.userName = userData
        }
        if !peerIds.contains(remotePeerId) {
            peerIds.append(remotePeerId)
        }
        var bool = false
        _ = peersInfos.keys.map { if $0 == remotePeerId { bool = true } }
        if !bool {
            peersInfos[remotePeerId] = ["videoView": NSNull(), "videoSize": CGSize.zero, "isAudioMuted": false, "isVideoMuted": false]
        }
        refreshPeerViews()
    }
    
    func connection(_ connection: SKYLINKConnection, didReceiveRemotePeerLeaveRoom remotePeerId: String!, infoCode: Int, userInfo: Any!) {
        print("CCC == LEAVE ROOM peerId: \(String(describing: remotePeerId))")
        if peerIds.count != 0 {
            peerIds.remove(at: peerIds.firstIndex(of: remotePeerId)!)
            peerObjects.removeAll(where: {$0.peerId == remotePeerId})
        }
        lockRoom(shouldLock: false)
        reloadVideoViews()
    }
    func connection(_ connection: SKYLINKConnection, didDisconnectWithRemotePeer remotePeerId: String, userInfo: Any!, hasDataChannel: Bool) {
        print("CCC == DISCONNECTED With peerId: \(String(describing: remotePeerId))")
        if peerIds.count != 0 {
            peerObjects.removeAll(where: {$0.peerId == remotePeerId})
        }
        lockRoom(shouldLock: false)
        reloadVideoViews()
        refreshPeerViews()
    }
    func connection(_ connection: SKYLINKConnection, didStartRecordingWithID recordingID: String!) {
        UIAlertController.showAlertWithAutoDisappear(title: "Recording", message: "recordingID \(recordingID ?? "") start recording!", duration: 3, onViewController: self)
    }
    func connection(_ connection: SKYLINKConnection, didStopRecordingWithID recordingID: String!) {
        UIAlertController.showAlertWithAutoDisappear(title: "Recording", message: "recordingID \(recordingID ?? "") stop recording!", duration: 3, onViewController: self)
    }
    func connection(_ connection: SKYLINKConnection, didReceiveRecordingError error: Error?, recordingId: String!) {
        UIAlertController.showAlertWithAutoDisappear(title: "Error", message: (error != nil) ? String(describing: error?.localizedDescription) : "", duration: 3, onViewController: self)
    }
    func connection(_ connection: SKYLINKConnection, didRefreshRemotePeerConnection remotePeerId: String!, userInfo: Any!, hasDataChannel: Bool, isIceRestarted: Bool) {
        UIAlertController.showAlertWithAutoDisappear(title: "Refresh", message: "remotePeerId: \(remotePeerId ?? "")", duration: 4, onViewController: self)
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
        skylinkConnection.switchCamera(nil)
    }
    
    @IBAction func switchLockTap() {
        lockRoom(shouldLock: !isRoomLocked)
    }
    
    @IBAction func recording(_ sender: UISwitch) {
        sender.isOn ? startRecording() : stopRecording()
    }
    @IBAction func videoAspectSegmentControlChanged() {
        updatePeersVideosFrames()
    }
    
    @IBAction func toggleCamera() {
        skylinkConnection.changeLocalMediaState(withMediaId: cameraMediaID, mediaState: isLocalCameraRunning ? SKYLINKMediaStateStopped : SKYLINKMediaStateActive) { (error) in
            
        }
        isLocalCameraRunning = !isLocalCameraRunning
        toggleCameraButton.tintColor = isLocalCameraRunning ? .white : .red
        toggleCameraButton.setImage(UIImage(named: isLocalCameraRunning ? "VideoCall.png" : "NoVideoFilled.png"), for: .normal)
    }
    @IBAction func restart(_ sender: Any) {
        pickerViewContainer.isHidden = false
    }
    @IBAction func toolbarDone(_ sender: Any){
        pickerViewContainer.isHidden = true
    }
    @IBAction func toolbarSend(_ sender: Any){
        pickerViewContainer.isHidden = true
        if pickerView.selectedRow(inComponent: 0) == 0 {
            skylinkConnection.refreshConnection(withRemotePeerId: nil, doIceRestart: true, callback: nil)
        }else{
            let peerId: String = peerObjects[pickerView.selectedRow(inComponent: 0)-1].peerId ?? ""
            skylinkConnection.refreshConnection(withRemotePeerId: peerId, doIceRestart: true, callback: nil)
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        print("picker items: \(peerObjects.count)")
        return peerObjects.count+1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row == 0 {
            return "All"
        }
        print("picker title: \(peerObjects[row-1].peerId ?? "")")
        return (peerObjects[row-1].userName ?? "") + ": " + (peerObjects[row-1].peerId ?? "")
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {

    }
    
    @IBAction func setStats() {
    }
    
    @IBAction func getStats() {
    }
    
    //MARK: -
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
    func addRenderRemoteVideoToView(videoView: UIView){
        if let emptyContainer = videoContainers.first(where: {$0.subviews.isEmpty}){
            print("Container Index: \(videoContainers.firstIndex(of: emptyContainer) ?? -1)")
            addRenderedVideo(videoView: videoView, insideContainer: emptyContainer)
        }
    }
    
    func reloadVideoViews(){
        print("Reload========================================== \(peerObjects.count)")
        print("peerObjects: \(peerObjects)")
        _ = videoContainers.map{$0.removeSubviews()}
        for peer in peerObjects{
            if let videoView = peer.videoView{
                let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 20))
                
                addRenderRemoteVideoToView(videoView: videoView)
                if let videoSize = peer.videoSize{
                    _ = videoContainers.filter {videoView.isDescendant(of: $0)}.map{videoView.aspectFitRectForSize(insideSize: videoSize, inContainer: $0)}
                }
            }
        }
    }
    
    fileprivate func aspectFillRectForSize(insideSize: CGSize, containedInRect containerRect: CGRect) -> CGRect {
        var maxFloat: CGFloat = 0
        if containerRect.size.height > containerRect.size.width {
            maxFloat = containerRect.size.height
        } else if containerRect.size.height < containerRect.size.width {
            maxFloat = containerRect.size.width
        } else {
            maxFloat = 0
        }
        var aspectRatio: CGFloat = 0
        if insideSize.height != 0 {
            aspectRatio = insideSize.width / insideSize.height
        } else {
            aspectRatio = 1
        }
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
}
