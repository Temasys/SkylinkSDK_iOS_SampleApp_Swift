//
//  UIAspectFitButton.swift
//  SampleApp
//
//  Created by Yuxi on 27/7/17.
//  Copyright © 2017 Yuxi. All rights reserved.
//

import UIKit

class UIAspectFitButton: UIButton {

    override func layoutSubviews() {
        super.layoutSubviews()
        _ = subviews.map {
            if $0.isKind(of: UIImageView.self) {
                $0.contentMode = .scaleAspectFit
            }
        }
    }
}
