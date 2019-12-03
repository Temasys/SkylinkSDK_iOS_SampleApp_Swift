//
//  StatsView.swift
//  SampleApp_Swift
//
//  Created by  Temasys on 6/3/18.
//  Copyright © 2018 Temasys. All rights reserved.
//

import UIKit

enum Status {
    case input
    case sent
    case received
    case all
}

struct Stats {
    var inputWidth: String
    var inputHeight: String
    var inputFPS: String
    var sentWidth: String
    var sentHeight: String
    var sentFPS: String
    var receivedWidth: String
    var receivedHeight: String
    var receivedFPS: String
    
    init(dict: [String : Any]) {
        inputWidth = "\(dict["FrameWidthInput"] ?? "480")"
        inputHeight = "\(dict["FrameHeightInput"] ?? "640")"
        inputFPS = "\(dict["FrameRateInput"] ?? "30 ")"
        sentWidth = "\(dict["FrameWidthSent"] ?? "0")"
        sentHeight = "\(dict["FrameHeightSent"] ?? "0")"
        sentFPS = "\(dict["FrameRateSent"] ?? "0")"
        receivedWidth = "\(dict["FrameWidthReceived"] ?? "0")"
        receivedHeight = "\(dict["FrameHeightReceived"] ?? "0")"
        receivedFPS = "\(dict["FrameRateReceived"] ?? "0")"
    }
}

class StatsView: UIView {

    @IBOutlet weak var inputWidthLabel: UILabel!
    @IBOutlet weak var inputHeightLabel: UILabel!
    @IBOutlet weak var inputFPSLabel: UILabel!
    @IBOutlet weak var sentWidthLabel: UILabel!
    @IBOutlet weak var sentHeightLabel: UILabel!
    @IBOutlet weak var sentFPSLabel: UILabel!
    @IBOutlet weak var receivedWidthLabel: UILabel!
    @IBOutlet weak var receivedHeightLabel: UILabel!
    @IBOutlet weak var receivedFPSLabel: UILabel!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupView(stats: Stats, status: Status) {
        DispatchQueue.main.async {
            if status == .input {
                self.inputWidthLabel.text = stats.inputWidth
                self.inputHeightLabel.text = stats.inputHeight
                self.inputFPSLabel.text = stats.inputFPS
            }
            if status == .sent {
                self.sentWidthLabel.text = stats.sentWidth
                self.sentHeightLabel.text = stats.sentHeight
                self.sentFPSLabel.text = stats.sentFPS
            }
            if status == .received {
                self.receivedWidthLabel.text = stats.receivedWidth
                self.receivedHeightLabel.text = stats.receivedHeight
                self.receivedFPSLabel.text = stats.receivedFPS
            }
            if status == .all {
                self.inputWidthLabel.text = stats.inputWidth
                self.inputHeightLabel.text = stats.inputHeight
                self.inputFPSLabel.text = stats.inputFPS
                self.sentWidthLabel.text = stats.sentWidth
                self.sentHeightLabel.text = stats.sentHeight
                self.sentFPSLabel.text = stats.sentFPS
                self.receivedWidthLabel.text = stats.receivedWidth
                self.receivedHeightLabel.text = stats.receivedHeight
                self.receivedFPSLabel.text = stats.receivedFPS
            }
        }
    }
}
