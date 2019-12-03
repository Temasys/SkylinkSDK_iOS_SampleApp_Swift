//
//  InsideFilesViewController.swift
//  SampleApp_Swift
//
//  Created by Temasys on 15/4/19.
//  Copyright © 2019 Temasys. All rights reserved.
//

import UIKit

class InsideFilesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var webView: UIWebView! {
        didSet {
            webView.autoresizingMask = UIView.AutoresizingMask.flexibleWidth
            webView.autoresizingMask = UIView.AutoresizingMask.flexibleHeight
            webView.scalesPageToFit = true
            webView.isMultipleTouchEnabled = true
            webView.isUserInteractionEnabled = true
            webView.stringByEvaluatingJavaScript(from: "var meta = document.createElement('meta');meta.content='width=device-width,initial-scale=1.0,minimum-scale=.5,maximum-scale=3';meta.name='viewport';document.getElementsByTagName('head')[0].appendChild(meta);")
        }
    }
    @IBOutlet weak var openBtn: UIButton!
    @IBOutlet weak var closeBtn: UIButton!
    weak var tableView: UITableView!
    lazy var files = [String]()
    lazy var selectedFile = ""
    var backClosure: (() -> Void)!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        copyItems()
    }
    
    fileprivate func setupUI() {
        view.backgroundColor = .groupTableViewBackground
        openBtn.setTitleColor(.blue, for: .normal)
        closeBtn.setTitleColor(.blue, for: .normal)
        let tableView = UITableView(frame: CGRect(x: 10, y: 80, width: view.frame.size.width * 0.5, height: view.frame.size.height * 0.5), style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isHidden = true
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)
        self.tableView = tableView
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "mycell")
    }
    
    fileprivate func copyItems() {
        if let excelPath = Bundle.main.path(forResource: "Excel", ofType: "xlsx") {
            do {
                if !FileManager.default.fileExists(atPath: appFilesFolder + "/" + "Excel.xlsx") {
                    try FileManager.default.copyItem(atPath: excelPath, toPath: appFilesFolder + "/" + "Excel.xlsx")
                }
            } catch {
                skylinkLog(error.localizedDescription)
            }
        }
        if let keynotePath = Bundle.main.path(forResource: "Keynote", ofType: "key") {
            do {
                if !FileManager.default.fileExists(atPath: appFilesFolder + "/" + "Keynote.key") {
                    try FileManager.default.copyItem(atPath: keynotePath, toPath: appFilesFolder + "/" + "Keynote.key")
                }
            } catch {
                skylinkLog(error.localizedDescription)
            }
        }
        if let imagePath = Bundle.main.path(forResource: "Image", ofType: "png") {
            do {
                if !FileManager.default.fileExists(atPath: appFilesFolder + "/" + "Image.png") {
                    try FileManager.default.copyItem(atPath: imagePath, toPath: appFilesFolder + "/" + "Image.png")
                }
            } catch {
                skylinkLog(error.localizedDescription)
            }
        }
        if let numbersPath = Bundle.main.path(forResource: "Numbers", ofType: "numbers") {
            do {
                if !FileManager.default.fileExists(atPath: appFilesFolder + "/" + "Numbers.numbers") {
                    try FileManager.default.copyItem(atPath: numbersPath, toPath: appFilesFolder + "/" + "Numbers.numbers")
                }
            } catch {
                skylinkLog(error.localizedDescription)
            }
        }
        if let pagesPath = Bundle.main.path(forResource: "Pages", ofType: "pages") {
            do {
                if !FileManager.default.fileExists(atPath: appFilesFolder + "/" + "Pages.pages") {
                    try FileManager.default.copyItem(atPath: pagesPath, toPath: appFilesFolder + "/" + "Pages.pages")
                }
            } catch {
                skylinkLog(error.localizedDescription)
            }
        }
        if let pdfPath = Bundle.main.path(forResource: "PDF", ofType: "pdf") {
            do {
                if !FileManager.default.fileExists(atPath: appFilesFolder + "/" + "PDF.pdf") {
                    try FileManager.default.copyItem(atPath: pdfPath, toPath: appFilesFolder + "/" + "PDF.pdf")
                }
            } catch {
                skylinkLog(error.localizedDescription)
            }
        }
        if let plainTextPath = Bundle.main.path(forResource: "PlainText", ofType: "txt") {
            do {
                if !FileManager.default.fileExists(atPath: appFilesFolder + "/" + "PlainText.txt") {
                    try FileManager.default.copyItem(atPath: plainTextPath, toPath: appFilesFolder + "/" + "PlainText.txt")
                }
            } catch {
                skylinkLog(error.localizedDescription)
            }
        }
        if let pptPath = Bundle.main.path(forResource: "PPT", ofType: "pptx") {
            do {
                if !FileManager.default.fileExists(atPath: appFilesFolder + "/" + "PPT.pptx") {
                    try FileManager.default.copyItem(atPath: pptPath, toPath: appFilesFolder + "/" + "PPT.pptx")
                }
            } catch {
                skylinkLog(error.localizedDescription)
            }
        }
        if let wordPath = Bundle.main.path(forResource: "Word", ofType: "docx") {
            do {
                if !FileManager.default.fileExists(atPath: appFilesFolder + "/" + "Word.docx") {
                    try FileManager.default.copyItem(atPath: wordPath, toPath: appFilesFolder + "/" + "Word.docx")
                }
            } catch {
                skylinkLog(error.localizedDescription)
            }
        }
    }

    @IBAction func close() {
        view.removeFromSuperview()
        removeFromParent()
        backClosure()
    }
    
    @IBAction func open() {
        do {
            files = try FileManager.default.subpathsOfDirectory(atPath: appFilesFolder)
            tableView.isHidden = false
            tableView.reloadData()
        } catch {
            skylinkLog(error.localizedDescription)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mycell", for: indexPath)
        cell.textLabel?.text = files[indexPath.row]
        cell.backgroundColor = .lightGray
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedFile = files[indexPath.row]
        loadWebView()
        tableView.isHidden = true
    }
    
    fileprivate func loadWebView() {
        let fileUrl = URL(fileURLWithPath: appFilesFolder + "/" + selectedFile)
        do {
            let data = try Data(contentsOf: fileUrl)
            webView.load(data, mimeType: checkFileMimeType(fileName: selectedFile), textEncodingName: "UTF-8", baseURL: fileUrl)
        } catch {
            skylinkLog(error.localizedDescription)
        }
    }
    
    fileprivate func checkFileMimeType(fileName: String) -> String {
        let arr = fileName.split(separator: ".")
        let ext = arr[1]
        var result = ""
        if ext == "docx" {
            result = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        } else if ext == "doc" {
            result = "application/msword"
        } else if ext == "pdf" {
            result = "application/pdf"
        } else if ext == "txt" {
            result = "text/plain"
        } else if ext == "html" {
            result = "text/html"
        } else if ext == "css" {
            result = "text/css"
        } else if ext == "gif" {
            result = "image/gif"
        } else if ext == "png" {
            result = "image/png"
        } else if ext == "jpg" || ext == "jpeg" {
            result = "image/jpeg"
        } else if ext == "bmp" {
            result = "image/bmp"
        } else if ext == "midi" {
            result = "audio/midi"
        } else if ext == "mp3" {
            result = "audio/mpeg"
        } else if ext == "ogg" {
            result = "audio/ogg"
        } else if ext == "wav" {
            result = "audio/wav"
        } else if ext == "mp4" {
            result = "video/mp4"
        } else if ext == "xml" {
            result = "application/xml"
        } else if ext == "json" {
            result = "application/json"
        } else if ext == "xls" {
            result = "application/vnd.ms-excel"
        } else if ext == "xlsx" {
            result = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        } else if ext == "ppt" {
            result = "application/vnd.ms-powerpoint"
        } else if ext == "pptx" {
            result = "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        } else {
            result = "application/octet-stream"
        }
        return result
    }
    
    
    
    
}
