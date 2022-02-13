//
//  ProgressIndicator.swift
//  Scane
//
//  Created by Matt Adam on 2022-01-28.
//

import SwiftUI

public struct ProgressBar:  NSViewRepresentable {
    public typealias Context = NSViewRepresentableContext<Self>
    public typealias NSViewType = NSProgressIndicator
    
    private var value: Double = 0.0
    
    public init(value: Double) {
        self.value = value
    }
    
    public func makeNSView(context: Context) -> NSViewType {
        let nsView = NSProgressIndicator()
        nsView.isIndeterminate = false
        nsView.style = .bar
        nsView.minValue = 0.0
        nsView.maxValue = 1.0
//        nsView.layer?.transform = CATransform3DMakeScale(1.0, 0.6, 0.0);
        return nsView
    }
    
    public func updateNSView(_ nsView: NSViewType, context: Context) {
        nsView.doubleValue = value;
    }
}
