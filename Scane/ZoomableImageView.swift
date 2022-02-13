//
//  ZoomableScrollView.swift
//  Scane
//
//  Created by Matt Adam on 2022-01-10.
//

import SwiftUI

struct ZoomableImageView: NSViewRepresentable {
    typealias NSViewType = NSScrollView

    let image: NSImage
    let magnification: CGFloat
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.allowsMagnification = true
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = true
        scrollView.magnification = magnification
        scrollView.minMagnification = magnification / 4
        scrollView.maxMagnification = magnification * 10
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let imageView = NSImageView(image: self.image)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.contentView = CenteredClipView()
        scrollView.documentView = imageView
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
    }
}


class CenteredClipView: NSClipView {
    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        var rect = super.constrainBoundsRect(proposedBounds)

        if let containerView = documentView {
            if rect.size.width > containerView.frame.size.width {
                rect.origin.x = (containerView.frame.width - rect.width ) / 2
            }

            if rect.size.height > containerView.frame.size.height {
                rect.origin.y = (containerView.frame.height - rect.height ) / 2
            }
        }

        return rect
    }
}
