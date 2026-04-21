//
//  ContentView.swift
//  HeadShotCapture
//
//  Created by Ari Everett on 3/18/26.
//

import SwiftUI

struct ContentView: View {
    @State private var photo: UIImage?
    @State private var textRecognizer = TextRecognizer()
    @State private var analysis = FaceAnalysis(
        faceDetected: false,
        isCentered: false,
        landmarksDetected: []
    )

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let photo {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 400, height: 400)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(.white, lineWidth: 3)
                            )
                            .shadow(radius: 10)
                    }

                    transcriptSection

                    summarySection

                    analysisSection
                }
                .padding(.horizontal, 8)
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button("Recognize") {
                        guard let photo else { return }
                        Task {
                            await textRecognizer.detectText(image: photo)
                        }
                    }

                    Spacer()

                    NavigationLink {
                        CaptureView(photo: $photo)
                    } label: {
                        Label("Camera", systemImage: "camera")
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()

                    Button("Analyze") {
                        guard let photo else { return }
                        Task {
                            analysis = await HeadshotAnalyzer().analyze(image: photo)
                        }
                    }

                    Spacer()

                    Menu {
                        Button("Save to Photo Library", systemImage: "photo") {
                            guard let photo else { return }
                            let imageSaver = ImageSaver()
                            imageSaver.writeToPhotoAlbum(image: photo)
                        }

                        Button("Save Jpeg to Documents", systemImage: "photo") {
                            guard let photo else { return }
                            exportJpegToDocuments(
                                image: photo,
                                filename: "photo.jpg",
                                quality: 0.9
                            )
                        }
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                }
            }
        }
    }

    private var transcriptSection: some View {
        LazyVStack(alignment: .leading) {
            ForEach(textRecognizer.allTranscripts) { line in
                Text(line.text)
            }
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary")
                .font(.title)

            Text(textRecognizer.summary)
        }
    }

    private var analysisSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Headshot Analysis")
                .font(.title2)

            if analysis.faceDetected {
                Text("Face detected")
                Text(analysis.isCentered ? "Face is centered" : "Face not centered")

                ForEach(analysis.landmarksDetected, id: \.self) { item in
                    Text(item)
                }
            } else {
                Text("No face detected")
            }
        }
    }
}
