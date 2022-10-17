//
//  ViewController.swift
//  baseball_ai_analyst
//
//  Created by Admin on 2022/9/11.
//

import UIKit
import AVFoundation
import CoreImage

class ViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    var  rpm: String?
    public var frame: CGImage?
    private let context = CIContext()
    private var bufferView:UIImageView = UIImageView()
    
    @IBOutlet weak var txtFieldIso: UITextField!
    
    @IBOutlet weak var txtFieldShutterSpeed: UITextField!
    // 640h 345w
    @IBOutlet weak var viewCameraPreview : UIView!
    
    @IBOutlet weak var bufferPreview: UIView!
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
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // circle record button
        //recordButtonBorder.layer.cornerRadius = 100
        //recordButtonBorder.layer.borderWidth = 10
        //recordButtonBorder.layer.borderColor = UIColor.white.cgColor
        recordButton.frame.size = CGSize(width: 15.0, height: 15.0)
        recordButton.setImage(UIImage(named: "record_state_off"), for: .normal)
        recordButton.setImage(UIImage(named: "record_state_on"), for: .selected)
        //recordButton.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        // 按空白處使鍵盤消失
        txtFieldIso.delegate = self
        txtFieldShutterSpeed.delegate = self
        // cemara
        settingPreviewLayer()
        session.addInput(deviceInput.microphone!)
        session.addInput(deviceInput.backWildAngleCamera!)
        
        session.sessionPreset = .hd1280x720
        session.addOutput(AVCaptureMovieFileOutput()) // output file
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        session.addOutput(videoOutput) // get frame
        videoOutput.connection(with: .video)?.videoOrientation = .portrait
        session.startRunning()
        settingFPS()
        
        
        //videoPicker
        self.videoPicker = VideoPicker(presentationController: self)
        
    }
    //videoPicker
    
    @IBAction func showImagePicker(_ sender: UIButton) {
        self.videoPicker.selectVideo(from: sender)
        
    }
    
    
    func settingPreviewLayer() {
        let previewLayer = AVCaptureVideoPreviewLayer()
        previewLayer.frame = viewCameraPreview.bounds
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
        viewCameraPreview.layer.addSublayer(previewLayer)
        
        
        bufferView.contentMode = UIView.ContentMode.scaleAspectFit
        bufferPreview.addSubview(bufferView)
        
    }
    
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
                camera.exposureMode = .continuousAutoExposure
            }
            
            if camera.isFocusModeSupported(.continuousAutoFocus) {
                camera.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
                camera.focusMode = .continuousAutoFocus
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
    
    func settingFPS() {
        session.beginConfiguration()
        session.sessionPreset = .hd1280x720
        let input = session.inputs.last as! AVCaptureDeviceInput
        if input.device.deviceType == .builtInMicrophone {
            return
        }
        
        let camera = input.device
        //----------------------------------------------//fps
        for format in camera.formats {
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
                let duration = maxRange.minFrameDuration
                camera.activeVideoMaxFrameDuration = duration
                camera.activeVideoMinFrameDuration = duration
                camera.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
        //----------------------------------------------//fps
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
    @IBAction func recording(_ sender: UIButton) {
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
    }
    
   /* @IBAction func pickVideo(_ sender: UIButton) {
        self.videoPicker.selectVideo(from: sender)
        
    }*/
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
   
    @IBAction func toServerResult(_ sender: UIButton) {
        performSegue(withIdentifier: "toServerResult", sender: self)
        
    }
    
    @IBAction func recordButton(_ sender: Any) {
        
        let url = URL(fileURLWithPath: NSTemporaryDirectory() + "output.mov")
        let output = session.outputs.first! as! AVCaptureMovieFileOutput
        output.startRecording(to: url, recordingDelegate: self)
        
    }
    
    @IBAction func stopRecordButton(_ sender: Any) {
        let output = session.outputs.first! as! AVCaptureMovieFileOutput
        output.stopRecording()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender:Any?) {
    let resultVC = segue.destination as! SecondViewController
        resultVC.rpm = self.videoPicker.RPM
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
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
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
}
extension ViewController: UITextFieldDelegate {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
}
