//
//  DeviceInput.swift
//  baseball_ai_analyst
//
//  Created by Admin on 2022/9/11.
//

import AVFoundation

class DeviceInput: NSObject {
    var frontWildAngleCamera: AVCaptureDeviceInput?
    
    var backWildAngleCamera: AVCaptureDeviceInput?
    
    var backTelephotoCamera: AVCaptureDeviceInput?
    
    var backDualCamera: AVCaptureDeviceInput?
    
    var microphone: AVCaptureDeviceInput?
    
    func getAllCameras() {
        let cameraDevices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInTelephotoCamera,
                          .builtInDualCamera],
            mediaType: .video,
            position: .unspecified).devices
        
        for camera in cameraDevices {
            let inputDevice = try! AVCaptureDeviceInput(device: camera)
            
            if camera.deviceType == .builtInWideAngleCamera, camera.position == .front {
                frontWildAngleCamera = inputDevice
            }
            
            if camera.deviceType == .builtInWideAngleCamera, camera.position == .back {
                backWildAngleCamera = inputDevice
            }
            
            if camera.deviceType == .builtInTelephotoCamera {
                backTelephotoCamera = inputDevice
            }
            
            if camera.deviceType == .builtInDualCamera {
                backDualCamera = inputDevice
            }
        }
    }
    
    func getMicrophone() {
        
        if let mic = AVCaptureDevice.default(for: .audio) {
            microphone = try! AVCaptureDeviceInput(device: mic)
        }
    }
    
    override init() {
        super.init()
        getAllCameras()
        getMicrophone()
    }
}
