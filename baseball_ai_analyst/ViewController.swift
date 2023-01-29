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
    let activaty = UIActivityIndicatorView(style: .large)
    
    var  rpm: String?
    var serverIP: String = "none"
    public var frame: CGImage?
    private let context = CIContext()
    private var bufferView:UIImageView = UIImageView()
    public var tmpOutputURL: URL?
    var subscriber = Set<AnyCancellable>()
    
    var player = AVPlayer()
    var playerViewController = AVPlayerViewController()
    var RPMlabel = UILabel()
    @IBOutlet weak var txtFieldIso: UITextField!
    
    @IBOutlet weak var ModeSwitch: UISwitch!
    @IBOutlet weak var IPInput: UIButton!
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
    
    var firstTouch: Bool = true
    var fLocation: CGPoint? = CGPoint(x: (0.0), y: (0.0))
    var sLocation: CGPoint? = CGPoint(x: (0.0), y: (0.0))
    var personHeight: Float = 0.0
    var selectedPredMode:Bool = true
    var screenCtrlMode: Int = 1
    var focusPosition: CGPoint? = CGPoint(x: 300, y: 300)
    var dis_result: Float = 0.0
    @IBOutlet weak var inputServerIP: UIButton!
    @IBOutlet weak var segCtrlScreen: UISegmentedControl!
    @IBOutlet weak var segCtrlPred: UISegmentedControl!
    @IBOutlet weak var download: UIButton!
    
    @IBOutlet weak var pixelLabel: UILabel!
    
    @IBOutlet weak var btn_sendParameter: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        activaty.center = view.center
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
        //txtFieldIso.delegate = self
        //txtFieldShutterSpeed.delegate = self
        
        // cemara
        settingPreviewLayer()
        //session.addInput(deviceInput.microphone!)
        //session.addInput(deviceInput.backTelephotoCamera!) // long focal
        session.addInput(deviceInput.backWildAngleCamera!)
        
        //session.sessionPreset = .hd1280x720
        //session.beginConfiguration()
        //session.sessionPreset = AVCaptureSession.Preset.medium
        //session.commitConfiguration()
        session.addOutput(AVCaptureMovieFileOutput()) // output file
        //let videoOutput = AVCaptureVideoDataOutput()
        //videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        //session.addOutput(videoOutput) // get frame
        //videoOutput.connection(with: .video)?.videoOrientation = .landscapeLeft
        session.startRunning()
        settingFPS()
        cameraSetting(setIso: 0.0, setShutterSpeed: 0)
        
        //videoPicker
        self.videoPicker = VideoPicker(presentationController: self)
        //draw rect on screen
        view.layer.addSublayer(rectLayer())
        
        //videoPicker.$RPM.sink { string in
        //    self.RPMlabel.text = string
        //}.store(in: &subscriber)
        //deltempfile()
        
        rotateView()
        pixelLabel.isHidden = true
        btn_sendParameter.isHidden = true
        onlyrecord.setImage(UIImage(named: "record_btn_img"), for: .normal)
        onlyrecord.frame.size = CGSize(width: 55.0, height: 55.0)
        onlyrecord.setTitle("", for: .normal)
        //onlyrecord.textInputMode
        //RPMlabel.text = "100 KPH"
        /*
        RPMlabel.textColor = UIColor.green
        RPMlabel.backgroundColor = UIColor(red:0,green: 0,blue:0,alpha: 0.6)
        RPMlabel.layer.cornerRadius = 10
        RPMlabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        RPMlabel.numberOfLines = 2
        RPMlabel.textAlignment = NSTextAlignment.center
        let title1 = UIFont.preferredFont(forTextStyle: .headline)
        let body = UIFont.preferredFont(forTextStyle: .body)
        
        let style = NSMutableAttributedString(
            string: "BALLSPEED\n",
            attributes: [.font : title1]
        )
        style.append(NSMutableAttributedString(
            string: "100 KPH",
            attributes: [.font: body,
                         ]
            )
        )
        RPMlabel.attributedText = style
         */
        //RPMlabel.font = UIFont(name: "Trebuchet MS", size: 20)
        
        //RPMlabel.frame = CGRect(x: 20, y:200, width: RPMlabel.frame.size.width, height: RPMlabel.frame.size.height)
        RPMlabel.frame = CGRectMake(10,10,150, 70)
        //view.addSubview(RPMlabel)
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
    func rotateView(){
        download.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        segCtrlPred.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        segCtrlScreen.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        inputServerIP.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        pixelLabel.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        btn_sendParameter.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)

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
    @IBAction func screenModeClicked(_ sender: UISegmentedControl) {
        
        if let sublayers = view.layer.sublayers {
            for layer in sublayers {
                //print("i\(String(describing: layer.name))")
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
    
    @IBAction func sendParameter(_ sender: UIButton) {
        //let parameter: Float = dis_result / personHeight
        videoPicker.jsonPost_parameter(height: personHeight, length: dis_result){
            print("send end")
        }
    }
    
    @IBAction func showImagePicker(_ sender: UIButton) {
        //view.addSubview(activaty)
        //activaty.startAnimating()
        //playVideo(videoPath: self.tmpOutputURL, rpm: videoPicker.RPM)
        self.videoPicker.selectVideo(from: sender)
        //playVideo(videoPath: videoPicker.VIDEOURL, rpm: videoPicker.RPM)
    
        
       /* let activaty = UIActivityIndicatorView(style: .large)
        activaty.center = view.center
        activaty.startAnimating()
        view.addSubview(activaty)
        
        let group: DispatchGroup = DispatchGroup()//主程式似乎不會被組塞
                
        let queue1 = DispatchQueue(label: "queue1")
        group.enter() // 開始呼叫 API1
        queue1.async(group: group) {
            // Call API1
            self.videoPicker.jsonPost(videoPath: self.tmpOutputURL) // auto upload video
            // 結束呼叫 API1
            group.leave()
        }
            
        group.notify(queue: DispatchQueue.global()) {
            // 完成所有 Call 後端 API 的動作
            activaty.stopAnimating()
            print("完成所有 Call 後端 API 的動作...")
            activaty.removeFromSuperview()
            self.playVideo(videoPath: self.tmpOutputURL, rpm: self.videoPicker.RPM)
            
        }
        //activaty.removeFromSuperview()
        //playVideo(videoPath: self.tmpOutputURL, rpm: videoPicker.RPM)
        */
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
        //session.sessionPreset = .hd1280x720
        //session.sessionPreset = AVCaptureSession.Preset.medium
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
            
            //guard format.formatDescription.dimensions.width ==  1280 else { continue }
            //guard format.formatDescription.dimensions.height == 720 else { continue }

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
        /*activaty.center = view.center
        activaty.startAnimating()
        view.addSubview(activaty)

        self.videoPicker.jsonPost_completion(videoPath: self.tmpOutputURL) {
            DispatchQueue.main.async {
                self.activaty.stopAnimating()
                self.activaty.removeFromSuperview()
            }
            
            self.playVideo(videoPath: self.tmpOutputURL, sm: self.videoPicker.RPM)
        }*/
        /*print("file ouput url: \(outputFileURL.absoluteString)")
        
        
        activaty.center = view.center
        activaty.startAnimating()
        view.addSubview(activaty)
         
        let group: DispatchGroup = DispatchGroup()//主程式似乎不會被組塞
                 
        let queue1 = DispatchQueue(label: "queue1")
        group.enter() // 開始呼叫 API1
        queue1.async(group: group) {
             // Call API1
            self.videoPicker.jsonPost(videoPath: self.tmpOutputURL) // auto upload video
             // 結束呼叫 API1
            group.leave()
        }
        self.activaty.stopAnimating()
        self.activaty.removeFromSuperview()
        group.notify(queue: DispatchQueue.global()) {
             // 完成所有 Call 後端 API 的動作
            print("完成所有 Call 後端 API 的動作...")
            self.playVideo(videoPath: self.tmpOutputURL, rpm: self.videoPicker.RPM)
             
        }
        //videoPicker.jsonPost(videoPath: outputFileURL) // auto upload video
        //playVideo(videoPath: outputFileURL, rpm: videoPicker.RPM)*/
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
   
    @IBAction func toServerResult(_ sender: UIButton) {
        performSegue(withIdentifier: "toServerResult", sender: self)
        
    }
    override func prepare(for segue: UIStoryboardSegue, sender:Any?) {
    let resultVC = segue.destination as! SecondViewController
        resultVC.rpm = self.videoPicker.RPM
        resultVC.runtime = self.videoPicker.runtime
        
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
            
            //self.videoPicker.jsonPost(videoPath: self.tmpOutputURL) // auto upload video
            self.activaty.startAnimating()
            self.view.addSubview(self.activaty)
            self.videoPicker.gzipstream(file: self.tmpOutputURL){
                DispatchQueue.main.async {
                    self.activaty.stopAnimating()
                    self.activaty.removeFromSuperview()
                    let endTime = CFAbsoluteTimeGetCurrent()
                    print("程式碼執：\(endTime - startTime)")
                    self.playVideo(videoPath: self.tmpOutputURL, serverResult:self.videoPicker.RPM)
                    
                }
                //self.videoPicker.test(file: self.tmpOutputURL!)
                //let endTime = CFAbsoluteTimeGetCurrent()
                //print("程式碼執：\(endTime - startTime)")
            }
        }
        
        /*self.videoPicker.jsonPost_completion(videoPath: self.tmpOutputURL) {
            /*DispatchQueue.main.async {
                self.activaty.stopAnimating()
                self.activaty.removeFromSuperview()
                self.playVideo(videoPath: self.tmpOutputURL, rpm: self.videoPicker.RPM)
             
             }*/
            
        }*/
        
        
        
        //let activaty = UIActivityIndicatorView(style: .large)
        /*activaty.center = view.center
        activaty.startAnimating()
        view.addSubview(activaty)
        let group: DispatchGroup = DispatchGroup()
        
        let queue1 = DispatchQueue(label: "queue1")
        group.enter() // 開始呼叫 API1
        queue1.async(group: group) {
            // Call API1
            self.videoPicker.jsonPost(videoPath: self.tmpOutputURL) // auto upload video
            // 結束呼叫 API1
            group.leave()
        }
        
        group.notify(queue: DispatchQueue.global()) {
            // 完成所有 Call 後端 API 的動作
            print("完成所有 Call 後端 API 的動作...")
         /*  DispatchQueue.main.async {
                self.activaty.stopAnimating()
                self.activaty.removeFromSuperview()
                playVideo(videoPath: self.tmpOutputURL, rpm: videoPicker.RPM)
          
              }*/
        }
*/
        
    }
    
    // Botton stop recording
    /*@IBAction func stopRecordButton(_ sender: Any) {
        let output = session.outputs.first! as! AVCaptureMovieFileOutput
        output.stopRecording()
    }*/
    

    
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
            

            camera.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    // Button replay video
    @IBAction func replayVideo(_ sender: UIButton) {
        //playVideo(videoPath: self.videoPicker.VIDEOURL, serverResult: self.videoPicker.RPM)
        print("press")
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


    func degreeToRadian(_ x: CGFloat) -> CGFloat {
        return .pi * x / 180.0
    }
    
    // replay and show label
    func playVideo(videoPath: URL? , serverResult: String?){
        if videoPath == nil {
            print("videoPath is nil")
            return
        }
        print("play video")

        //RPMlabel.lineBreakMode = NSLineBreakMode.byWordWrapping
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
        
        //RPMlabel.frame = CGRect(x: 20, y:200, width: RPMlabel.frame.size.width, height: RPMlabel.frame.size.height)
        RPMlabel.frame = CGRectMake(self.view.frame.height*0.7,self.view.frame.width*0.8,150, 70)
        //RPMlabel.sizeToFit()
        let playerItem = AVPlayerItem(url: videoPath!)
        playerItem.audioTimePitchAlgorithm = .varispeed
        player = AVPlayer(playerItem: playerItem)
        player.rate = 0.125
        playerViewController.player = player
        
        playerViewController.contentOverlayView!.addSubview(RPMlabel)
        
        //NotificationCenter.default.addObserver(self, selector: "playerDidFinishPlaying:", name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        //playerViewController.contentOverlayView!.addSubview(loadIndicatorView)
        self.present(playerViewController, animated: true)
        {
        //  //auto play the video
        //  player.play()
            
        }
    }    // error

    func playerDidFinishPlaying(note: NSNotification) {
        // Your code here
        player.rate = 0.125
    }
    func deltempfile(){
        let fm = FileManager.default
        do{
            let files = try fm.contentsOfDirectory(atPath: NSTemporaryDirectory())
            for file in files{
                print(file)
                //del file
                //try fm.removeItem(atPath: (NSTemporaryDirectory() + file))
            }
        } catch{
            print("err")
        }
    }
    
    // create a rect layer
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
            /*let alertController = UIAlertController(title: "TEST", message: "HELLO", preferredStyle: .alert)
            let actionOK = UIAlertAction(title: "OK", style: .default,handler: nil)
            alertController.addAction(actionOK)
            show(alertController,sender: self)*/
        }
    }
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
extension ViewController: UITextFieldDelegate {
   override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       //================================================================//
       // focus of camera
       let touch = touches.first!
       let location = touch.location(in: self.view)
       //let location = touches.first?.location(in: view)
       let touchX = location.x / self.view.frame.width
       let touchY = location.y / self.view.frame.height
       if  (0.3<touchY && touchY<0.65) && (screenCtrlMode == 1){
           self.focusPosition = location
           if let sublayers = view.layer.sublayers {
               for layer in sublayers {
                   //print("i\(String(describing: layer.name))")
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
           print("screen h: \(UIScreen.main.bounds.height)")
           print("screen width: \(UIScreen.main.bounds.width)")
           print("dist [\(disx),\(disy), \(dis)]")
           firstTouch = true
           
           if let sublayers = view.layer.sublayers {
               for layer in sublayers {
                   //print("i\(String(describing: layer.name))")
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
