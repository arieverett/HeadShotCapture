//
//  CaptureHandler.swift
//  HeadShotCapture
//
//  Created by Ari Everett on 3/18/26.
//

import Foundation
import SwiftUI
import AVFoundation

@Observable
class CaptureHandler: NSObject {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    
    var isSessionRunning = false
    var cameraAccessDenied = false
    
    func setup() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            print("Capture authorized")
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else {
                cameraAccessDenied = true
                return
            }
        default:
            cameraAccessDenied = true
            return
        }
        
        configureSession()
        
        Task.detached { [session] in
            session.startRunning()
            await MainActor.run {
                self.isSessionRunning = true
            }
            
        }
        
    }
    
    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        defer {
            session.commitConfiguration()
        }
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        else {
            print("Warning, AVCaptureDevice failed.")
            return
            
        }
        
        guard let input = try? AVCaptureDeviceInput(device: camera) else {
            print("Warning, AVCaptureDeviceInput failed.")
            return
        }
        
        guard session.canAddInput(input) else {
            return
        }
        
        session.addInput(input)
        
        guard session.canAddOutput(photoOutput) else {
            print("Warning, session can't add photoOutput")
            return
        }
        
        session.addOutput(photoOutput)
    }
}
