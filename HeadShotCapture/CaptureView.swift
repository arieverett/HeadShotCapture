//
//  CaptureView.swift
//  HeadShotCapture
//
//  Created by Ari Everett on 3/18/26.
//

import SwiftUI

struct CaptureView: View {
    @State private var capture = CaptureHandler()
    
    var body: some View {
        ZStack {
            // todo: camera preview
            
            VStack {
                Spacer()
                
                Text("tap to capture.")
            }
        }
        .task {
            await capture.setup()
            
        }
    }
}


//#preview {
//CaptureView()
//}
