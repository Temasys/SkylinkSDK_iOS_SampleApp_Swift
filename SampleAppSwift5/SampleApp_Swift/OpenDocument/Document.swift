//
//  Document.swift
//  SampleApp_Swift
//
//  Created by  Temasys on 16/4/19.
//  Copyright © 2019 Temasys. All rights reserved.
//

import UIKit

class Document: UIDocument {
    
    var state: String {
        switch documentState {
        case .normal: return "Normal"
        case .closed: return "Closed"
        case .inConflict: return "Conflict"
        case .savingError: return "Save Error"
        case .editingDisabled: return "Editing Disabled"
        case .progressAvailable: return "Progress Available"
        default: return "Unknown"
        }
    }
    
    var fileData: Data?
    var filesText: String?
    
    override func contents(forType typeName: String) throws -> Any {
        // Encode your document with an instance of NSData or NSFileWrapper
        if typeName == "public.plain-text" {
            if let content = filesText {
                let data = content.data(using: .utf8)
                return data!
            } else {
                return Data()
            }
        } else if typeName == "public.plain-text" {
            if let content = filesText {
                let data = content.data(using: .utf8)
                return data!
            } else {
                return Data()
            }
        } else if typeName == "public.text" {
            if let content = filesText {
                let data = content.data(using: .utf8)
                return data!
            } else {
                return Data()
            }
        } else if typeName == "public.rtf" {
            if let content = filesText {
                let data = content.data(using: .utf8)
                return data!
            } else {
                return Data()
            }
        } else if typeName == "com.adobe.pdf" {
            if let content = filesText {
                let data = content.data(using: .utf8)
                return data!
            } else {
                return Data()
            }
        } else if typeName == "com.microsoft.word.doc" {
            if let content = filesText {
                let data = content.data(using: .utf8)
                return data!
            } else {
                return Data()
            }
        } else if typeName == "com.microsoft.excel.xls" {
            if let content = filesText {
                let data = content.data(using: .utf8)
                return data!
            } else {
                return Data()
            }
        } else if typeName == "com.microsoft.powerpoint.ppt" {
            if let content = filesText {
                let data = content.data(using: .utf8)
                return data!
            } else {
                return Data()
            }
        } else if typeName == "com.microsoft.word.wordml" {
            if let content = filesText {
                let data = content.data(using: .utf8)
                return data!
            } else {
                return Data()
            }
        } else if typeName == "com.apple.keynote.key" {
            if let content = filesText {
                let data = content.data(using: .utf8)
                return data!
            } else {
                return Data()
            }
        } else if typeName == "com.apple.iWork.Keynote.key" {
            if let content = filesText {
                let data = content.data(using: .utf8)
                return data!
            } else {
                return Data()
            }
        } else if typeName == "com.apple.keynote.kth" {
            if let content = filesText {
                let data = content.data(using: .utf8)
                return data!
            } else {
                return Data()
            }
        }
        return Data()
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // Load your document from contents
        if let fileType = typeName {
            if fileType == "public.png" || fileType == "public.jpg" {
                if let fileContents = contents as? Data {
                    fileData = fileContents
                }
            } else if fileType == "public.plain-text" {
                if let fileContents = contents as? Data {
                    filesText = String(data: fileContents, encoding: .utf8)
                }
            } else if fileType == "public.text" {
                if let fileContents = contents as? Data {
                    filesText = String(data: fileContents, encoding: .utf8)
                }
            } else if fileType == "public.rtf" {
                if let fileContents = contents as? Data {
                    filesText = String(data: fileContents, encoding: .utf8)
                }
            } else if fileType == "com.adobe.pdf" {
                if let fileContents = contents as? Data {
                    filesText = String(data: fileContents, encoding: .utf8)
                }
            } else if fileType == "com.microsoft.word.doc" {
                if let fileContents = contents as? Data {
                    filesText = String(data: fileContents, encoding: .utf8)
                }
            } else if fileType == "com.microsoft.excel.xls" {
                if let fileContents = contents as? Data {
                    filesText = String(data: fileContents, encoding: .utf8)
                }
            } else if fileType == "com.microsoft.powerpoint.ppt" {
                if let fileContents = contents as? Data {
                    filesText = String(data: fileContents, encoding: .utf8)
                }
            } else if fileType == "com.microsoft.word.wordml" {
                if let fileContents = contents as? Data {
                    filesText = String(data: fileContents, encoding: .utf8)
                }
            } else if fileType == "com.apple.keynote.key" {
                if let fileContents = contents as? Data {
                    filesText = String(data: fileContents, encoding: .utf8)
                }
            } else if fileType == "com.apple.iWork.Keynote.key" {
                if let fileContents = contents as? Data {
                    filesText = String(data: fileContents, encoding: .utf8)
                }
            } else if fileType == "com.apple.keynote.kth" {
                if let fileContents = contents as? Data {
                    filesText = String(data: fileContents, encoding: .utf8)
                }
            } else {
                print("File type unsupported.")
            }
        }
    }
}
