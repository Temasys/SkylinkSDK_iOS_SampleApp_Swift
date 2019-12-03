//
//  DocumentActivity.swift
//  Test4
//
//  Created by  Temasys on 18/4/19.
//  Copyright © 2019 Temasys. All rights reserved.
//

import UIKit

class DocumentActivity: UIActivity {
    
    var document: Document!

    init(document: Document) {
        self.document = document
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    override func perform() {
        document.open { (success) in
            if success {
                self.activityDidFinish(true)
            }
        }
    }
}
