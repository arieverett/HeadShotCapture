//
//  HeadshotAnalyzer.swift
//  HeadShotCapture
//
//  Created by Ari Everett on 4/21/26.
//

import Foundation
import UIKit
import Vision

struct FaceAnalysis {
    var faceDetected: Bool
    var isCentered: Bool
    var landmarksDetected: [String]
}

struct HeadshotAnalyzer {
    func analyze(image: UIImage) async -> FaceAnalysis {
        guard let cgImage = image.cgImage else {
            return FaceAnalysis(faceDetected: false, isCentered: false, landmarksDetected: [])
        }

        let request = DetectFaceLandmarksRequest()

        do {
            let observations = try await request.perform(on: cgImage)

            guard let face = observations.first else {
                return FaceAnalysis(faceDetected: false, isCentered: false, landmarksDetected: [])
            }

            let boundingBox = face.boundingBox
            let centerX = boundingBox.origin.x + (boundingBox.width / 2.0)
            let isCentered = abs(centerX - 0.5) < 0.15

            var landmarks: [String] = []

            if face.landmarks?.faceContour != nil {
                landmarks.append("Face Contour")
            }
            if face.landmarks?.leftEye != nil {
                landmarks.append("Left Eye")
            }
            if face.landmarks?.rightEye != nil {
                landmarks.append("Right Eye")
            }
            if face.landmarks?.nose != nil {
                landmarks.append("Nose")
            }
            if face.landmarks?.outerLips != nil {
                landmarks.append("Outer Lips")
            }
            if face.landmarks?.innerLips != nil {
                landmarks.append("Inner Lips")
            }
            if face.landmarks?.leftEyebrow != nil {
                landmarks.append("Left Eyebrow")
            }
            if face.landmarks?.rightEyebrow != nil {
                landmarks.append("Right Eyebrow")
            }

            return FaceAnalysis(
                faceDetected: true,
                isCentered: isCentered,
                landmarksDetected: landmarks
            )

        } catch {
            print("Headshot analysis error: \(error)")
            return FaceAnalysis(faceDetected: false, isCentered: false, landmarksDetected: [])
        }
    }
}
