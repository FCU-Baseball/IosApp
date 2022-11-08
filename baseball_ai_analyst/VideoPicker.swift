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
import AVKit
open class VideoPicker: NSObject {

    public var RPM: String = "None"
    public var runtime: Float = 0.0
    public var VIDEOURL: URL?
    private let pickerController: UIImagePickerController
    private weak var presentationController: UIViewController?
    var player = AVPlayer()
    var playerViewController = AVPlayerViewController()
    
    var label = UILabel()
    var fileHandler = FileHandler()
    public init(presentationController: UIViewController) {
        self.pickerController = UIImagePickerController()

        super.init()

        self.presentationController = presentationController

        self.pickerController.delegate = self
        self.pickerController.mediaTypes = ["public.movie"]
        self.pickerController.videoQuality = .typeHigh
        self.pickerController.videoExportPreset = AVAssetExportPresetPassthrough
        
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.text = "RPM/n1234"
        label.textColor = UIColor.white
        label.frame = CGRect(x: 20, y:200, width: label.frame.size.width, height: label.frame.size.height)
        label.sizeToFit()
        
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
    
    struct videoData: Codable {
        let video_data: String
    }
    
    //can use
    func jsonPost(videoPath: URL?) {
        let startTime = CFAbsoluteTimeGetCurrent()
        if videoPath == nil {
            print("videoPath is nil")
            return
        }
        let url = URL(string: "http:/111.252.120.253:8000/spinrate")
        var request = URLRequest(
            url: url!,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        //================================================================//
        // fileName : output_20221106225255
        let fileName = videoPath!.lastPathComponent
        
        // get the video bin data
        var movieData: Data?
        do {
            movieData = try Data(contentsOf: videoPath!,options:  Data.ReadingOptions.alwaysMapped)
        } catch _ {
            movieData = nil
            return
        }
        //================================================================//
        // jason data post to server
        let encoder = JSONEncoder()
        let body = bodyData(video: fileName, content: (movieData?.base64EncodedString(options: NSData.Base64EncodingOptions.init(rawValue: 0)))!)
        //print(movieData?.base64EncodedString(options: NSData.Base64EncodingOptions.init(rawValue: 0)).count)
        let data = try? encoder.encode(body)
        request.httpBody = data
        
        // remove tmp mov file
        /*do{
            let fm = FileManager.default
            try fm.removeItem(atPath: videoPath!.path)
            print("file tmp remove: \(videoPath!.absoluteString)")
        } catch {
            print(error)
        }*/
        //================================================================//
        // use urlsession task to post data
        let task = URLSession.shared.dataTask(with: request) { (data, response,error) in
            if let data = data {
                //let html = String(data: data, encoding: .utf8)
                let decoder = JSONDecoder()
                print("return get")
                do {
                    let meme = try decoder.decode(rpmData.self, from: data)
                    //print("meme\(meme)")
                    self.RPM = String(meme.RPM)
                    print("have return\(meme.RPM)")
                    /*
                    print("base64 len\(meme.video_data.count)")
                    self.fileHandler.saveFile(base64String: meme.video_data)
                    */
                    // calculate runtime
                    let endTime = CFAbsoluteTimeGetCurrent()
                    print("程式碼執行時長1：\(endTime - startTime)")
                    self.runtime = Float(endTime - startTime)
                } catch {
                    print(error)
                }
                
                //print(html!)
                //self.RPM = meme.RPM
            }
        }
        task.resume()
        let endTime = CFAbsoluteTimeGetCurrent()
        print("程式碼執行時長2：\(endTime - startTime)")
        self.runtime = Float(endTime - startTime)
    }

    /*func test(){
        let upload = URLSession.shared.uploadTask(with: POST, from: <#T##Data#>)
    }*/
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
        self.VIDEOURL = url
        print("video path: \(url)")
        // uploadMedia(videoPath: url)
        jsonPost(videoPath: url)
    }
}

extension VideoPicker: UINavigationControllerDelegate {

}
