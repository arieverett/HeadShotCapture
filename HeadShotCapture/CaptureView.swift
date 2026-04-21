//
//  CaptureView.swift
//  HeadShotCapture
//
//  Created by Ari Everett on 3/18/26.
//

import SwiftUI
import AVFoundation

struct CaptureView: View {
    @Environment(CaptureHandler.self) private var capture
    @Environment(\.dismiss) private var dismiss

    private let faceCropper = FaceCropper()

    @Binding var photo: UIImage?

    var body: some View {
        ZStack {
            CameraPreviewView(session: capture.session)
                .ignoresSafeArea()
        }
        .onAppear {
            capture.start()
        }
        .onDisappear {
            capture.stop()
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Spacer()

                Button(action: {
                    Task {
                        await capturePhoto()
                    }
                }, label: {
                    Image(systemName: "camera.circle")
                        .font(.largeTitle)
                })

                Spacer()

                Menu(content: {
                    ForEach(capture.devices, id: \.uniqueID) { device in
                        Button(action: {
                            capture.changeCameraInput(device: device)
                        }, label: {
                            if capture.isCurrentInput(device: device) {
                                Label(device.localizedName, systemImage: "camera.fill")
                            } else {
                                Label(device.localizedName, systemImage: "camera")
                            }
                        })
                    }
                }, label: {
                    Label("Camera Menu", systemImage: "arrow.triangle.2.circlepath.camera")
                })
            }
        }
    }

    private func capturePhoto() async {
        guard let capturedPhoto = await capture.capturePhoto() else {
            return
        }

        if let croppedFace = await faceCropper.detectAndCropFace(in: capturedPhoto) {
            self.photo = croppedFace
        } else {
            self.photo = capturedPhoto
        }

        dismiss()
    }
}

//#Preview {
//  CaptureView()
//}
