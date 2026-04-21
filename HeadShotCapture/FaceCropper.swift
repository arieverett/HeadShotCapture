//
//  FaceCropper.swift
//  HeadShotCapture
//
//  Created by Loren Olson on 3/25/26.
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
