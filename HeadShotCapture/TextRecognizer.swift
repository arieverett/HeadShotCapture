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

@Observable
class TextRecognizer {
    var allTranscripts: [RecipeLine] = []
    
    var summary: LocalizedStringKey = ""

    func detectText(image: UIImage) async {
        guard let cgImage = image.cgImage else { return }

        let imageRequestHandler = ImageRequestHandler(cgImage)
        let recognizeRequest = RecognizeTextRequest()

        do {
            let response: RecognizeTextRequest.Result = try await
                imageRequestHandler.perform(recognizeRequest)

            for observation in response {
                allTranscripts.append(RecipeLine(id: <#T##UUID#>, text: observation.transcript))
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

            //let allText = allTranscripts.joined(separator: "\n")
            let allText = allTranscripts.map({ $0.text + "\n"}).joined()
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
            summary = LocalizedStringKey(response.content)

        } catch {
            print(error)
        }
    }
}

struct RecipeLine: Identifiable, Equatable {
    var id: UUID
    var text: String
}
