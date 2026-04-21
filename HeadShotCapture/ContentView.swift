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
    @State private var headshotAnalyzer = HeadshotAnalyzer()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
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
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.thinMaterial)
                            .frame(width: 400, height: 400)
                            .overlay {
                                VStack(spacing: 8) {
                                    Image(systemName: "person.crop.square")
                                        .font(.largeTitle)
                                    Text("Capture a headshot to begin")
                                }
                                .foregroundStyle(.secondary)
                            }
                    }

                    if headshotAnalyzer.analysis.faceCount > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Headshot Analysis")
                                .font(.title2)
                                .bold()
                            Text("Faces detected: \(headshotAnalyzer.analysis.faceCount)")
                            Text("Centered: \(headshotAnalyzer.analysis.isCentered ? "Yes" : "No")")
                            Text(headshotAnalyzer.analysis.featureSummary)
                            Text(headshotAnalyzer.analysis.recommendation)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                    }

                    if !textRecognizer.allTranscripts.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recognized Text")
                                .font(.title2)
                                .bold()

                            LazyVStack(alignment: .leading) {
                                ForEach(textRecognizer.allTranscripts) { line in
                                    Text(line.text)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                    }

                    if !textRecognizer.summary.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Summary")
                                .font(.title2)
                                .bold()
                            Text(textRecognizer.summary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("HeadShotCapture")
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button(action: {
                        guard let photo else { return }
                        Task {
                            await textRecognizer.detectText(image: photo)
                        }
                    }, label: {
                        Label("Recognize", systemImage: "text.viewfinder")
                    })

                    Spacer()

                    NavigationLink(destination: {
                        CaptureView(photo: $photo)
                    }, label: {
                        Label("Camera", systemImage: "camera")
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                    })
                    .buttonStyle(.borderedProminent)

                    Spacer()

                    Menu(content: {
                        Button(action: {
                            guard let photo else { return }
                            let imageSaver = ImageSaver()
                            imageSaver.writeToPhotoAlbum(image: photo)
                        }, label: {
                            Label("Save to Photo Library", systemImage: "photo")
                        })

                        Button(action: {
                            guard let photo else { return }
                            exportJpegToDocuments(
                                image: photo,
                                filename: "photo.jpg",
                                quality: 0.9
                            )
                        }, label: {
                            Label("Save Jpeg to Documents", systemImage: "photo")
                        })
                    }, label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                    })
                }
            }
            .onChange(of: photo) { _, newPhoto in
                Task {
                    await headshotAnalyzer.analyze(image: newPhoto)
                    textRecognizer.allTranscripts = []
                    textRecognizer.summary = ""
                }
            }
        }
    }
}
