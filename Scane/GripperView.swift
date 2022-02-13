//
//  GripperView.swift
//  Scane
//
//  Created by Matt Adam on 2022-01-23.
//

import SwiftUI

enum GripperEdge {
    case left
    case topLeft
    case top
    case topRight
    case right
    case bottomRight
    case bottom
    case bottomLeft
    
    static let cursorNS = NSCursor(image: NSImage(named: "ResizeNS")!, hotSpot: NSPoint(x: 8, y: 8))
    static let cursorEW = NSCursor(image: NSImage(named: "ResizeEW")!, hotSpot: NSPoint(x: 8, y: 8))
    static let cursorNESW = NSCursor(image: NSImage(named: "ResizeNESW")!, hotSpot: NSPoint(x: 8, y: 8))
    static let cursorNWSE = NSCursor(image: NSImage(named: "ResizeNWSE")!, hotSpot: NSPoint(x: 8, y: 8))

    var cursor: NSCursor {
        switch self {
        case .left, .right: return Self.cursorEW
        case .top, .bottom: return Self.cursorNS
        case .topLeft, .bottomRight: return Self.cursorNWSE
        case .topRight, .bottomLeft: return Self.cursorNESW
        }
    }
}

extension CGRect {
    
    func getGripperValue(edge: GripperEdge) -> CGPoint {
        switch edge {
        case .left: return CGPoint(x: self.minX, y: self.minY + (self.height / 2))
        case .topLeft: return CGPoint(x: self.minX, y: self.minY)
        case .top: return CGPoint(x: self.minX + (self.width / 2), y: self.minY)
        case .topRight: return CGPoint(x: self.maxX, y: self.minY)
        case .right: return CGPoint(x: self.maxX, y: self.minY + (self.height / 2))
        case .bottomRight: return CGPoint(x: self.maxX, y: self.maxY)
        case .bottom: return CGPoint(x: self.minX + (self.width / 2), y: self.maxY)
        case .bottomLeft: return CGPoint(x: self.minX, y: self.maxY)
        }
    }
    
    mutating func setGripperValue(point: CGPoint, edge: GripperEdge, bounds: CGRect) {
        if [.left, .topLeft, .bottomLeft].contains(edge) {
            if point.x != self.minX {
                let maxX = self.maxX
                self.origin.x = max(min(point.x, self.maxX), bounds.minX)
                self.size.width = maxX - self.origin.x
            }
        }

        if [.top, .topLeft, .topRight].contains(edge) {
            if point.y != self.minY {
                let maxY = self.maxY
                self.origin.y = max(min(point.y, self.maxY), bounds.minY)
                self.size.height = maxY - self.origin.y
            }
        }

        if [.right, .topRight, .bottomRight].contains(edge) {
            if point.x != self.maxX {
                self.size.width = min(max(point.x, self.minX) - self.minX, bounds.maxX - self.minX)
            }
        }

        if [.bottom, .bottomLeft, .bottomRight].contains(edge) {
            if point.y != self.maxY {
                self.size.height = min(max(point.y, self.minY) - self.minY, bounds.maxY - self.minY)
            }
        }
    }
}

struct GripperView: View {

    @Binding var rect: CGRect
    @Binding var committedRect: CGRect
    
    var edge: GripperEdge
    var boundSize: CGSize

    var body: some View {
        
        let drag = DragGesture(minimumDistance: 0)
            .onChanged({ event in
                rect.setGripperValue(point: CGPoint(x: event.location.x / boundSize.width, y: event.location.y / boundSize.height), edge: edge, bounds: CGRect(x: 0, y: 0, width: 1, height: 1))
            })
            .onEnded({_ in
                committedRect = rect
            })
        
        let pct = rect.getGripperValue(edge: edge)
        let x = pct.x * boundSize.width
        let y = pct.y * boundSize.height

        Circle()
            .fill(Color.accentColor)
            .onHover(perform: { hover in
                if hover {
                    NSApp.keyWindow?.disableCursorRects()
                    self.edge.cursor.push()
                }
                else {
                    NSApp.keyWindow?.enableCursorRects()
                    NSCursor.pop()
                }
            })
            .overlay(Circle().stroke(Color.white))
            .frame(width: 10, height: 10, alignment: .center)
            .position(x: x, y: y)
            .gesture(drag)
    }
}


