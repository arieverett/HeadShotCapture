//
//  FaceCropper.swift
//  HeadShotCapture
//
//  Created by Ari Everett on 3/25/26.
//

import Foundation
import UIKit
import Vision

struct FaceCropper {

    func detectAndCropFace(in image: UIImage) async -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let request = DetectFaceRectanglesRequest()
        let observations: [FaceObservation]
        do {
            observations = try await request.perform(on: cgImage)
        } catch {
            print(error)
            return nil
        }

        guard let face = observations.first else { return nil }

        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        let boundingBox = face.boundingBox

        let x = boundingBox.origin.x * imageWidth
        let y = (1 - boundingBox.origin.y - boundingBox.height) * imageHeight
        let width = boundingBox.width * imageWidth
        let height = boundingBox.height * imageHeight

        let padding: CGFloat = 0.3
        let padX = width * padding
        let padY = height * padding
        let paddingRect = CGRect(
            x: max(x - padX, 0),
            y: max(y - padY, 0),
            width: min(width + padY * 2, imageWidth - max(x - padX, 0)),
            height: min(height + padY * 2, imageHeight - max(y - padY, 0))
        )

        guard let cropped = cgImage.cropping(to: paddingRect) else { return nil }

        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }
}

struct FaceAnalysis {
    var faceCount: Int = 0
    var hasLeftEye = false
    var hasRightEye = false
    var hasNose = false
    var hasMouth = false
    var isCentered = false

    var featureSummary: String {
        let features = [
            hasLeftEye ? "left eye" : nil,
            hasRightEye ? "right eye" : nil,
            hasNose ? "nose" : nil,
            hasMouth ? "mouth" : nil,
        ].compactMap { $0 }

        return features.isEmpty ? "No facial landmarks detected." : "Detected: " + features.joined(separator: ", ")
    }

    var recommendation: String {
        guard faceCount > 0 else { return "No face found. Try retaking the photo." }
        if isCentered && hasLeftEye && hasRightEye && hasNose && hasMouth {
            return "Good headshot: face is centered and major facial features are visible."
        }
        if !isCentered {
            return "Try centering your face more in the frame."
        }
        return "Face found, but some facial features were not clearly detected. Try better lighting or a more direct angle."
    }
}

@Observable
class HeadshotAnalyzer {
    var analysis = FaceAnalysis()

    func analyze(image: UIImage?) async {
        guard let image, let cgImage = image.cgImage else {
            analysis = FaceAnalysis()
            return
        }

        let request = DetectFaceLandmarksRequest()
        let observations: [FaceObservation]

        do {
            observations = try await request.perform(on: cgImage)
        } catch {
            print(error)
            analysis = FaceAnalysis()
            return
        }

        guard let face = observations.first else {
            analysis = FaceAnalysis(faceCount: 0)
            return
        }

        let landmarks = face.landmarks
        let faceCenterX = face.boundingBox.midX
        let faceCenterY = face.boundingBox.midY
        let centeredX = abs(faceCenterX - 0.5) < 0.18
        let centeredY = abs(faceCenterY - 0.5) < 0.20

        analysis = FaceAnalysis(
            faceCount: observations.count,
            hasLeftEye: landmarks?.leftEye != nil,
            hasRightEye: landmarks?.rightEye != nil,
            hasNose: landmarks?.nose != nil || landmarks?.noseCrest != nil,
            hasMouth: landmarks?.outerLips != nil || landmarks?.innerLips != nil,
            isCentered: centeredX && centeredY
        )
    }
}
