//
//  ScannedImageView.swift
//  Scane
//
//  Created by Matt Adam on 2022-01-10.
//

import SwiftUI
import Combine

struct ScannedImageView: View {
    
    let cgImage: CGImage
    let nsImage: NSImage
    private let idealViewSize = CGFloat(500.0)
    
    @State var error: ErrorDefinition?

    @Environment(\.hostingWindow) var hostingWindow

    init(image: CGImage) {
        self.cgImage = image
        self.nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
    }
    
    private func save() {
        
        guard let window = hostingWindow?.window else {
            // FIXME: show error
            return
        }
        
        let panel = NSSavePanel()

        let options = SaveImageFormatOptions()
        let accessoryView = NSHostingView(rootView: SaveImageFormatView(options: options))
        
        let sinkCancellable = options.$format.sink { value in
            panel.allowedFileTypes = [ value.fileExtension ]
        }
        
        accessoryView.translatesAutoresizingMaskIntoConstraints = false
        panel.accessoryView = accessoryView
        
        panel.beginSheetModal(for: window) { response in
            
            sinkCancellable.cancel()
            
            if response == .OK, let savePath = panel.url {
                self.save(path: savePath, options: options)
            }
        }
    }
    
    private func save(path: URL, options: SaveImageFormatOptions) {

        let imageRep = NSBitmapImageRep(cgImage: cgImage)
        var imageData: Data?
        
        switch options.format {
        case .png:
            imageData = imageRep.representation(using: .png, properties: [:])
        case .jpeg:
            imageData = imageRep.representation(using: .jpeg, properties: [.compressionFactor: options.jpegQuality])
        }
        
        
        do {
            try imageData?.write(to: path)
        }
        catch {
            self.error = ErrorDefinition(error, "An error occurred saving the image")
        }
    }
    
    private func cancel() {
        hostingWindow?.window?.close()        
    }
    
    var body: some View {
        
        let imageZoom = idealViewSize / max(nsImage.size.width, nsImage.size.height)
        
        VStack {
            
            ZoomableImageView(image: nsImage, magnification: imageZoom).frame(width: idealViewSize, height: idealViewSize).padding(.bottom)
            
            HStack {
                Spacer()
                
                Button(action: self.cancel) {
                    Text("Cancel").frame(minWidth: 65)
                }
                
                Button(action: self.save) {
                    Text("Save").frame(minWidth: 65)
                }
            }
        }
        .padding()
        .alert(item: $error, content: { error in error.toAlert() })
    }
}
