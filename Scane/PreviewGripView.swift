//
//  PreviewGripView.swift
//  Scane
//
//  Created by Matt Adam on 2022-01-23.
//

import SwiftUI

struct PreviewGripView: View {
    
    @State var rect = CGRect(x: 0, y: 0, width: 1.0, height: 1.0)
    @Binding var committedRect: CGRect

    var body: some View {

        return GeometryReader { geometry in

            let bounds = CGRect(x: geometry.size.width * rect.minX, y: geometry.size.height * rect.minY, width: geometry.size.width * rect.width, height: geometry.size.height * rect.height)

            GripperRectangleView(bounds: bounds)

            GripperView(rect: $rect, committedRect: $committedRect, edge: .topLeft, boundSize: geometry.size)
            GripperView(rect: $rect, committedRect: $committedRect, edge: .top, boundSize: geometry.size)
            GripperView(rect: $rect, committedRect: $committedRect, edge: .topRight, boundSize: geometry.size)
            GripperView(rect: $rect, committedRect: $committedRect, edge: .right, boundSize: geometry.size)
            GripperView(rect: $rect, committedRect: $committedRect, edge: .bottomRight, boundSize: geometry.size)
            GripperView(rect: $rect, committedRect: $committedRect, edge: .bottom, boundSize: geometry.size)
            GripperView(rect: $rect, committedRect: $committedRect, edge: .bottomLeft, boundSize: geometry.size)
            GripperView(rect: $rect, committedRect: $committedRect, edge: .left, boundSize: geometry.size)
        }
        // If outside code modifies the rect, adopt the new value
        // This happens when the rect is re-set on preview
        .onChange(of: committedRect, perform: { value in
            if committedRect != rect {
                rect = committedRect
            }
        })
    }
}
