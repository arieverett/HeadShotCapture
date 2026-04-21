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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
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
                }

                LazyVStack(alignment: .leading) {
                    ForEach(textRecognizer.allTranscripts) { line in
                        Text(line.text)
                    }
                }
                .padding(.horizontal, 8)

                Text("Summary")
                    .font(.title)

                Text(textRecognizer.summary)
            }
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
        }
    }
}
