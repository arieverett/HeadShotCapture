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
    private var photoContinuation: CheckedContinuation<UIImage?, Never>? = nil

    var isSessionRunning = false
    var cameraAccessDenied = false
    var devices: [AVCaptureDevice] = []
    private var currentCaptureDevice: AVCaptureDevice?
    private let savedDeviceKey = "CurrentCaptureDevice"

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
        devices = discoverCaptureDevices()
    }

    func start() {
        guard !session.isRunning else { return }
        session.startRunning()
        isSessionRunning = true
    }

    func stop() {
        guard session.isRunning else { return }
        session.stopRunning()
        isSessionRunning = false
    }

    func capturePhoto() async -> UIImage? {
        await withCheckedContinuation { continuation in
            photoContinuation = continuation
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        defer {
            session.commitConfiguration()
        }

        guard let device = getCaptureDevice() else { return }
        guard makeCurrentCaptureDevice(device: device) else { return }

        guard session.canAddOutput(photoOutput) else {
            print("Warning, session can't add photoOutput")
            return
        }
        session.addOutput(photoOutput)
    }

    private func discoverCaptureDevices() -> [AVCaptureDevice] {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInWideAngleCamera,
            .builtInUltraWideCamera,
            .builtInTelephotoCamera,
            .builtInDualCamera,
            .builtInTripleCamera,
        ]
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: .video,
                                                         position: .unspecified)
        return discovery.devices
    }

    func changeCameraInput(device: AVCaptureDevice) {
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
        }

        if let captureInput = session.inputs.first {
            session.removeInput(captureInput)
        }

        guard makeCurrentCaptureDevice(device: device) else { return }
    }

    func makeCurrentCaptureDevice(device: AVCaptureDevice) -> Bool {
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            print("Warning, AVCaptureDeviceInput failed.")
            return false
        }

        guard session.canAddInput(input) else {
            return false
        }

        session.addInput(input)
        currentCaptureDevice = device
        saveAsCurrent(device: device)
        return true
    }

    func saveAsCurrent(device: AVCaptureDevice) {
        if let encodedData = try? JSONEncoder().encode(device.uniqueID) {
            UserDefaults.standard.set(encodedData, forKey: savedDeviceKey)
        }
    }

    func deviceFromSavedDefault() -> AVCaptureDevice? {
        if let savedData = UserDefaults.standard.data(forKey: savedDeviceKey) {
            if let decodedUniqueID = try? JSONDecoder().decode(String.self, from: savedData) {
                return AVCaptureDevice(uniqueID: decodedUniqueID)
            }
        }
        return nil
    }

    func getCaptureDevice() -> AVCaptureDevice? {
        if let device = deviceFromSavedDefault() {
            return device
        }

        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            return device
        }

        return nil
    }

    func isCurrentInput(device: AVCaptureDevice) -> Bool {
        return device.uniqueID == currentCaptureDevice?.uniqueID
    }
}

extension CaptureHandler: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error {
            print(error)
            photoContinuation?.resume(returning: nil)
            photoContinuation = nil
            return
        }

        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            photoContinuation?.resume(returning: nil)
            photoContinuation = nil
            return
        }

        photoContinuation?.resume(returning: image)
        photoContinuation = nil
    }
}
