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
