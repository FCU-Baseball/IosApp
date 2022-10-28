//
//  FileHandler.swift
//  baseball_ai_analyst
//
//  Created by Admin on 2022/10/26.
//

import Foundation
import UIKit

class FileHandler: NSObject {
    let fm = FileManager.default
    let home = NSHomeDirectory()
    
    override init() {
        super.init()
        guard let url = fm.urls(for: .documentDirectory,in: .userDomainMask).first else {
            return
        }
        print(url.path)
    }
    
    func saveFile(base64String: String) {
        let stringData = Data(base64Encoded: base64String)
        let fileName = "sample1"
        let documentDirectoryUrl = try! FileManager.default.url(
            for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )
        let fileUrl = documentDirectoryUrl.appendingPathComponent(fileName).appendingPathExtension("mov")
        // prints the file path
        print("File path save \(fileUrl.path)")
        // data to write in file.
        do {
            try stringData?.write(to: fileUrl)
            
        } catch let error as NSError {
            print(error)
        }
    }
    
    private func documentDirectory() -> String {
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                                    .userDomainMask,
                                                                    true)
        return documentDirectory[0]
    }
    
    private func append(toPath path: String, withPathComponent pathComponent: String) -> String? {
        if var pathURL = URL(string: path) {
            pathURL.appendPathComponent(pathComponent)
            return pathURL.absoluteString
        }
        return nil
    }
}
