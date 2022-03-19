//
//  ScanOption.swift
//  Scane
//
//  Created by Matt Adam on 2022-01-20.
//

import SwiftUI
import SaneKit


protocol ScanOptionValue: SANEActionValue, Equatable {
    static func createValue(with descriptor: SANEOptionDescriptor) -> Self
    static func getOptions(for descriptor: SANEOptionDescriptor) -> [Self]?
}

extension ScanOptionValue {
    static func createValue(with descriptor: SANEOptionDescriptor) -> Self {
        return Self()
    }
    static func getOptions(for descriptor: SANEOptionDescriptor) -> [Self]? { [] }
}

extension SANEActionValue {
    @SANEActor
    mutating func controlOption(handle: SANEHandle, index: Int, action: SANEAction) throws {
        try saneControlOption(handle: handle, n: index, action: action, value: &self)
    }
}

extension Bool: ScanOptionValue {}

extension Int: ScanOptionValue {
    static func getOptions(for descriptor: SANEOptionDescriptor) -> [Self]? {
        if case .intList(let list) = descriptor.constraint {
            return list
        }
        return nil
    }
}

extension Double: ScanOptionValue {
    static func getOptions(for descriptor: SANEOptionDescriptor) -> [Self]? {
        if case .fixedList(let list) = descriptor.constraint {
            return list
        }
        return nil
    }
}

extension String: ScanOptionValue {
    static func createValue(with descriptor: SANEOptionDescriptor) -> Self {
        return String(repeating: " ", count: descriptor.size + 1)
    }

    static func getOptions(for descriptor: SANEOptionDescriptor) -> [Self]? {
        if case .stringList(let list) = descriptor.constraint {
            return list
        }
        return nil
    }
}

// Normally this would be a protocol, but it must be a class in order to implement ObservableObject
@MainActor
class IScanOption: ObservableObject {
    let name: String
    let index: Int
    var isActive: Bool { true }

    func update(handle: SANEHandle, updateDescriptor: Bool) async throws {}

    var userSelectedValue: SANEActionValue { 0 }
    var minimumPossibleValue: SANEActionValue? { nil }
    
    fileprivate init(name: String, index: Int) {
        self.name =  name
        self.index = index
    }
}

@MainActor
class ScanOption<T: ScanOptionValue>: IScanOption {
    
    @Published var title: String
    @Published var options: [T]?

    var value: Binding<T> {
        Binding<T>(
            get: {
                self.value_
            },
            set: { newValue in
                self.objectWillChange.send()
                self.value_ = newValue
                
                Task {
                    await self.scanManager?.setValue(index: self.index, value: newValue)
                }
            }
        )
    }

    var type: SANEValueType { descriptor.type }
    override var isActive: Bool { descriptor.cap.isActive }

    fileprivate var descriptor: SANEOptionDescriptor
    private var value_: T
    private weak var scanManager: ScanManager?

    init(descriptor: SANEOptionDescriptor, index: Int, scanManager: ScanManager, initialVale: T = T()) {
        self.descriptor = descriptor
        self.title = descriptor.title
        self.options = T.getOptions(for: descriptor)
        self.value_ = initialVale
        self.scanManager = scanManager
        super.init(name: descriptor.name, index: index)
    }
    
    override var userSelectedValue: SANEActionValue {
        return self.value_
    }
    
    override var minimumPossibleValue: SANEActionValue? {
        switch self.descriptor.constraint {
        case .intRange(range: let range):
            return range.min
        case .fixedRange(range: let range):
            return range.min
        case .intList(list: let list):
            return list.min()
        case .fixedList(list: let list):
            return list.min()
        case .stringList(list: let list):
            return list.min()
        default:
            return nil
        }
    }

    override func update(handle: SANEHandle, updateDescriptor: Bool) async throws {
        let descriptor = updateDescriptor ? self.descriptor : try await saneGetOptionDescriptor(handle: handle, n: index)
        var newValue = T()
        
        if descriptor.cap.isActive {
            newValue = T.createValue(with: descriptor)
            try await saneControlOption(handle: handle, n: index, action: .getValue, value: &newValue)
        }
        
        // active
        if descriptor.cap.isActive != self.descriptor.cap.isActive || newValue != self.value_ {
            self.objectWillChange.send()
            self.value_ = newValue
            self.descriptor = descriptor
        }
    }
}

