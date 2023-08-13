//
//  ContentView.swift
//  Scane
//
//  Created by Matt Adam on 2021-11-29.
//

import SwiftUI

struct MainView: View {
    
    @ObservedObject
    var manager: ScanManager
    
    @State
    var previewImage: CGImage?
    
    @State var error: ErrorDefinition?
    
    func doInit() {
        Task {
            do {
                try await manager.initDevice()
            }
            catch {
                self.error = ErrorDefinition(error, "An error occurred initializing scanners")
            }
        }
    }

    func preview() {
        
        #if DEBUG
        if CGKeyCode.optionKeyPressed {
            previewImage = NSImage(named: "AppIcon")!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
            return;
        }
        #endif

        Task {
            do {
                let image = try await manager.scan(preview: true)
                previewImage = image
            }
            catch {
                self.error = ErrorDefinition(error, "An error occurred while preview scanning")
            }
        }
    }
    
    func scan() {
        
        #if DEBUG
        if CGKeyCode.optionKeyPressed {
            let cgImage = NSImage(named: "AppIcon")!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
            let view = ScannedImageView(image: cgImage)
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 200), styleMask: [.titled, .closable], backing: .buffered, defer: false, content: view)
            window.title = "Scanned Image"
            window.makeKeyAndOrderFront(nil)
            window.center()
            return;
        }
        #endif

        Task {
            let image: CGImage
            do {
                image = try await manager.scan(preview: false)
            }
            catch {
                self.error = ErrorDefinition(error, "An error occurred while scanning")
                return
            }

            let view = ScannedImageView(image: image)
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 200), styleMask: [.titled, .closable], backing: .buffered, defer: false, content: view)
            window.title = "Scanned Image"
            window.makeKeyAndOrderFront(nil)
            window.center()
        }
    }

    var body: some View {
        
        let isActive = manager.isScanning || manager.isLoading
        
        NavigationView {
            
            // Left column
            VStack {
                
                if let deviceInfo = manager.deviceInfo {
                    Text("\(deviceInfo.vendor) \(deviceInfo.model)").font(.headline).padding(.top)
                }
                
                Form {
                    ForEach(manager.options.filter(\.isActive), id: \.name) { option in
                        ScanOptionView(option: option)
                    }
                }
                .disabled(isActive)
                .padding(.vertical)
                
                HStack {
                    if manager.canPreview {
                        Button(action: self.preview) {
                            Text("Preview")
                                .frame(width: 80)
                        }
                    }
                    
                    Button(action: self.scan) {
                        Text("Scan")
                            .frame(width: 80)
                    }
                }
                .disabled(isActive)

                Spacer()
            }
            .padding(.horizontal)

            // Right panel
            ZStack {
                if let previewImage = previewImage {
                    PreviewView(image: previewImage, manager: manager)
                        .disabled(isActive)
                        .overlay(Rectangle().fill(Color.black).opacity(isActive ? 0.5 : 0.0))
                }
                
                if manager.isLoading {
                    Spinner()
                }

                if manager.isScanning {
                    ScanProgressView(pct: manager.scanProgress)
                }
            }
        }
        .onAppear(perform: { doInit() })
        .alert(item: $error, content: { error in error.toAlert() })
    }
}
