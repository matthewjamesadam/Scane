//
//  GripperRectangleView.swift
//  Scane
//
//  Created by Matt Adam on 2022-01-23.
//

import SwiftUI

struct GripperRectangleView: View {
    var bounds: CGRect
    
    var body: some View {

        let mask = Rectangle()
            .size(width: bounds.width, height: bounds.height)
            .offset(x: bounds.minX, y: bounds.minY)
            .foregroundColor(.black)
            .background(Color.white)
            .compositingGroup()
            .luminanceToAlpha()

        Rectangle()
            .fill(.black)
            .opacity(0.6)
            .mask(mask)
        
        Rectangle()
            .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, miterLimit: 1, dash: [10, 7], dashPhase: 0))
            .overlay(Rectangle()
                    .stroke(Color.gray, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, miterLimit: 1, dash: [10, 7], dashPhase: 0)))
            .offset(x: bounds.minX, y: bounds.minY)
            .frame(width: bounds.width, height: bounds.height)
    }
}
