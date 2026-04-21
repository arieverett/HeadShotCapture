//
//  HeadShotCaptureApp.swift
//  HeadShotCapture
//
//  Created by Ari Everett on 3/18/26.
//

import SwiftUI

@main
struct HeadShotCaptureApp: App {
    @State private var capture = CaptureHandler()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(capture)
                .task {
                    await capture.setup()
                }
        }
    }
}
