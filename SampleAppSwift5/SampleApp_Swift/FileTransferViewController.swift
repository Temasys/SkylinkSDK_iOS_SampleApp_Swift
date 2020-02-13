//
//  FileTransferViewController.swift
//  SampleApp
//
//  Created by  Temasys on 26/7/17.
//  Copyright © 2017  Temasys. All rights reserved.
//

import UIKit
import MediaPlayer
import AssetsLibrary
import MobileCoreServices
import Photos
import AVFoundation

class FileTransferViewController: SKConnectableVC, SKYLINKConnectionLifeCycleDelegate, SKYLINKConnectionFileTransferDelegate, SKYLINKConnectionRemotePeerDelegate, MPMediaPickerControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var peersTableView: UITableView!
    @IBOutlet weak var fileTransferTableView: UITableView!
    
    var alerts : [UIAlertController] = []
    lazy var remotePeerArray = [String]() // array holding the ids (strings) of the peers connected to the room
    lazy var transfersArray = [[String : Any]]() // array of dictionnaries holding infos about started (and finished) file transfers
    var musicPlayer: AVAudioPlayer?
    var selectedRow = -1
//MARK: - INIT
    override func initUI() {
        super.initUI()
        title = "File Transfer"
    }
    override func initData() {
        super.initUI()
        roomName = ROOM_FILE_TRANSFER
        joinRoom()
        NotificationCenter.default.addObserver(self, selector: #selector(needPermission), name: NSNotification.Name.SKYLINKRequiresPermission, object: nil)
    }
    override func initSkylinkConnection() -> SKYLINKConnection {
        let config = SKYLINKConnectionConfig()
        config.setAudioVideoSend(AudioVideoConfig_NO_AUDIO_NO_VIDEO)
        config.setAudioVideoReceive(AudioVideoConfig_NO_AUDIO_NO_VIDEO)
        config.hasFileTransfer = true
        config.setTimeout(30, skylinkAction: SkylinkAction_FILE_SEND_REQUEST)
        skylinkLog(config.description)
        if let skylinkConnection = SKYLINKConnection(config: config, callback: nil) {
            skylinkConnection.lifeCycleDelegate = self
            skylinkConnection.fileTransferDelegate = self
            skylinkConnection.remotePeerDelegate = self
            skylinkConnection.enableLogs = true
            return skylinkConnection
        } else {
            return SKYLINKConnection()
        }
    }
//MARK: -
    
    @objc fileprivate func needPermission() {
        
    }
    
    fileprivate func showAlert() {
        if let alert = alerts.last {
            let okayAction = UIAlertAction(title: "OK", style: .default) { [weak weakSelf = self] action in
                weakSelf?.alerts.remove(at: (weakSelf?.alerts.count ?? 1) - 1)
                weakSelf?.showAlert()
            }
            if alerts.count == 1 && alert.actions.count == 0{
                alert.addAction(okayAction)
                present(alert, animated: true, completion: nil)
            } else {
                presentedViewController?.dismiss(animated: false, completion: nil)
                if alert.actions.count == 0 {
                    alert.addAction(okayAction)
                    present(alert, animated: true, completion: nil)
                } else {
                    present(alert, animated: true, completion: nil)
                }
            }
        } else {
            skylinkLog("All alerts shown")
        }
    }
    
    // MARK: - Table view data source delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == peersTableView {
            return remotePeerArray.count
        } else if tableView == fileTransferTableView {
            return transfersArray.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == peersTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "peerCell", for: indexPath)
            cell.textLabel?.text = "Peer \(indexPath.row + 1), ID: \(remotePeerArray[indexPath.row])"
            return cell
        } else if tableView == fileTransferTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "fileTransferCell", for: indexPath)
            let trInfos = transfersArray[indexPath.row]
            if let isoutgoing = trInfos["isOutgoing"] as? Bool, let percentage = trInfos["percentage"] as? Float, let state = trInfos["state"] as? String, let filename = trInfos["filename"] as? String, let peerid = trInfos["peerId"] as? String {
                cell.textLabel?.text = String(format: "%@ %.0f%% • %@", (isoutgoing != false) ? "⬆️" : "⬇️", percentage * 100, state)
                cell.detailTextLabel?.text = String(format: "File: %@ • Peer: %@", filename, peerid)
            }
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == peersTableView {
            if section == 0 {
                return remotePeerArray.count > 0 ? "Or select a connected peer recipient:" : "No peer connected yet"
            }
        } else if tableView == fileTransferTableView {
            return "File transfers \(transfersArray.count)"
        }
        return ""
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if tableView == peersTableView && view.isKind(of: UITableViewHeaderFooterView.self) {
            (view as! UITableViewHeaderFooterView).textLabel?.textColor = .lightGray
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if tableView == peersTableView {
            selectedRow = indexPath.row
            showTransferFormForRecipient(peerID: remotePeerArray[indexPath.row])
        } else if tableView == fileTransferTableView {
            let transferInfos = transfersArray[indexPath.row]
            if let state = transferInfos["state"] as? String, state == "In progress" {
                let alert = UIAlertController(title: "Cancel file transfer ?", message: "\nCancel file transfer for filename:\n'\(transferInfos["filename"] ?? "")'\npeer ID:\n\(transferInfos["peerId"] ?? "")", preferredStyle: .alert)
                let dropTrans = UIAlertAction(title: "Drop transfer", style: .default, handler: { [weak weakSelf = self] _ in
                    skylinkLog("\(weakSelf?.transfersArray[indexPath.row]["state"] ?? "")")
                    if let state = weakSelf?.transfersArray[indexPath.row]["state"] as? String, state == "In progress" {
//                        weakSelf?.skylinkConnection.cancelFileTransfer(transferInfos["filename"] as? String ?? "", peerId: transferInfos["peerId"] as? String ?? "")
                        weakSelf?.skylinkConnection.cancelFileTransfer(withRemotePeerId: transferInfos["peerId"] as? String ?? "", forSending: true)
                        weakSelf?.updateFileTranferInfosForFilename(filename: transferInfos["filename"] as? String ?? "", peerId: transferInfos["peerId"] as? String ?? "", withState: "Cancelled", progress: transferInfos["progress"] as? Float ?? 0, isOutgoing: transferInfos["isOutgoing"] as? Bool ?? false)
                    } else {
                        let canNotCancelAlert = UIAlertController(title: "Can not cancel", message: "Transfer already completed", preferredStyle: .alert)
                        weakSelf?.alerts.append(canNotCancelAlert)
                        weakSelf?.showAlert()
                    }
                })
                alert.addAction(dropTrans)
                let cancelBtn = UIAlertAction(title: "Continue transfer", style: .cancel)
                alert.addAction(cancelBtn)
                present(alert, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: "Transfer details", message: transferInfos.description, preferredStyle: .alert)
                alerts.append(alert)
                showAlert()
            }
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        var peerId: String?
        if selectedRow != -1 && selectedRow < remotePeerArray.count {
            peerId = remotePeerArray[selectedRow]
        }
        let url = info[.referenceURL] as? URL
        startFileTransfer(userId: peerId, url: url, type: SKYLINKAssetTypePhoto)
    }
    
    // MARK: - MPMediaPickerControllerDelegate
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        mediaPicker.dismiss(animated: true, completion: nil)
        var peerId: String?
        if selectedRow != -1 && selectedRow < remotePeerArray.count {
            peerId = remotePeerArray[selectedRow]
        }
        startFileTransfer(userId: peerId, url: mediaItemCollection.representativeItem?.value(forProperty: MPMediaItemPropertyAssetURL) as? URL, type: SKYLINKAssetTypeMusic)
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true) {
        }
    }
    
    // SKYLINK Delegate methods implementations
    // MARK: - SKYLINKConnectionLifeCycleDelegate
    func connectionDidConnect(toRoomSuccessful connection: SKYLINKConnection) {
        skylinkLog("Inside \(#function)")
        self.activityIndicator.stopAnimating()
    }
    
    func connection(_ connection: SKYLINKConnection, didConnectWithRemotePeer remotePeerId: String!, userInfo: Any!, hasDataChannel: Bool) {
        skylinkLog("Peer with id %@ joigned the room.\(String(describing: remotePeerId))")
        if !remotePeerArray.contains(remotePeerId) {
            remotePeerArray.append(remotePeerId)
        }
        peersTableView.reloadData()
        self.activityIndicator.stopAnimating()
    }
        
    func connection(_ connection: SKYLINKConnection, didReceiveRemotePeerLeaveRoom remotePeerId: String!, userInfo: Any!, skylinkInfo: [AnyHashable : Any]?) {
        skylinkLog("Peer with id " + remotePeerId + " left the room with message: \(skylinkInfo ?? [:])" )
        remotePeerArray.remove(remotePeerId)
        peersTableView.reloadData()
    }
    
    // MARK: - SKYLINKConnectionFileTransferDelegate
    func connection(_ connection: SKYLINKConnection, didReceiveFileTransferRequest fileName: String!, isPublic: Bool, remotePeerId: String!) {
        let alert = UIAlertController(title: "Accept file transfer ?", message: "\nA user wants to send you a file named:\n'\(String(describing: fileName))'", preferredStyle: .alert)
                let rejectAction=UIAlertAction(title: "Decline", style: .default) { [weak weakSelf = self] _ in
                    weakSelf?.skylinkConnection.rejectFileTransfer(fromRemotePeerId: remotePeerId, callback: nil)
                    weakSelf?.alerts.remove(at: weakSelf!.alerts.count - 1)
                    weakSelf?.showAlert()
                }
                alert.addAction(rejectAction)
                let acceptAction = UIAlertAction(title: "Accept", style: .default){ [weak weakSelf = self] _ in
                    weakSelf?.skylinkConnection.acceptFileTransfer(withFileName: fileName, fromRemotePeerId: remotePeerId, callback: nil)
                    weakSelf?.alerts.remove(at: weakSelf!.alerts.count - 1)
                    weakSelf?.showAlert()
                }
                alert.addAction(acceptAction)
                alerts.append(alert)
                showAlert()
    }
    
    func connection(_ connection: SKYLINKConnection, didReceiveFileTransferResponse wasAccepted: Bool, fileName: String!, remotePeerId: String!) {
        if !wasAccepted {
            let alert = UIAlertController(title: "File refused", message: "The peer ID: \(String(describing: remotePeerId)) has refused your '\(String(describing: fileName))' file sending request", preferredStyle: .alert)
            alerts.append(alert)
            showAlert()
        }
    }

    func connection(_ connection: SKYLINKConnection, didUpdateFileTransferSendingProgress percentage: CGFloat, fileName: String!, remotePeerId: String!) {
        updateFileTranferInfosForFilename(filename: fileName, peerId: (remotePeerId != nil) ? remotePeerId : "all", withState: "In progress", progress: Float(percentage), isOutgoing: true)
    }
    
    func connection(_ connection: SKYLINKConnection, didUpdateFileTransferReceivingProgress percentage: CGFloat, fileName: String!, remotePeerId: String!) {
        updateFileTranferInfosForFilename(filename: fileName, peerId: (remotePeerId != nil) ? remotePeerId : "all", withState: "In progress", progress: Float(percentage), isOutgoing: false)
    }
    
    func connection(_ connection: SKYLINKConnection, didDropFileTransfer fileName: String!, message: String!, isExplicit: Bool, remotePeerId: String!) {
        skylinkLog("connection didDropTransfer")
        updateFileTranferInfosForFilename(filename: fileName, peerId: (remotePeerId != nil) ? remotePeerId : "all", withState: (message != nil) ? message : "Dropped my sender", progress: nil, isOutgoing: nil)
    }
    
    func connection(_ connection: SKYLINKConnection, didCompleteFileTransferSending fileName: String!, remotePeerId: String!) {
        updateFileTranferInfosForFilename(filename: fileName, peerId: (remotePeerId != nil) ? remotePeerId : "all", withState: "Completed ✓", progress: 1, isOutgoing: true)
    }
    
    func connection(_ connection: SKYLINKConnection, didCompleteFileTransferReceiving fileName: String!, fileData: Data!, fileSavePath: String!, remotePeerId: String!) {
        updateFileTranferInfosForFilename(filename: fileName, peerId: (remotePeerId != nil) ? remotePeerId : "all", withState: "Completed ✓", progress: 1, isOutgoing: false)
        if fileData != nil {
            if fileData.count != 0 {
                guard let fileExtension = fileName.components(separatedBy: ".").last else { return }
                let filename1 = fileName.replacingOccurrences(of: " ", with: "_")
                if isImage(exten: fileExtension) == true && UIImage(data: fileData) != nil {
                    UIImageWriteToSavedPhotosAlbum(UIImage(data:fileData)!, self, nil, nil)
                } else if fileExtension == "mp3" || fileExtension == "m4a" {
                    let showMusicAlert: () throws -> Void = { [weak weakSelf = self] in
                        weakSelf?.musicPlayer = try fileExtension == "mp3" ? AVAudioPlayer(data: fileData, fileTypeHint: AVFileType.mp3.rawValue) : AVAudioPlayer(data: fileData)
                        weakSelf?.musicPlayer?.play()
                        let alert = UIAlertController(title: "Music transfer completed", message: "File transfer success.\nPEER: \(String(describing: remotePeerId))\n\nPlaying the received music file:\n'\(String(describing: fileName))'", preferredStyle: .alert)
                        let cancelBtn: UIAlertAction = UIAlertAction(title: "Stop playing", style: .default) { [weak weakSelf = self] _ in
                            weakSelf?.musicPlayer?.stop()
                            weakSelf?.musicPlayer = nil
                        }
                        alert.addAction(cancelBtn)
                        weakSelf?.present(alert, animated: true, completion: nil)
                    }
                    do {
                        try showMusicAlert()
                    } catch {
                        skylinkLog("ERROR IN Music => \(error.localizedDescription)")
                    }
                } else {
                    let pathArray = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                    guard let filePath = (pathArray.first as NSString?)?.appendingPathComponent(filename1) else { return }
                    do {
                        let b = try removeFileAtPath(filePath: filePath)
                        if FileManager.default.fileExists(atPath: filePath) && !b { return }
                    } catch {
                        skylinkLog("ERROR IN remove file => \(error.localizedDescription)")
                    }
                    var wError: Error?
                    do {
                        try fileData.write(to: URL(fileURLWithPath: filePath), options: .atomicWrite)
                    } catch let exception {
                        wError = exception as Error
                        skylinkLog(exception)
                    }
                    if wError != nil {
                        skylinkLog("\(#function) • Error while writing '\(filePath)'->\(wError!.localizedDescription)")
                    } else {
                        if isMovie(exten: fileExtension) && UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath) {
                            /**
                             ALAssetsLibrary().writeVideoAtPath(toSavedPhotosAlbum: URL(fileURLWithPath: filePath), completionBlock: { [weak weakSelf = self] (filePathUrl, error) in
                             if error != nil {
                             skylinkLog("\(#function) • Error while saving '\(filename1)'->\(error!.localizedDescription)")
                             } else {
                             do {
                             if let filePath = filePathUrl?.absoluteString {
                             _ = try weakSelf?.removeFileAtPath(filePath: filePath)
                             }
                             } catch {
                             skylinkLog("Some error => \(error.localizedDescription)")
                             }
                             }
                             })
                             */
                            var placeholder: PHObjectPlaceholder?
                            PHPhotoLibrary.shared().performChanges({
                                if let createAssetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: filePath)) {
                                    placeholder = createAssetRequest.placeholderForCreatedAsset
                                }
                            }, completionHandler: { [weak weakSelf = self] (isSuccess, error) in
                                if isSuccess {
                                    skylinkLog("\(#function) • Error while saving '\(filename1)'->\(error?.localizedDescription)")
                                } else {
                                    do {
                                        _ = try weakSelf?.removeFileAtPath(filePath: filePath)
                                    } catch {
                                        skylinkLog("Some error => \(error.localizedDescription)")
                                    }
                                }
                            })
                            skylinkLog("placeholder ---> \(placeholder?.description ?? "")")
                        }
                    }
                }
            }
        }
    }
    
    func updateFileTranferInfosForFilename(filename: String?, peerId: String?, withState state: String?, progress percentage: Float?, isOutgoing: Bool?) {
        let indexOfTransfer = (transfersArray as NSArray).indexOfObject { (obj, idx, stop) -> Bool in
            if let dict = obj as? [String : Any], let filename2 = dict["filename"] as? String, let peerId2 = dict["peerId"] as? String {
                return (filename2 == filename) && (peerId2 == peerId)
            } else {
                return false
            }
        }
        if indexOfTransfer == NSNotFound {
            let object: [String : Any] = ["filename" : (filename != nil) ? filename! : "none", "peerId" : (peerId != nil) ? peerId! : "No peer Id", "isOutgoing" : isOutgoing ?? false, "percentage" : percentage ?? 0.0, "state" : (state != nil) ? state! : "Undefined"]
            transfersArray.insert(object, at: 0)
        } else { // updated transfer
            var transferInfos = transfersArray[indexOfTransfer]
            if filename != nil { transferInfos["filename"] = filename! }
            if peerId != nil { transferInfos["peerId"] = peerId! }
            if isOutgoing != nil { transferInfos["isOutgoing"] = isOutgoing }
            if percentage != nil { transferInfos["percentage"] = percentage }
            if state != nil { transferInfos["state"] = state! }
            transfersArray.remove(at: indexOfTransfer)
            transfersArray.insert(transferInfos, at: indexOfTransfer)
        }
        DispatchQueue.main.async {
           self.fileTransferTableView.reloadData()
        }
    }
    
    
    func startFileTransfer(userId: String?, url fileURL: URL?, type transferType: SKYLINKAssetType) {
        if userId != nil && fileURL != nil {
            do {
                let triggerFileTransfer: () throws -> Void = { [weak weakSelf = self] in
                    weakSelf?.skylinkConnection.sendFileTransfer(withFileURL: fileURL!, assetType: transferType, fileName: nil, remotePeerId: userId, callback: nil)
                }
                try triggerFileTransfer()
            } catch {
                skylinkLog(error.localizedDescription)
            }
        } else if fileURL != nil {
            // No peer ID provided means transfer to every peer in the room
            skylinkConnection.sendFileTransfer(withFileURL: fileURL, assetType: transferType, fileName: nil, remotePeerId: nil) { (error) in
                
            }
        } else {
            let alert = UIAlertController(title: "No file URL", message: "\nError: there is no file URL. Try another media.", preferredStyle: .alert)
            alerts.append(alert)
            showAlert()
        }
    }
    
    func showTransferFormForRecipient(peerID: String?) {
        var message: String
        peerID != nil ? (message = "\nYou are about to send a tranfer request to user with ID \n\(peerID!)\nWhat do you want to send ?") : (message = "\nYou are about to send a tranfer request all users\nWhat do you want to send ?")
        
        let alertPopUp = UIAlertController(title:"Send a file.",message: message, preferredStyle: .alert)
        let cancelAction=UIAlertAction(title: "Cancel", style: .cancel)
        alertPopUp.addAction(cancelAction)
        let pVAction = UIAlertAction(title: "Photo / Video (pick from library)", style: .default) { [weak weakSelf = self] _ in
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
                let pickerController: UIImagePickerController = UIImagePickerController()
                pickerController.sourceType = UIImagePickerController.SourceType.photoLibrary
                pickerController.delegate = weakSelf
                pickerController.mediaTypes = [String(kUTTypeImage), String(kUTTypeMovie)]
                weakSelf?.present(pickerController, animated: true, completion: nil)
            }
        }
        alertPopUp.addAction(pVAction)
        let musicAction = UIAlertAction(title: "Music (pick from library)", style: .default) { [weak weakSelf = self] _ in
            let pickerController = MPMediaPickerController()
            pickerController.delegate = weakSelf
            weakSelf?.present(pickerController, animated: true, completion: nil)
        }
        alertPopUp.addAction(musicAction)
        
        //Music
        let fileAction = UIAlertAction(title: "File (prepared image)", style: .default){ [weak weakSelf = self] _ in
            var peerId: String?
            if weakSelf!.selectedRow != -1 && weakSelf!.selectedRow < weakSelf!.remotePeerArray.count {
                peerId = weakSelf?.remotePeerArray[weakSelf!.selectedRow] ?? ""
            }
            let imageStr = (peerId != nil) ? "sampleImage_transfer" : "sampleImage_groupTransfer"
            if let filePath = Bundle.main.path(forResource: imageStr, ofType: "png") {
                weakSelf?.startFileTransfer(userId: peerId, url: URL(string: filePath), type: SKYLINKAssetTypeFile)
            } else {
                weakSelf?.startFileTransfer(userId: nil, url: nil, type: SKYLINKAssetTypeFile)
            }
        }
        alertPopUp.addAction(fileAction)
        present(alertPopUp, animated: true, completion: nil)
    }
    
    func mediaPickerDidCancel(mediaPicker: MPMediaPickerController){
        // Dismiss the picker if the user canceled
        dismiss(animated: true, completion: nil)
    }
    
    func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if error != nil {
            skylinkLog("\(#function) • Error while saving '\(contextInfo)'->\(error!.localizedDescription)")
            skylinkLog("\(#function) • Now trying to save image in the Documents Directory")
            let pathArray = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            let filePath = (pathArray.first! as NSString).appendingPathComponent(String(describing: contextInfo))
            do {
                let b = try removeFileAtPath(filePath: filePath)
                if FileManager.default.fileExists(atPath: filePath) && !b { return }
            } catch {
                skylinkLog(error)
                return
            }
            var wError: Error?
            do {
                try image.pngData()?.write(to: URL(fileURLWithPath: filePath), options: .atomicWrite)
            } catch let exception {
                wError = exception as Error
                skylinkLog("Write to file exception => \(exception)")
            }
            if wError != nil {
                skylinkLog("\(#function) • Error while writing '\(filePath)'->\(wError!.localizedDescription)")
            }
        } else {
            skylinkLog("\(#function) • Image saved successfully")
        }
    }
    
    fileprivate func removeFileAtPath(filePath: String) throws -> Bool {
        var succeed = false
        var error: Error?
        do {
            try FileManager.default.removeItem(at: URL(string: filePath)!)
        } catch let exception {
            error = exception as Error
            skylinkLog("Write to file exception => \(exception)")
        }
        if error != nil {
            skylinkLog("\(#function) • Error while removing '\(filePath)'->\(error!.localizedDescription)")
        } else {
            succeed = true
        }
        return succeed
    }
    
    fileprivate func isImage(exten: String) -> Bool {
        return ["jpg", "jpeg", "jpe", "jif", "jfif", "jfi", "jp2", "j2k", "jpf", "jpx", "jpm", "tiff", "tif", "pict", "pct", "pic", "gif", "png", "qtif", "icns", "bmp", "bmpf", "ico", "cur", "xbm"].contains(exten.lowercased())
    }
    
    fileprivate func isMovie(exten: String) -> Bool {
        return ["mpg", "mpeg", "m1v", "mpv", "3gp", "3gpp", "sdv", "3g2", "3gp2", "m4v", "mp4", "mov", "qt"].contains(exten.lowercased())
    }
    
    
    // MARK: - IBActions
    
    @IBAction func sendToAllTap(sender: AnyObject) {
        selectedRow = -1
        if !remotePeerArray.isEmpty {
            showTransferFormForRecipient(peerID: nil)
        } else{
            let alert = UIAlertController(title: "No peer connected", message: "Wait for someone to connect before sending files.", preferredStyle: .alert)
            alerts.append(alert)
            showAlert()
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
    return input.rawValue
}
