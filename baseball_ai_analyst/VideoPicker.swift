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
//import Combine
open class VideoPicker: NSObject {

    //@Published var RPM: String = "None"
    var RPM: String = "None"
    public var runtime: Float = 0.0
    public var VIDEOURL: URL?
    public var ServerURL: String = ""
    private let pickerController: UIImagePickerController
    private weak var presentationController: UIViewController?

    
    var fileHandler = FileHandler()
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
        let url = URL(string:"http://114.41.133.218:8000/spinrate")
        //let url = URL(string: "http:/114.41.138.58:8000/ballspeed")
        //let url = URL(string: self.ServerURL)
        print("videopicker \(self.ServerURL)")
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
        let sem = DispatchSemaphore.init(value: 0)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response,error) in
            defer { sem.signal() }
            print("server response \(String(describing: response))")
            /*if let error = error {
                print("Error -> \(error)")
                return
            }*/
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
                    print("get error")
                    print(error)
                }
                
                //print(html!)
                //self.RPM = meme.RPM
            }
            
            
        }
        task.resume()
        
        // This line will wait until the semaphore has been signaled
        // which will be once the data task has completed
        sem.wait()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        print("程式碼執行時長2：\(endTime - startTime)")
        self.runtime = Float(endTime - startTime)
    }
    
    func jsonPost_completion(videoPath: URL?, completion: @escaping () -> ()) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        if videoPath == nil {
            print("videoPath is nil")
            return
        }
        print("aadsadad",videoPath?.path)
        //let url = URL(string: "http:/114.41.141.253:8000/spinrate")
        let url = URL(string: self.ServerURL)
        print("videopicker\(self.ServerURL)")
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
        let sem = DispatchSemaphore.init(value: 0)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response,error) in
            //defer { sem.signal() }
            print("server response \(String(describing: response))")
            /*if let error = error {
                print("Error -> \(error)")
                return
            }*/
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
                    print("get error")
                    print(error)
                }
                
                //print(html!)
                //self.RPM = meme.RPM
            }
            completion()
        }
        task.resume()
        
        // This line will wait until the semaphore has been signaled
        // which will be once the data task has completed
        //sem.wait()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        print("程式碼執行時長2：\(endTime - startTime)")
        self.runtime = Float(endTime - startTime)
    }
    
    func stream(file : URL?, completion: @escaping() -> ()){
        let startTime = CFAbsoluteTimeGetCurrent()
        let serverUrl = URL(string:"http://114.41.138.43:8000/upload")
        var request = URLRequest(url: serverUrl!)
        request.httpMethod = "POST"
        //request.setValue(file!.lastPathComponent, forHTTPHeaderField: "filename")
        request.setValue("video/quicktime", forHTTPHeaderField: "Content-Type")
        
        //let sessionConfig = URLSessionConfiguration.background(withIdentifier: "it.example.upload")
        //sessionConfig.isDiscretionary = false
        //sessionConfig.networkServiceType = .video
        //let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: OperationQueue.main)
        
        let task = URLSession.shared.uploadTask(with: request, fromFile: file!){ (data, response,error) in
   
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
                    print("get error")
                    print(error)
                }
            }
            completion()
        }
        
        task.resume()
    }

    func test(file: URL?, completion: @escaping()->()){
        var semaphore = DispatchSemaphore (value: 0)
        print("form data: \(file!.path)")
        let parameters = [
          [
            "key": "file",
            "src": file!.path,
            "type": "file"
          ]] as [[String : Any]]

        let boundary = "Boundary-\(UUID().uuidString)"
        var body = ""
        var error: Error? = nil
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
              //let paramSrc = param["src"] as! String
                let paramSrc = "outputTest.mov"
                var fileData: Data = Data()
                do {
                    fileData = try NSData(contentsOf:file!, options:[]) as Data
                } catch {
                    print("catch err")
                    print(error)
                }
                print("fileData len: \(fileData.count)")
              /*var fileData: Data?
              do {
                  fileData = try Data(contentsOf: file!, options:  Data.ReadingOptions.alwaysMapped)
              } catch _ {
                fileData = nil
                print("form data: fileData is nil")
                print(error)
                return
              }*/
              //let fileContent = String(data: fileData, encoding: .utf8)
              let fileContent = String(decoding: fileData, as: UTF8.self)
              body += "; filename=\"\(paramSrc)\"\r\n"
                + "Content-Type: \"content-type header\"\r\n\r\n\(fileContent)\r\n"
            }
          }
        }
        body += "--\(boundary)--\r\n";
        let postData = body.data(using: .utf8)

        var request = URLRequest(url: URL(string: self.ServerURL)!,timeoutInterval: Double.infinity)
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
          completion()
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
        self.VIDEOURL = url
        print("video path: \(url)")
        // uploadMedia(videoPath: url)
        //jsonPost(videoPath: url)
        //stream(file:  url)
    }
}

extension VideoPicker: UINavigationControllerDelegate {

}

extension VideoPicker: URLSessionDelegate, URLSessionTaskDelegate,
                       URLSessionDataDelegate {
    
}
