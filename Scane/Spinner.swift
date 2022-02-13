//
//  Spinner.swift
//  Scane
//
//  Created by Matt Adam on 2022-01-29.
//

import SwiftUI

public struct Spinner:  NSViewRepresentable {
    public typealias Context = NSViewRepresentableContext<Self>
    public typealias NSViewType = NSProgressIndicator

    private var size: NSControl.ControlSize
    
    public init(size: NSControl.ControlSize = .regular) {
        self.size = size
    }
    
    public func makeNSView(context: Context) -> NSViewType {
        let nsView = NSProgressIndicator()
        nsView.isIndeterminate = true
        nsView.style = .spinning
        nsView.controlSize = size
        nsView.sizeToFit()
        nsView.startAnimation(nil)
        return nsView
    }
    
    public func updateNSView(_ nsView: NSViewType, context: Context) {
    }
}
