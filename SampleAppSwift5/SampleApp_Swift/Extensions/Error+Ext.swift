//
//  Error+Ext.swift
//  SampleApp_Swift
//
//  Created by Charlie on 7/11/19.
//  Copyright © 2019 Temasys. All rights reserved.
//

import Foundation
extension Error {
    var code: Int { return (self as NSError).code }
    var domain: String { return (self as NSError).domain }
}
