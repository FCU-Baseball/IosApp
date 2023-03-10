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
import Combine
import Photos
import PhotosUI

class ViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    ///未使用變數 待確認
    @IBOutlet weak var txtFieldIso: UITextField!
    @IBOutlet weak var ModeSwitch: UISwitch!
    @IBOutlet weak var IPInput: UIButton!
    @IBOutlet weak var txtFieldShutterSpeed: UITextField!
    public var frame: CGImage?
    private let context = CIContext()
    private var bufferView:UIImageView = UIImageView()
    var subscriber = Set<AnyCancellable>()
    //@IBOutlet weak var recordButton: UIButton!
    ///

    //錄影 鏡頭 變數
    @IBOutlet weak var viewCameraPreview : UIView!
    let session = AVCaptureSession()
    let deviceInput = DeviceInput()
    var bestFormat: AVCaptureDevice.Format?
    var maxRate: AVFrameRateRange?
    public var tmpOutputURL: URL?

    //模式 變數
    var selectedPredMode:Bool = true  //true球速 false轉速
    var screenCtrlMode: Int = 1       //0 關/1 對焦/2 pixeltometer校正

    //主畫面上的按鈕
    @IBOutlet weak var onlyrecord: UIButton!
    @IBOutlet weak var inputServerIP: UIButton!
    @IBOutlet weak var segCtrlScreen: UISegmentedControl!
    @IBOutlet weak var segCtrlPred: UISegmentedControl!
    @IBOutlet weak var download: UIButton!
    @IBOutlet weak var btn_sendParameter: UIButton!

    //轉圈
    let activaty = UIActivityIndicatorView(style: .large)

    //videoPicker
    var videoPicker: VideoPicker!
    var screenRect: CGRect! = nil // screen size
    var  rpm: String?
    var serverIP: String = "none"

    //回放影片函式 變數
    var player = AVPlayer()
    var playerViewController = AVPlayerViewController()
    var RPMlabel = UILabel()

    // pixeltometer校正函式 變數
    var focusPosition: CGPoint? = CGPoint(x: 300, y: 300)
    var firstTouch: Bool = true
    var fLocation: CGPoint? = CGPoint(x: (0.0), y: (0.0))
    var sLocation: CGPoint? = CGPoint(x: (0.0), y: (0.0))
    var personHeight: Float = 0.0
    var dis_result: Float = 0.0
    @IBOutlet weak var pixelLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        activaty.center = view.center
        // Do any additional setup after loading the view.
           
        // cemara setting
        settingPreviewLayer()
        //session.addInput(deviceInput.backTelephotoCamera!) // long focal
        session.addInput(deviceInput.backWildAngleCamera!)
        session.addOutput(AVCaptureMovieFileOutput()) // output file
        session.startRunning()
        settingFPS()
        cameraSetting(setIso: 0.0, setShutterSpeed: 0)
        
        //videoPicker
        self.videoPicker = VideoPicker(presentationController: self)

        //draw rect on screen
        view.layer.addSublayer(rectLayer())

        // 主畫面按鈕旋轉
        rotateView()
        pixelLabel.isHidden = true
        btn_sendParameter.isHidden = true

        //錄影鍵
        onlyrecord.setImage(UIImage(named: "record_btn_img"), for: .normal)
        onlyrecord.frame.size = CGSize(width: 55.0, height: 55.0)
        onlyrecord.setTitle("", for: .normal)
        
        RPMlabel.frame = CGRectMake(10,10,150, 70)
        //hint() 
    }

    //Set the shouldAutorotate to False
    override open var shouldAutorotate: Bool {
       return false
    }
    // Specify the orientation.
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
       return .portrait
    }

    ///旋轉主畫面按鈕
    func rotateView(){
        download.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        segCtrlPred.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        segCtrlScreen.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        inputServerIP.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        pixelLabel.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        btn_sendParameter.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
    }    
        
    func settingPreviewLayer() {
        let previewLayer = AVCaptureVideoPreviewLayer()
        //full screen
        screenRect = UIScreen.main.bounds
        previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
        viewCameraPreview.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        viewCameraPreview.layer.addSublayer(previewLayer)
        //move  view to  back
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
            try camera.lockForConfiguration()   
            
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
                duration: CMTime(value: 1, timescale: 3000),
                iso: 500,
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

        let input = session.inputs.last as! AVCaptureDeviceInput
        if input.device.deviceType == .builtInMicrophone {
            return
        }
        
        let camera = input.device
        //==================================================//
        // FPS setting
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
        //=======================================================//
        session.commitConfiguration()
    }
   
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(outputFileURL.path) {
            UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, self, #selector(completion(_:error:contextInfo:)), nil)
        }
        self.tmpOutputURL = outputFileURL
    }
    
    @objc func completion(_ videoPath: String, error:Error?, contextInfo: Any?){
        do{

        } catch {
            print(error)
        }
        //===============================================//
        // Alert Message
        print("Alert start")
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

    ///切換球速或轉速模式
    @IBAction func predModeClicked(_ sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        
        
        if index == 1 {
            //===============camera change===================//
            /*session.beginConfiguration()
            session.removeInput(session.inputs.last!)
            session.addInput(deviceInput.backWildAngleCamera!)
            session.commitConfiguration()*/
            //===============================================//
            self.selectedPredMode = true
            videoPicker.ServerURL = "http://" + serverIP + ":8000/ballspeed"
            print(videoPicker.ServerURL)
        } else{
            //http://36.235.131.131:8000/
            //===============camera change===================//
            /*session.beginConfiguration()
            session.removeInput(session.inputs.last!)
            session.addInput(deviceInput.backTelephotoCamera!)
            // long focal
            session.commitConfiguration()*/
            //=================================================//
            self.selectedPredMode = false
            videoPicker.ServerURL = "http://" + serverIP + ":8000/spinrate"
            print(videoPicker.ServerURL)
        }
        
    }

    /// 切換 關/對焦/pixeltometer校正
    @IBAction func screenModeClicked(_ sender: UISegmentedControl) {
        
        if let sublayers = view.layer.sublayers {
            for layer in sublayers {
                if layer.name == "rectfocal" {
                    layer.removeFromSuperlayer()
                }
                if layer.name == "straightLine"{
                    layer.removeFromSuperlayer()
                }
                    
            }
        }
        pixelLabel.isHidden = true
        btn_sendParameter.isHidden = true

        let index = sender.selectedSegmentIndex
        switch index {
        case 0:
            screenCtrlMode = 0
            view.layer.addSublayer(rectLayer())
            break
        case 1:
            screenCtrlMode = 1
            view.layer.addSublayer(rectLayer())
            
            break
        case 2:
            screenCtrlMode = 2
            pixelLabel.isHidden = false
            btn_sendParameter.isHidden = false
            let alertController = UIAlertController(title:"輸入身高(m):",message: nil,preferredStyle: .alert)
            let actionOK = UIAlertAction(title: "OK", style: .default){
                action in
                self.personHeight = Float(alertController.textFields![0].text!) ?? 0.0
                print(self.personHeight)
            }
            alertController.addTextField(configurationHandler: nil)
            alertController.addAction(actionOK)
            show(alertController, sender: self)
            break
        default:
            break
        }
    }

    /// 傳送校正參數到Server
    @IBAction func sendParameter(_ sender: UIButton) {
        videoPicker.jsonPost_parameter(height: personHeight, length: dis_result){
            print("send end")
        }
    }
   
    /// Button start recording
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
        let startTime = CFAbsoluteTimeGetCurrent()
        let seconds = 3.0 // time delay

        
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            // Put your code which should be executed with a delay here
            if output.isRecording {
                output.stopRecording()
                print("still recording stop by asyn")
            } else {
                print("not recording stop by maxRecordedDuration")
            }
            
            self.activaty.startAnimating()
            self.view.addSubview(self.activaty)
            self.videoPicker.gzipstream(file: self.tmpOutputURL){  //auto uplaod video
                DispatchQueue.main.async {
                    self.activaty.stopAnimating()
                    self.activaty.removeFromSuperview()
                    let endTime = CFAbsoluteTimeGetCurrent()
                    print("程式碼執行時間：\(endTime - startTime)")
                    self.playVideo(videoPath: self.tmpOutputURL, serverResult:self.videoPicker.RPM)
                    
                }

                //let endTime = CFAbsoluteTimeGetCurrent()
                //print("：\(endTime - startTime)")
            }
        }
        
    }
         
    /// 重播慢動作影片和顯示預測結果
    func playVideo(videoPath: URL? , serverResult: String?){
        if videoPath == nil {
            print("videoPath is nil")
            return
        }

        let unwrapped = serverResult ?? "none"
        let lab_spinrate = "SPINRATE        \(unwrapped) RPM"
        let lab_ballspeed = "BALLSPEED             \(unwrapped) KPH"
        
        if (selectedPredMode == false){
            RPMlabel.text = lab_ballspeed
        }else{
            RPMlabel.text = lab_spinrate
        }
        RPMlabel.textColor = UIColor.green
        RPMlabel.backgroundColor = UIColor(red:0,green: 0,blue:0,alpha: 0.6)
        RPMlabel.layer.cornerRadius = 10
        RPMlabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        RPMlabel.numberOfLines = 0
        RPMlabel.textAlignment = NSTextAlignment.center
        RPMlabel.font = UIFont(name: "Trebuchet MS", size: 20)
        
        RPMlabel.frame = CGRectMake(self.view.frame.height*0.7,self.view.frame.width*0.8,150, 70)
        let playerItem = AVPlayerItem(url: videoPath!)
        playerItem.audioTimePitchAlgorithm = .varispeed
        player = AVPlayer(playerItem: playerItem)
        player.rate = 0.125
        playerViewController.player = player
        
        playerViewController.contentOverlayView!.addSubview(RPMlabel)
        
        self.present(playerViewController, animated: true)
        {
        //  //auto play the video
        //  player.play()
        }
    }    
    
    /// 輸入ServerIP
    @IBAction func ServerInput(_ sender: Any){
        let alertController = UIAlertController(title:"Input IP:",message: nil,preferredStyle: .alert)
        let actionOK = UIAlertAction(title: "OK", style: .default){
            action in
            let textIP = alertController.textFields![0].text
            self.videoPicker.ServerURL = "http://" + textIP! + ":8000/ballspeed"
            self.videoPicker.parameterURL = "http://" + textIP! + ":8000/parameter"
            self.serverIP = textIP!
            print(self.serverIP)
        }
        alertController.addTextField(configurationHandler: nil)
        alertController.addAction(actionOK)
        show(alertController, sender: self)
    }

    /// create a rect layer
    func rectLayer() -> CAShapeLayer {
        let shapeLayer = CAShapeLayer()
        shapeLayer.name = "rectfocal"
        shapeLayer.frame = CGRect(x: 130, y: 130, width: 50, height: 50)
        if screenCtrlMode == 1{
            shapeLayer.strokeColor = UIColor.white.cgColor
        }else
        {
            shapeLayer.strokeColor = UIColor.red.cgColor
        }
        
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.path = UIBezierPath(
            rect: CGRect(x: 0, y: 0, width: 50, height: 50)
        ).cgPath
        shapeLayer.position = focusPosition!
        return shapeLayer
        
    }

    /// 重播骨架影片
    @IBAction func replayVideo(_ sender: UIButton) {

        let videoImageUrl = "http://114.41.138.43:8000/download/111.mp4"
        let donloadurl = URL(string:videoImageUrl)
        self.playVideo(videoPath: donloadurl, serverResult:self.videoPicker.RPM)
        DispatchQueue.global(qos: .background).async {
            if let url = URL(string: videoImageUrl),
                let urlData = NSData(contentsOf: url) {
                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0];
                let filePath="\(documentsPath)/tempFile.mov"
                DispatchQueue.main.async {
                    urlData.write(toFile: filePath, atomically: true)
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: filePath))
                    }) { completed, error in
                        if completed {
                            print("Video is saved!")
                            
                        }
                    }
                }
            }
        }
    }

    /// 對焦框位置
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

            camera.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    //// 未使用 待確認
    ///未使用 待確認
    @IBAction func onValueChanged(_ sender: UISwitch){
        
        if sender.isOn {
            //===============camera change===================//
            session.beginConfiguration()
            session.removeInput(session.inputs.last!)
            session.addInput(deviceInput.backWildAngleCamera!)
            session.commitConfiguration()
            //===============================================//
            self.selectedPredMode = true
            videoPicker.ServerURL = "http://" + serverIP + ":8000/ballspeed"
            print(videoPicker.ServerURL)
        } else{
            //http://36.235.131.131:8000/
            //===============camera change===================//
            session.beginConfiguration()
            session.removeInput(session.inputs.last!)
            session.addInput(deviceInput.backTelephotoCamera!)
            // long focal
            session.commitConfiguration()
            //=================================================//
            self.selectedPredMode = false
            videoPicker.ServerURL = "http://" + serverIP + ":8000/spinrate"
            print(videoPicker.ServerURL)

        }
    }


    /* 未使用 待確認
    @IBAction func settingIso(_ sender: UITextField) {
        let valIso = Float(txtFieldIso.text!) ?? 50.0
        let valShutterSpeed = Int32(txtFieldShutterSpeed.text!) ?? 3000
        cameraSetting(setIso:valIso, setShutterSpeed:valShutterSpeed)
    }
    
    @IBAction func settingShutterSpeed(_ sender: UITextField) {
        let valIso = Float(txtFieldIso.text!) ?? 50.0
        let valShutterSpeed = Int32(txtFieldShutterSpeed.text!) ?? 3000
        cameraSetting(setIso:valIso, setShutterSpeed:valShutterSpeed)
    }
    */

    @IBAction func showImagePicker(_ sender: UIButton) {

        //playVideo(videoPath: self.tmpOutputURL, rpm: videoPicker.RPM)
        self.videoPicker.selectVideo(from: sender)
        //playVideo(videoPath: videoPicker.VIDEOURL, rpm: videoPicker.RPM)
    
    }

    func degreeToRadian(_ x: CGFloat) -> CGFloat {
        return .pi * x / 180.0
    }
    ///刪除暫存影片
    func deltempfile(){
        let fm = FileManager.default
        do{
            let files = try fm.contentsOfDirectory(atPath: NSTemporaryDirectory())
            for file in files{
                print(file)
                //del file
                try fm.removeItem(atPath: (NSTemporaryDirectory() + file))
            }
        } catch{
            print("err")
        }
    }

    func hint(){
        let alertController = UIAlertController(title:"提醒您！",message: "＊請先輸入Server IP!\n *球速預測須先校正一次!",preferredStyle: .alert)
        let actionOK = UIAlertAction(title: "OK", style: .default){_ in
            print("ok")
        }
        alertController.addAction(actionOK)
        show(alertController ,sender: self)
        //self.present(alertController, animated: true)
    }
    ////
}

