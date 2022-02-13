//
//  ScanProgressView.swift
//  Scane
//
//  Created by Matt Adam on 2022-01-10.
//

import SwiftUI

struct ScanProgressView: View {
    
    var pct: Double
    
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 10)

        VStack {
            Text("Scanning...").font(.headline)
            ProgressBar(value: pct).frame(maxWidth: 200)
        }
        .padding()
        .background(shape.fill(Color(.controlBackgroundColor)))
        .background(shape.stroke(Color(.controlColor)))
    }
}
