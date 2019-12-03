//
//  WrapViewController.swift
//  SampleApp_Swift
//
//  Created by  Temasys on 17/4/19.
//  Copyright © 2019 Temasys. All rights reserved.
//

import UIKit

class WrapViewController: UIViewController {
    
    @IBOutlet weak var closeBtn: UIButton!
    var backClosure: (() -> Void)!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeBtn.setTitleColor(.blue, for: .normal)

        if #available(iOS 11.0, *) {
            let browserVc =  DocumentBrowserViewController()
            browserVc.view.frame = CGRect(x: 0, y: 50, width: view.frame.width, height: view.frame.height - 50)
            view.addSubview(browserVc.view)
            addChild(browserVc)
        } else {
            // Fallback on earlier versions
        }
        
    }

    @IBAction func close() {
        view.removeFromSuperview()
        removeFromParent()
        backClosure()
    }
    
    
}
