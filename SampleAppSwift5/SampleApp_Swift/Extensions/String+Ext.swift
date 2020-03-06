//
//  String+Ext.swift
//  SampleApp_Swift
//
//  Created by Charlie on 24/2/20.
//  Copyright © 2020 Temasys. All rights reserved.
//

import Foundation
extension String{
    func convertToDictionary() -> [String: Any]? {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}
