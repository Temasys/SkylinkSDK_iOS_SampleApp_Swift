//
//  Date+Ext.swift
//  SampleApp_Swift
//
//  Created by Charlie on 10/2/20.
//  Copyright © 2020 Temasys. All rights reserved.
//

import Foundation

extension Date{
    static func skylinkDate(from string: String?) -> Date?{
        return dateFrom(string: string, format: "yyyy-MM-dd'T'HH:mm:ss.0'Z'")
    }
    static func skylinkString(from date: Date?) -> String?{
        return Date.strinFrom(date: date, format: "yyyy-MM-dd'T'HH:mm:ss.0'Z'")
    }
    
    
    static private func dateFrom(string: String?, format: String?) -> Date?{
        guard let string = string else {return nil}
        guard let format = format else {return nil}
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = format
        return dateFormatter.date(from: string)
    }
    static private func strinFrom(date: Date?, format: String?) -> String?{
        guard let date = date else {return nil}
        guard let format = format else {return nil}
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
    func toTimeStamp() -> Int64! {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
    static func datefrom(timeStamp: Int64?) -> Date?{
        guard let timeStamp = timeStamp else {return nil}
        return Date(timeIntervalSince1970: TimeInterval(timeStamp / 1000))
    }
}