/// 變換對焦位置 和 pixeltometer校正
extension ViewController: UITextFieldDelegate {
   override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       //================================================================//
       // focus of camera
       let touch = touches.first!
       let location = touch.location(in: self.view)
       let touchX = location.x / self.view.frame.width
       let touchY = location.y / self.view.frame.height
       if  (0.3<touchY && touchY<0.65) && (screenCtrlMode == 1){
           self.focusPosition = location
           if let sublayers = view.layer.sublayers {
               for layer in sublayers {
                   if layer.name == "rectfocal" {
                       layer.position = location
                   }
               }
           }
           focalSetting(touchX: touchX, touchY: touchY) // set focal 0-1
           print("began\(location)")
       }
       
       self.view.endEditing(true)
       //================================================================//
       //https://stackoverflow.com/questions/44181926/swift-3-labels-move-by-touch/44182096
       //pixel to meter
       var path = UIBezierPath()
       print("Scale: \(UIScreen.main.scale)")
       if (firstTouch == true && screenCtrlMode == 2){
           self.fLocation = touches.first?.previousLocation(in: self.viewCameraPreview)
           firstTouch = false
           print("cgpoint first: \(fLocation!)")
       } else if(firstTouch == false && screenCtrlMode == 2){
           self.sLocation = touches.first?.previousLocation(in: self.viewCameraPreview)
           print("cgpoint second: \(sLocation!)")
           let disx = (fLocation!.x - sLocation!.x) * (1080/UIScreen.main.bounds.width)
           let disy = (fLocation!.y - sLocation!.y) * (1920/UIScreen.main.bounds.height)
           let dis = sqrt(disx * disx + disy * disy)
           dis_result = Float(dis)
           //print("dist [\(disx),\(disy), \(dis)]")
           firstTouch = true
           
           if let sublayers = view.layer.sublayers {
               for layer in sublayers {
                   if layer.name == "straightLine" {
                       layer.removeFromSuperlayer()
                   }
               }
           }
           path = UIBezierPath()
           path.move(to: fLocation ?? CGPoint.init())
           path.addLine(to: sLocation ?? CGPoint.init())
           drawLine()
           
           pixelLabel.text = "\(Int(dis)) px"
       }

       func drawLine(){
           let shape = CAShapeLayer()
           shape.name = "straightLine"
           shape.path = path.cgPath
           shape.strokeColor = UIColor.red.cgColor
           self.view.layer.addSublayer(shape)
       }
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
/*extension ViewController: UITextFieldDelegate {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: self.view)
        //let location = touches.first?.location(in: view)
        let touchX = location.x / self.view.frame.width
        let touchY = location.y / self.view.frame.height 
        if  (0.3<touchY && touchY<0.65) && (screenCtrlMode == 1){
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
    
}*/
