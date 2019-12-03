//
//  UIView+Ext.swift
//  SampleApp_Swift
//
//  Created by Charlie on 25/7/19.
//  Copyright © 2019 Temasys. All rights reserved.
//

import UIKit

extension UIView{
    func removeSubviews(){
        self.subviews.forEach { $0.removeFromSuperview() }
    }
    func aspectFitRectForSize(insideSize: CGSize?, inContainer container: UIView?){
        guard let container = container, let insideSize = insideSize, insideSize.width != 0, insideSize.height != 0 else{return}
        let originRate = insideSize.width/insideSize.height
        let containerRate = container.frame.width/container.frame.height
        var resultFrame = CGRect(x: 0, y: 0, width: 0, height: 0)
        if originRate > containerRate{
            resultFrame.size.width = container.frame.width
            resultFrame.size.height = container.frame.width/originRate
        }else{
            resultFrame.size.height = container.frame.height
            resultFrame.size.width = container.frame.height*originRate
        }
        resultFrame.origin.x = container.frame.width/2 - resultFrame.size.width/2
        resultFrame.origin.y = container.frame.height/2 - resultFrame.size.height/2
        self.frame = resultFrame
    }
    func aspectFillRectForSize(insideSize: CGSize?, inContainer container: UIView?){
        guard let container = container, let insideSize = insideSize else{return}
        var maxFloat: CGFloat = 0
        if container.frame.size.height > container.frame.size.width {
            maxFloat = container.frame.size.height
        } else if container.frame.size.height < container.frame.size.width {
            maxFloat = container.frame.size.width
        } else {
            maxFloat = 0
        }
        var aspectRatio: CGFloat = 0
        if insideSize.height != 0 {
            aspectRatio = insideSize.width / insideSize.height
        } else {
            aspectRatio = 1
        }
        var frame = CGRect(x: 0, y: 0, width: container.frame.size.width, height: container.frame.size.height)
        if insideSize.width < insideSize.height {
            frame.size.width = maxFloat
            frame.size.height = frame.size.width / aspectRatio
        } else {
            frame.size.height = maxFloat;
            frame.size.width = frame.size.height * aspectRatio
        }
        frame.origin.x = (container.frame.size.width - frame.size.width) / 2
        frame.origin.y = (container.frame.size.height - frame.size.height) / 2
        self.frame = frame
    }
    
}
