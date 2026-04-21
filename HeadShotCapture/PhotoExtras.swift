//
//  PhotoExtras.swift
//  HeadShotCapture
//
//  Created by Ari Everett on 3/30/26.
//

import Foundation
import SwiftUI

// Paul Hudson – ImageSaver class

class ImageSaver: NSObject {
    func writeToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
    }
    
    @objc func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        print("saveCompted")
    }
}

func exportJpegToDocuments(image: UIImage, filename: String, quality: CGFloat) {
    let url = URL.documentsDirectory.appending(path: filename)
    if let data = image.jpegData(compressionQuality: quality) {
        try? data.write(to: url)
    }
}
