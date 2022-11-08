//
//  ViewController.swift
//  baseball_ai_analyst
//
//  Created by Admin on 2022/9/11.
//

import UIKit
import AVFoundation
import CoreImage
import AVKit
class ViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    var  rpm: String?
    public var frame: CGImage?
    private let context = CIContext()
    private var bufferView:UIImageView = UIImageView()
    public var tmpOutputURL: URL?
    
    var player = AVPlayer()
    var playerViewController = AVPlayerViewController()
    var RPMlabel = UILabel()
    @IBOutlet weak var txtFieldIso: UITextField!
    
    @IBOutlet weak var txtFieldShutterSpeed: UITextField!
    // 640h 345w
    @IBOutlet weak var viewCameraPreview : UIView!
    
    //@IBOutlet weak var bufferPreview: UIView!
    @IBOutlet weak var onlyrecord: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    //@IBOutlet weak var recordButtonBorder: UIButton!
    //record on off
    var record_state:Bool = false
    
    let session = AVCaptureSession()
    let deviceInput = DeviceInput()
    var bestFormat: AVCaptureDevice.Format?
    var maxRate: AVFrameRateRange?
    //videoPicker
    var videoPicker: VideoPicker!
    
    var screenRect: CGRect! = nil // screen size
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // circle record button
        //recordButtonBorder.layer.cornerRadius = 100
        //recordButtonBorder.layer.borderWidth = 10
        //recordButtonBorder.layer.borderColor = UIColor.white.cgColor
        /*recordButton.frame.size = CGSize(width: 15.0, height: 15.0)
        recordButton.setImage(UIImage(named: "record_state_off"), for: .normal)
        recordButton.setImage(UIImage(named: "record_state_on"), for: .selected)*/
        //recordButton.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        // 按空白處使鍵盤消失
        txtFieldIso.delegate = self
        txtFieldShutterSpeed.delegate = self
        // cemara
        settingPreviewLayer()
        session.addInput(deviceInput.microphone!)
        //session.addInput(deviceInput.backTelephotoCamera!) // long focal
        session.addInput(deviceInput.backWildAngleCamera!)
        
        //session.sessionPreset = .hd1280x720
        session.beginConfiguration()
        //session.sessionPreset = AVCaptureSession.Preset.medium
        session.commitConfiguration()
        session.addOutput(AVCaptureMovieFileOutput()) // output file
        //let videoOutput = AVCaptureVideoDataOutput()
        //videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        //session.addOutput(videoOutput) // get frame
        //videoOutput.connection(with: .video)?.videoOrientation = .landscapeLeft
        session.startRunning()
        settingFPS()
        
        
        //videoPicker
        self.videoPicker = VideoPicker(presentationController: self)
        //draw rect on screen
        view.layer.addSublayer(rectLayer())
    }
    //Set the shouldAutorotate to False
    override open var shouldAutorotate: Bool {
       return false
    }

    // Specify the orientation.
    //override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    //   return .landscapeLeft
    //}
    
    //videoPicker
    
    @IBAction func showImagePicker(_ sender: UIButton) {
        self.videoPicker.selectVideo(from: sender)
        
    }
    
    
    func settingPreviewLayer() {
        let previewLayer = AVCaptureVideoPreviewLayer()
        //full screen
        screenRect = UIScreen.main.bounds
        previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        //previewLayer.frame = viewCameraPreview.bounds
        
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
        viewCameraPreview.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        //viewCameraPreview.transform = CGAffineTransform(rotationAngle: .pi / 2)
        viewCameraPreview.layer.addSublayer(previewLayer)
        //move  view to  back
        //viewCameraPreview.sendSubviewToBack(onlyrecord)
        self.view.sendSubviewToBack(viewCameraPreview)
        
        bufferView.contentMode = UIView.ContentMode.scaleAspectFit
        //bufferPreview.addSubview(bufferView)
        
    }
    
    // seting ligth,focal,iso,shutter speed,
    func cameraSetting(setIso:Float, setShutterSpeed:Int32) {
        let input = session.inputs.last as! AVCaptureDeviceInput
        if input.device.deviceType == .builtInMicrophone {
            return
        }
        
        do {
            let camera = input.device
            
            try camera.lockForConfiguration()   //
            
            if camera.isExposureModeSupported(.continuousAutoExposure) {
                camera.exposurePointOfInterest = CGPoint(x: 0.5, y: 0.5)
                camera.exposureMode = .autoExpose
            }
            
            if camera.isFocusModeSupported(.continuousAutoFocus) {
                camera.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
                camera.focusMode = .autoFocus // change to autofocus
            }
            // shutter speed and iso
            camera.setExposureModeCustom(
                duration: CMTime(value: 1, timescale: setShutterSpeed),
                iso: setIso,
                completionHandler: nil
            )
            camera.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    // set FPS to lens device max
    func settingFPS() {
        session.beginConfiguration()
        //session.sessionPreset = .hd1280x720
        //session.sessionPreset = AVCaptureSession.Preset.medium
        let input = session.inputs.last as! AVCaptureDeviceInput
        if input.device.deviceType == .builtInMicrophone {
            return
        }
        
        let camera = input.device
        //----------------------------------------------//fps
        for format in camera.formats {
            // 1080p setting
            guard format.formatDescription.dimensions.width == 1920 else { continue }
            guard format.formatDescription.dimensions.height == 1080 else { continue }
            
            
            for range in format.videoSupportedFrameRateRanges {
                if maxRate?.maxFrameRate ?? 0 < range.maxFrameRate {
                    maxRate = range
                    bestFormat = format
                }
            }
        }
        if let bestFormat = bestFormat, let maxRange = maxRate {
            do {
                try camera.lockForConfiguration()
                camera.activeFormat = bestFormat
                // print format setting
                print(camera.activeFormat)
                print(camera.activeFormat.formatDescription)
                
                let duration = maxRange.minFrameDuration
                camera.activeVideoMaxFrameDuration = duration
                camera.activeVideoMinFrameDuration = duration
                camera.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
        //----------------------------------------------//fps
        //test set 1080p here
        //session.sessionPreset = .hd1920x1080
        session.commitConfiguration()
    }
    
    @IBAction func settingIso(_ sender: UITextField) {
        let valIso = Float(txtFieldIso.text!) ?? 300.0
        let valShutterSpeed = Int32(txtFieldShutterSpeed.text!) ?? 3000
        cameraSetting(setIso:valIso, setShutterSpeed:valShutterSpeed)
    }
    
    @IBAction func settingShutterSpeed(_ sender: UITextField) {
        let valIso = Float(txtFieldIso.text!) ?? 300.0
        let valShutterSpeed = Int32(txtFieldShutterSpeed.text!) ?? 3000
        cameraSetting(setIso:valIso, setShutterSpeed:valShutterSpeed)
    }
    
    //recordButton.addTarget(self, action: #selector(butttonAction), for: .touchUpInside)
    /*@IBAction func recording(_ sender: UIButton) {
        if(sender.isSelected){
            recordButton.isSelected = false
            let url = URL(fileURLWithPath: NSTemporaryDirectory() + "output.mov")
            let output = session.outputs.first! as! AVCaptureMovieFileOutput
            output.startRecording(to: url, recordingDelegate: self)
            
        }else{
            recordButton.isSelected = true
            let output = session.outputs.first! as! AVCaptureMovieFileOutput
            output.stopRecording()
        }
    }*/
    
   /* @IBAction func pickVideo(_ sender: UIButton) {
        self.videoPicker.selectVideo(from: sender)
        
    }*/
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(outputFileURL.path) {
            UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, self, #selector(completion(_:error:contextInfo:)), nil)
        }
        self.tmpOutputURL = outputFileURL
        print("file ouput url: \(outputFileURL.absoluteString)")
        videoPicker.jsonPost(videoPath: outputFileURL) // auto upload video
        playVideo(videoPath: outputFileURL, rpm: videoPicker.RPM)
    }
    
    @objc func completion(_ videoPath: String, error:Error?, contextInfo: Any?){
        do{
            //print("file ouput url2: \(videoPath)")
            
            //let fm = FileManager.default
            //try fm.removeItem(atPath: videoPath)
        } catch {
            print(error)
        }
        //===============================================//
        // Alert Message
        let alertController = UIAlertController(
            title: "提醒您",
            message:"錄影結束",
            preferredStyle: .alert
        )
        let actionOK = UIAlertAction(
            title: "確定",
            style: .default,
            handler: nil
        )
        alertController.addAction(actionOK)
        show(alertController, sender: self) //show the alert message on screen
        //===============================================//
    }
   
    @IBAction func toServerResult(_ sender: UIButton) {
        performSegue(withIdentifier: "toServerResult", sender: self)
        
    }
    
    // Button start recording
    @IBAction func recordButton(_ sender: Any) {
        // Date Time in Taipei
        let date: Date = Date()
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss" // 20221106225255
        dateFormatter.locale = Locale(identifier: "zh_Hant_TW") //set location
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Taipei") //set timezone
        let dateFormateString: String = dateFormatter.string(from: date)
        //====================================================================//
        let fileName:String = "output_" + dateFormateString + ".mov"
        let url = URL(fileURLWithPath: NSTemporaryDirectory() + fileName) // stote in tmp
        let output = session.outputs.first! as! AVCaptureMovieFileOutput
        //2.5s auto stop record
        output.maxRecordedDuration = CMTimeMakeWithSeconds(2.5, preferredTimescale: 240)
        output.connection(with: .video)?.videoOrientation = .landscapeRight //video spin
        output.startRecording(to: url, recordingDelegate: self)
        let seconds = 2.7 // time delay
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            // Put your code which should be executed with a delay here
            if output.isRecording {
                output.stopRecording()
                print("still recording stop by asyn")
            } else {
                print("not recording stop by maxRecordedDuration")
            }
        }
    }
    
    // Botton stop recording
    @IBAction func stopRecordButton(_ sender: Any) {
        let output = session.outputs.first! as! AVCaptureMovieFileOutput
        output.stopRecording()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender:Any?) {
    let resultVC = segue.destination as! SecondViewController
        resultVC.rpm = self.videoPicker.RPM
        resultVC.runtime = self.videoPicker.runtime
        
    }
    
    // set lens focal point
    func focalSetting(touchX:CGFloat, touchY:CGFloat) {
        let input = session.inputs.last as! AVCaptureDeviceInput
        if input.device.deviceType == .builtInMicrophone {
            return
        }
        
        do {
            let camera = input.device
            
            try camera.lockForConfiguration()
            //焦距
            if camera.isFocusModeSupported(.continuousAutoFocus) {
                camera.focusPointOfInterest = CGPoint(x: touchX, y: touchY)
                camera.focusMode = .autoFocus
            }
            
            if camera.isExposureModeSupported(.continuousAutoExposure) {
                camera.exposurePointOfInterest = CGPoint(x: touchX, y: touchY)
                camera.exposureMode = .autoExpose
            }

            camera.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    // Button replay video
    @IBAction func replayVideo(_ sender: UIButton) {
        playVideo(videoPath: self.videoPicker.VIDEOURL, rpm: self.videoPicker.RPM)
    }

    // replay and show label
    func playVideo(videoPath: URL? , rpm: String?){
        if videoPath == nil {
            print("videoPath is nil")
            return
        }
        //let loadIndicatorView: UIActivityIndicatorView (
            
        //)
        
        RPMlabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        let unwrappedRPM = rpm ?? "none"
        RPMlabel.text = "RPM \(unwrappedRPM)"
        RPMlabel.textColor = UIColor.white
        RPMlabel.frame = CGRect(x: 20, y:200, width: RPMlabel.frame.size.width, height: RPMlabel.frame.size.height)
        RPMlabel.sizeToFit()
        player = AVPlayer(url: videoPath!)
        playerViewController.player = player
        playerViewController.contentOverlayView!.addSubview(RPMlabel)
        //playerViewController.contentOverlayView!.addSubview(loadIndicatorView)
        self.present(playerViewController, animated: true)
        {
        //  //auto play the video
        //  player.play()
            
        }
    }    // error
    
    // create a rect layer
    func rectLayer() -> CAShapeLayer {
        let shapeLayer = CAShapeLayer()
        shapeLayer.name = "rectfocal"
        shapeLayer.frame = CGRect(x: 130, y: 130, width: 50, height: 50)
        shapeLayer.strokeColor = UIColor.red.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.path = UIBezierPath(
            rect: CGRect(x: 0, y: 0, width: 50, height: 50)
        ).cgPath
        return shapeLayer
    }
}
    
/*
extension ViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(outputFileURL.path){
            UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, self, #selector(completion(_:error:contextInfo:)),nil )}    }
    
    @objc func completion(_ videoPath: String, error:Error?, contextInfo: Any?){
        do{
            let fm = FileManager.default
            try fm.removeItem(atPath: videoPath)
        } catch {
            print(error)
        }
    }
}*/
/*extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let cgImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        DispatchQueue.main.async { [unowned self] in
            self.frame = cgImage // 把每一個frame給ViewController的public frame參數裡
            // https://youtu.be/cLnw5z8ZGqM 參考影片
            // 要測看看app可不可以用，frame的照片
            print("new frame")
        }
        let bufferFrame = UIImage(cgImage: cgImage)
        bufferView.image = bufferFrame
        print("call")
    }
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CGImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        
        return cgImage
    }
}*/
extension ViewController: UITextFieldDelegate {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: self.view)
        //let location = touches.first?.location(in: view)
        let touchX = location.x / self.view.frame.width
        let touchY = location.y / self.view.frame.height 
        if  (0.3<touchY && touchY<0.65){
            if let sublayers = view.layer.sublayers {
                for layer in sublayers {
                    //print("i\(String(describing: layer.name))")
                    if layer.name == "rectfocal" {
                        layer.position = location
                    }
                }
            }
            focalSetting(touchX: touchX, touchY: touchY) // set focal 0-1
        
        }
        print("began\(location)")
        self.view.endEditing(true)
    }
    
}
