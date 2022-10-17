//
//  ImagePicker.swift
//  baseball_ai_analyst
//
//  Created by Admin on 2022/9/15.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import AVFoundation
import UIKit
open class VideoPicker: NSObject {

    public var RPM: String?
    private let pickerController: UIImagePickerController
    private weak var presentationController: UIViewController?

    public init(presentationController: UIViewController) {
        self.pickerController = UIImagePickerController()

        super.init()

        self.presentationController = presentationController

        self.pickerController.delegate = self
        self.pickerController.mediaTypes = ["public.movie"]
        self.pickerController.videoQuality = .typeHigh
        self.pickerController.videoExportPreset = AVAssetExportPresetPassthrough
        
    }
    
    public func selectVideo(from sourceView: UIView) {
        self.pickerController.sourceType = .photoLibrary
        self.presentationController?.present(self.pickerController, animated: true)
    }

    private func didSelectVideo(_ controller: UIImagePickerController, didSelect url: URL?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    struct bodyData: Codable {
        let video: String
        let content: String
    }
    
    struct rpmData: Codable {
        let RPM: Int
    }
    
    //can use
    func jsonPost(videoPath: URL?) {
        if videoPath == nil {
            print("videoPath is nil")
            return
        }
        let url = URL(string: "http://36.235.155.187:8000 /upload")
        var request = URLRequest(
            url: url!,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let fileName = videoPath!.lastPathComponent
        var movieData: Data?
        do {
            movieData = try Data(contentsOf: videoPath!,options:  Data.ReadingOptions.alwaysMapped)
        } catch _ {
            movieData = nil
            return
        }
        
        /*let body:[String: AnyHashable] = [
            "video" : fileName,
            "content" : movieData?.base64EncodedString(options: NSData.Base64EncodingOptions.init(rawValue: 0))
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: .fragmentsAllowed)*/
        let encoder = JSONEncoder()
        let body = bodyData(video: fileName, content: (movieData?.base64EncodedString(options: NSData.Base64EncodingOptions.init(rawValue: 0)))!)
        //print(movieData?.base64EncodedString(options: NSData.Base64EncodingOptions.init(rawValue: 0)).count)
        let data = try? encoder.encode(body)
        request.httpBody = data
        let task = URLSession.shared.dataTask(with: request) { (data, response,error) in
            if let data = data {
                //let html = String(data: data, encoding: .utf8)
                let decoder = JSONDecoder()
                do {
                    let meme = try decoder.decode(rpmData.self, from: data)
                    print(meme)
                    self.RPM = String(meme.RPM)
                } catch {
                    print(error)
                }
                
                //print(html!)
                //self.RPM = meme.RPM
            }
        }
        task.resume()
    }
    
    // error
    func testPostv2(videoPath: URL?) {
        if videoPath == nil {
            print("videoPath is nil")
            return
        }
        print("post2")
        let semaphore = DispatchSemaphore (value: 0)

        let parameters = [
          [
            "key": "file",
            "src": videoPath as Any,
            "type": "file"
          ]] as [[String : Any]]

        let boundary = "Boundary-\(UUID().uuidString)"
        var body = ""
        //var error: Error? = nil
        for param in parameters {
          if param["disabled"] == nil {
            let paramName = param["key"]!
            body += "--\(boundary)\r\n"
            body += "Content-Disposition:form-data; name=\"\(paramName)\""
            if param["contentType"] != nil {
              body += "\r\nContent-Type: \(param["contentType"] as! String)"
            }
            let paramType = param["type"] as! String
            if paramType == "text" {
              let paramValue = param["value"] as! String
              body += "\r\n\r\n\(paramValue)\r\n"
            } else {
              let paramSrc = param["src"] as! URL
                
                var fileData: NSData
                do {
                    fileData = try NSData(contentsOfFile: paramSrc.absoluteString,options: [])
                } catch _ {
                    //fileData = nil
                    print("FileData is nil")
                    return
                }
                //let fileData = try NSData(contentsOfFile:paramSrc, options:[]) as Data
                
                let fileContent = String(data: fileData as Data, encoding: .utf8)!
              body += "; filename=\"\(paramSrc)\"\r\n"
                + "Content-Type: \"content-type header\"\r\n\r\n\(fileContent)\r\n"
            }
          }
        }
        body += "--\(boundary)--\r\n";
        let postData = body.data(using: .utf8)
        print("testPostv2")
        var request = URLRequest(url: URL(string: "http://114.41.134.141:8000/upload")!,timeoutInterval: Double.infinity)
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = postData
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
          guard let data = data else {
            print(String(describing: error))
            semaphore.signal()
            return
          }
          print(String(data: data, encoding: .utf8)!)
          semaphore.signal()
        }

        task.resume()
        semaphore.wait()
        
    }
}
extension VideoPicker: UIImagePickerControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.didSelectVideo(picker, didSelect: nil)
    }

    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {

        guard let url = info[.mediaURL] as? URL else {
            return self.didSelectVideo(picker, didSelect: nil)
        }
        self.didSelectVideo(picker, didSelect: url)
        print("video path: \(url)")
        // uploadMedia(videoPath: url)
        jsonPost(videoPath: url)
    }
}

extension VideoPicker: UINavigationControllerDelegate {

}
