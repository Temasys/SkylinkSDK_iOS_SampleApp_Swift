//
//  HomeViewController.swift
//  SampleApp
//
//  Created by  Temasys on 26/7/17.
//  Copyright © 2017  Temasys. All rights reserved.
//

import UIKit

//
// ====== SET YOUR SKYLINK API KEY & SECRET HERE ======
//
let SKYLINK_APP_KEY = APP_KEY
let SKYLINK_SECRET = APP_SECRET

// Enroll at developer.temasys.com.sg if needed


class HomeViewController: UIViewController, UITextFieldDelegate, TFRateBarViewDelegate {
    
//    @IBOutlet weak var secretTextField: UITextField!
//    @IBOutlet weak var keyTextField: UITextField!
    
    let USERDEFAULTS_KEY_SKYLINK_APP_KEY = "SKYLINK_APP_KEY"
    let USERDEFAULTS_KEY_SKYLINK_SECRET = "SKYLINK_SECRET"

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupOthers()
    }
    
    func setupUI() {
//        keyTextField.text = SKYLINK_APP_KEY
//        secretTextField.text = SKYLINK_SECRET
    }
    
    func setupOthers() {
        if !SKYLINK_APP_KEY.isEmpty && !SKYLINK_SECRET.isEmpty, let defaultKey = UserDefaults.standard.object(forKey: USERDEFAULTS_KEY_SKYLINK_APP_KEY) as? String, let defaultSecret = UserDefaults.standard.object(forKey: USERDEFAULTS_KEY_SKYLINK_SECRET) as? String {
//            keyTextField.text = defaultKey
//            secretTextField.text = defaultSecret
        }
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        let shouldPerform = true// (keyTextField.text?.count == 36 && secretTextField.text?.count == 13)
        if !shouldPerform {
            let msgTitle = "Wrong Key / Secret"
            let msg = "\nYou haven't correctly set your \nSkylink API Key (36 characters) or Secret (13 characters)\n\nIf you don't have access to the API yet, enroll at \ndeveloper.temasys.com.sg/register"
            let alertController = UIAlertController(title: msgTitle , message: msg, preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default)
            alertController.addAction(OKAction)
            present(alertController, animated: true, completion: nil)
        } else {
//            UserDefaults.standard.set(keyTextField.text, forKey: USERDEFAULTS_KEY_SKYLINK_APP_KEY)
//            UserDefaults.standard.set(secretTextField.text, forKey: USERDEFAULTS_KEY_SKYLINK_SECRET)
            UserDefaults.standard.synchronize()
        }
        return shouldPerform
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination.responds(to: Selector(("setSkylinkApiKey:"))) && segue.destination.responds(to: Selector(("setSkylinkApiSecret:"))) {
//            segue.destination.perform(Selector(("setSkylinkApiKey:")), with: keyTextField.text)
//            segue.destination.perform(Selector(("setSkylinkApiSecret:")), with: secretTextField.text)
        }
        if #available(iOS 10.0, *) {
            if segue.identifier == "home2videocall", let videocallVc = segue.destination as? VideoCallViewController {
                videocallVc.backClosure = {
                    if !UserDefaults.standard.bool(forKey: "DONT_SHOW_ANYMORE") {
                        let alertController = UIAlertController(title: "Please rate our service\n\n\n\n", message: nil, preferredStyle: .alert)
                        let container = UIView(frame: CGRect(x: 10, y: 50, width: 230, height: 60))
                        let starView = TFRateBarView(frame: CGRect(x: 0, y: 10, width: 230, height: 60))
                        starView.delegate = self
                        starView.maxRateValue = 4
                        starView.starBackgroundColor = .lightGray
                        starView.starTintColor = .yellow
                        container.addSubview(starView)
                        alertController.view.addSubview(container)
                        let hateAction = UIAlertAction(title: "Don't show this anymore", style: .destructive, handler: { _ in
                            UserDefaults.standard.set(true, forKey: "DONT_SHOW_ANYMORE")
                        })
                        let okAction = UIAlertAction(title: "OK", style: .default)
                        alertController.addAction(hateAction)
                        alertController.addAction(okAction)
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    func alertMessage(_ msg_title: String, msg: String) {
        let alertController = UIAlertController(title: msg_title , message: msg, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(OKAction)
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func homeInfoTap() {
        let msgTitle = "HomeViewController"
        let msg = "\nSet you Skylink API Key and secret in the appropriate text field or modify HomeViewController's code to have it by default.\nIf you don't have your Key/Secret, enroll at developer.temasys.com.sg/register\n\nIn all view controllers, you can tap the info button in the upper right corner to get the current room name, your current local ID, the current API key and the current SDK version. Refer to the documentation for more infos on how to use it.\n"
        alertMessage(msgTitle, msg: msg)
    }
    
    @IBAction func videoCallVCinfoTap() {
        let msgTitle = "VideoCallViewController"
        let msg = "\nOne to one video call sample\n\nThe first 2 people to enter the room will be able to have a video call. The bottom bar contains buttons to refresh the peer connexion, mute/unmute the camera, mute/unmute the mic and switch the device camera if available.\n\nRefer to the view controller's code and to the documentation for more infos.\n"
        alertMessage(msgTitle, msg: msg)
    }
    
    @IBAction func multiVideoCallVCinfoTap() {
        let msgTitle = "MultiViewController"
        let msg = "\nThe first 4 people to enter the room will be able to have a multi party video call (as long as the room isn't locked). The bottom bar contains buttons to change the aspect of the peer video views, lock/unlock the room, mute/unmute the camera, mute/unmute the mic and switch the device camera if available.\n\nRefer to the view controller's code and to the documentation for more infos.\n"
        alertMessage(msgTitle, msg: msg)
    }
    
    @IBAction func audioCallVCinfoTap() {
        let msgTitle = "AudioCallViewController"
        let msg = "\nEnter the room to make an audio call with the other peers inside the same room. Tap the button on top to mute/unmute your microphone.\n\nRefer to the view controller's code and to the documentation for more infos.\n"
        alertMessage(msgTitle, msg: msg)
    }
    
    @IBAction func messagesVCinfoTap() {
        let msgTitle = "MessagesViewController"
        let msg = "\nEnter the room to chat with the peers in the same room. The first text field allows you to edit your nickname, the yellow button indicates the number of peers in the room: tap it to display theirs ID and nickname if available, tap the icon to hide the keyboard if needed. There is also a button to select the type of messages you want to test (P2P, signeling server or binary data), and another one to choose if you want to send your messages to all the peers in the room (public) or privatly. If not public, you will be ask what peer you want to send your private message to when tapping the send button. To send a message, enter it in the second text field and tap the send button. The messages you sent appear in green.\n\nRefer to the view controller's code and to the documentation for more infos.\n"
        alertMessage(msgTitle, msg: msg)
    }

    @IBAction func fileTransferVCinfoTap() {
        let msgTitle = "FileTransferViewController"
        let msg = "\nEnter the room to send file to the ppers in the same room. To send a file to all the peers, tap the main button, to send it to a particular peer, tap the peer in the list. In both cases you will be asked the king of media you want to send and to pick it if needed.\nBehaviour will be slightly different with MCU enabled.\n\nRefer to the view controller's code and to the documentation for more infos.\n"
        alertMessage(msgTitle, msg: msg)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        keyTextField.resignFirstResponder()
//        secretTextField.resignFirstResponder()
        return true
    }
    @IBAction func clicked() {
        
//        let vc = BroadcastSetupViewController()
//        present(vc, animated: true, completion: nil)
    }
    
    func didSelectedRateBarView(_ rateBarView: TFRateBarView, atIndex index: Int) {
        rateBarView.rate = index
    }
}
