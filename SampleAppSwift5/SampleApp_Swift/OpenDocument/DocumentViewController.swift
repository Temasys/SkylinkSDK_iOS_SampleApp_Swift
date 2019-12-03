//
//  DocumentViewController.swift
//  SampleApp_Swift
//
//  Created by  Temasys on 16/4/19.
//  Copyright © 2019 Temasys. All rights reserved.
//

import UIKit

class DocumentViewController: UIViewController {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var pictureView: UIImageView!
    @IBOutlet weak var saveFileButton: UIButton!
    var document: Document?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Access the document
        document?.open(completionHandler: { (success) in
            if success {
                // Display the content of the document, e.g.:
                self.nameLabel.text = self.document?.fileURL.lastPathComponent
                if self.document?.fileType == "public.png" || self.document?.fileType == "public.jpg" {
                    self.pictureView.image = UIImage(data: (self.document?.fileData)!)
                    self.saveFileButton.isEnabled = false
                } else if self.document?.fileType == "public.plain-text" {
                    self.textView.text = self.document?.filesText!
                    self.saveFileButton.isEnabled = true
                } else if self.document?.fileType == "public.text" {
                    self.textView.text = self.document?.filesText!
                    self.saveFileButton.isEnabled = true
                } else if self.document?.fileType == "public.rtf" {
                    self.textView.text = self.document?.filesText!
                    self.saveFileButton.isEnabled = true
                } else if self.document?.fileType == "com.adobe.pdf" {
                    self.textView.text = self.document?.filesText ?? ""
                    self.saveFileButton.isEnabled = true
                } else if self.document?.fileType == "com.microsoft.word.doc" {
                    self.textView.text = self.document?.filesText ?? ""
                    self.saveFileButton.isEnabled = true
                } else if self.document?.fileType == "com.microsoft.excel.xls" {
                    self.textView.text = self.document?.filesText ?? ""
                    self.saveFileButton.isEnabled = true
                } else if self.document?.fileType == "com.microsoft.powerpoint.ppt" {
                    self.textView.text = self.document?.filesText ?? ""
                    self.saveFileButton.isEnabled = true
                } else if self.document?.fileType == "com.microsoft.word.wordml" {
                    self.textView.text = self.document?.filesText ?? ""
                    self.saveFileButton.isEnabled = true
                } else if self.document?.fileType == "com.apple.keynote.key" {
                    self.textView.text = self.document?.filesText ?? ""
                    self.saveFileButton.isEnabled = true
                } else if self.document?.fileType == "com.apple.iWork.Keynote.key" {
                    self.textView.text = self.document?.filesText ?? ""
                    self.saveFileButton.isEnabled = true
                } else if self.document?.fileType == "com.apple.keynote.kth" {
                    self.textView.text = self.document?.filesText ?? ""
                    self.saveFileButton.isEnabled = true
                }
                print("Document state: \((self.document?.state)!)")
            } else {
                // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
            }
        })
    }
    
    
    @IBAction func save() {
        document?.filesText = textView.text
        print("Save to: \(String(describing: document?.fileURL.path))!")
        document?.save(to: (document?.fileURL)!, for: .forOverwriting, completionHandler: { (success) in
            if success {
                print("File created OK")
                self.dismissDocumentViewController()
            } else {
                print("Failed to save file.")
                self.textView.backgroundColor = UIColor.red
                let docState = self.document?.state
                self.textView.text = "Failed to save file. Document state: " + docState!
            }
        })
    }
    
    @IBAction func dismissDocumentViewController() {
        view.removeFromSuperview()
        removeFromParent()
        self.document?.close(completionHandler: nil)
    }
}
