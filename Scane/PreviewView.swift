//
//  PreviewView.swift
//  Scane
//
//  Created by Matt Adam on 2021-12-21.
//

import SwiftUI

struct PreviewView: View {
    
    var image: CGImage
    
    @ObservedObject
    var manager: ScanManager
    
    var body: some View {
        
        let overlay = manager.canSetRoi ? PreviewGripView(committedRect: manager.roi) : nil

        ZStack {
            Image(decorative: image, scale: 1.0)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .overlay(
                    overlay
                )
        }
        .padding()
    }
}
