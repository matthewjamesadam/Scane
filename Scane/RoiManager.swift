//
//  RoiManager.swift
//  Scane
//
//  Created by Matt Adam on 2022-01-20.
//

import SaneKit

fileprivate protocol RoiSettable: SANEActionValue {
    static func denormalizeValue(value: Double, descriptor: SANEOptionDescriptor) -> Self?
}

extension Int: RoiSettable {
    static func denormalizeValue(value: Double, descriptor: SANEOptionDescriptor) -> Self? {
        if case .intRange(let range) = descriptor.constraint {
            return Int(range.min + Int(Double(range.max - range.min) * value))
        }
        return nil
    }
}

extension Double: RoiSettable {
    static func denormalizeValue(value: Double, descriptor: SANEOptionDescriptor) -> Self? {
        if case .fixedRange(let range) = descriptor.constraint {
            return range.min + ((range.max - range.min) * value)
        }
        return nil
    }
}

@SANEActor
protocol IRoiElement {
    func setValue(handle: SANEHandle, value: Double) throws
}

@SANEActor
fileprivate struct RoiElement<T: RoiSettable>: IRoiElement {
    let index: Int
    var descriptor: SANEOptionDescriptor

    func setValue(handle: SANEHandle, value: Double) throws {
        if var denormalized = T.denormalizeValue(value: value, descriptor: descriptor) {
            try saneControlOption(handle: handle, n: self.index, action: .setValue, value: &denormalized)
        }
    }
}

@SANEActor
struct RoiManager {
    
    var tlxElement: IRoiElement?
    var tlyElement: IRoiElement?
    var brxElement: IRoiElement?
    var bryElement: IRoiElement?
    
    nonisolated init() {
        
    }

    mutating func addOption(index: Int, descriptor: SANEOptionDescriptor) {
        switch descriptor.name {
        case SANEWellKnownOptions.tlX.rawValue:
            self.tlxElement = self.makeElement(index: index, descriptor: descriptor)
        case SANEWellKnownOptions.tlY.rawValue:
            self.tlyElement = self.makeElement(index: index, descriptor: descriptor)
        case SANEWellKnownOptions.brX.rawValue:
            self.brxElement = self.makeElement(index: index, descriptor: descriptor)
        case SANEWellKnownOptions.brY.rawValue:
            self.bryElement = self.makeElement(index: index, descriptor: descriptor)
        default: break
        }
    }
    
    func setRoi(handle: SANEHandle, roi: CGRect) throws {
        try self.tlxElement?.setValue(handle: handle, value: roi.minX)
        try self.tlyElement?.setValue(handle: handle, value: roi.minY)
        try self.brxElement?.setValue(handle: handle, value: roi.maxX)
        try self.bryElement?.setValue(handle: handle, value: roi.maxY)
    }
    
    var isValid: Bool {
        return tlxElement != nil &&
            tlyElement != nil &&
            brxElement != nil &&
            bryElement != nil
    }
    
    private func makeElement(index: Int, descriptor: SANEOptionDescriptor) -> IRoiElement? {
        switch descriptor.type {
        case .int: return RoiElement<Int>(index: index, descriptor: descriptor)
        case .fixed: return RoiElement<Double>(index: index, descriptor: descriptor)
        default: return nil
        }
    }
}
