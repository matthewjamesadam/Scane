//
//  CGKeyCodeExtensions.swift
//  Scane
//
//  Created by Matt Adam on 2022-01-24.
//

import Foundation

import CoreGraphics

extension CGKeyCode
{
    static let kVK_Option     : CGKeyCode = 0x3A
    static let kVK_RightOption: CGKeyCode = 0x3D
    
    var isPressed: Bool {
        CGEventSource.keyState(.combinedSessionState, key: self)
    }
    
    static var optionKeyPressed: Bool {
        return Self.kVK_Option.isPressed || Self.kVK_RightOption.isPressed
    }
}
