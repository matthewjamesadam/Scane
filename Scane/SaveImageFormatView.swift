//
//  SaveImageFormatView.swift
//  Scane
//
//  Created by Matt Adam on 2022-01-15.
//

import SwiftUI

enum SaveImageFormat: String {
    case jpeg = "JPEG"
    case png = "PNG"
    
    var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .png: return "png"
        }
    }
}

class SaveImageFormatOptions: ObservableObject {
    @Published var format: SaveImageFormat = .png
    @Published var jpegQuality: Float = 0.75
}

struct SaveImageFormatView: View {

    @ObservedObject var options: SaveImageFormatOptions
    
    let formats: [SaveImageFormat] = [ .png, .jpeg ]

    var body: some View {

        VStack {
            Picker("Format:", selection: $options.format) {
                ForEach(formats, id: \.self) { option in
                    Text(option.rawValue)
                }
            }

            if options.format == .jpeg {
                Slider(value: $options.jpegQuality, in: 0.0...1.0, minimumValueLabel: Text("Least"), maximumValueLabel: Text("Best")) {
                    Text("Quality:")
                }
            }

        }
        .frame(width: 275)
        .padding()
    }
}
