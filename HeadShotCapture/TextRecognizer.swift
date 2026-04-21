//
//  TextRecognizer.swift
//  HeadShotCapture
//
//  Created by Ari Everett on 4/1/26.
//

import SwiftUI
import Vision
import FoundationModels
import Foundation

struct TranscriptLine: Identifiable {
    let id = UUID()
    let text: String
}

@Observable
class TextRecognizer {
    var allTranscripts: [TranscriptLine] = []
    var summary: String = ""

    func detectText(image: UIImage) async {
        guard let cgImage = image.cgImage else { return }

        let imageRequestHandler = ImageRequestHandler(cgImage)
        let recognizeRequest = RecognizeTextRequest()

        allTranscripts = []
        summary = ""

        do {
            let response: RecognizeTextRequest.Result = try await
                imageRequestHandler.perform(recognizeRequest)

            var transcriptStrings: [String] = []

            for observation in response {
                transcriptStrings.append(observation.transcript)
                allTranscripts.append(TranscriptLine(text: observation.transcript))

                print("---------------------------")
                print("transcript: \(observation.transcript)")
                print("\(observation.isTitle ? "TITLE" : "not title")")

                if let wrapFlag = observation.shouldWrapToNextLine {
                    print("\(wrapFlag ? "SHOULD WRAP" : "no wrap")")
                }

                let candidates = observation.topCandidates(3)
                if let firstCandidate = candidates.first {
                    if firstCandidate.confidence < 1.0 {
                        for candidate in candidates {
                            print(" string: \(candidate.string) : confidence: \(candidate.confidence)")
                        }
                    }
                }
            }

            let allText = transcriptStrings.joined(separator: "\n")
            await summarizeRecipe(text: allText)

        } catch {
            print("Error recognizing text: \(error)")
        }
    }

    func summarizeRecipe(text: String) async {
        let model = SystemLanguageModel.default
        guard model.isAvailable else { return }

        let instructions = "What is this recipe? Please describe the primary ingredients found in this recipe. How long will it take to prepare this recipe?"

        let session = LanguageModelSession(instructions: instructions)

        do {
            let response: LanguageModelSession.Response<String> = try await session.respond(to: text)

            print("***********************")
            print("Summary result:")
            print(response.content)

            summary = response.content
        } catch {
            print(error)
        }
    }
}
