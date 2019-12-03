//
//  SAPeerObject.swift
//  SampleApp_Swift
//
//  Created by Charlie on 8/8/19.
//  Copyright © 2019 Temasys. All rights reserved.
//

import Foundation

class SAPeerObject {
    var peerId: String?
    var userName: String?
    var videoView: UIView?
    var videoSize: CGSize?
    var medias: [SKYLINKMedia]
    init(peerId: String?, userName: String?, videoView: UIView?, videoSize: CGSize?){
        self.peerId = peerId
        self.userName = userName
        self.videoView = videoView
        self.videoSize = videoSize
        medias = []
    }
}
