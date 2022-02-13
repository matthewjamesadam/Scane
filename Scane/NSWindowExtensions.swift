//
//  ViewExtensions.swift
//  Scane
//
//  Created by Matt Adam on 2022-01-09.
//

import Foundation
import SwiftUI

extension NSWindow {
    convenience init<ViewT: View>(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool,
        content: ViewT) {
            
        self.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        self.contentView = NSHostingView(rootView: content.environment(\.hostingWindow, HostingWindow(window: self)))
        self.isReleasedWhenClosed = false
    }
}
