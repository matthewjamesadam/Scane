//
//  Sane.swift
//  SaneKit
//
//  Created by Matt Adam on 2021-12-02.
//

import Foundation
import libsane

// A nicer Swift wrapper for the C Sane API (https://sane-project.gitlab.io/standard/)
// This tries to stay as close as possible to the C API for easy translation and understanding,
// while presenting Swift-friendly types.

public enum SANEError: LocalizedError {
    case status(statusCode: Int)
    case failure
    case invalidConversion
    
    init(with status: SANE_Status) {
        self = .status(statusCode: Int(status.rawValue))
    }
    
    public var errorDescription: String? {
        switch self {
        case .status(let statusCode):
            if let string = errorStringMap[statusCode] {
                return string
            }
            return "SANE status code \(statusCode)"
        
        case .failure:
            return "An unexpected failure occurred"
            
        case .invalidConversion:
            return "An unexpected value was returned from SANE"
        }
    }
}

// Static dictionary mapping error strings
// We do this on initialization so it happens on the right thread
private var errorStringMap = Dictionary<Int, String>()

public struct SANEDevice {
    public let name: String
    public let vendor: String
    public let model: String
    public let type: String
    
    init(from saneDevice: libsane.SANE_Device) {
        name = String(cString: saneDevice.name)
        vendor = String(cString: saneDevice.vendor)
        model = String(cString: saneDevice.model)
        type = String(cString: saneDevice.type)
    }
}

public enum SANEValueType {
    case bool
    case int
    case fixed
    case string
    case button
    case group
    
    init(from type: libsane.SANE_Value_Type) throws {
        switch type {
        case libsane.SANE_TYPE_BOOL:
            self = .bool
        case libsane.SANE_TYPE_INT:
            self = .int
        case libsane.SANE_TYPE_FIXED:
            self = .fixed
        case libsane.SANE_TYPE_STRING:
            self = .string
        case libsane.SANE_TYPE_BUTTON:
            self = .button
        case libsane.SANE_TYPE_GROUP:
            self = .group
        default:
            throw SANEError.invalidConversion
        }
    }
}

public enum SANEUnit {
    case none
    case pixel
    case bit
    case mm
    case dpi
    case percent
    case microsecond
    
    init(from unit: libsane.SANE_Unit) throws {
        switch unit {
        case libsane.SANE_UNIT_NONE:
            self = .none
        case libsane.SANE_UNIT_PIXEL:
            self = .none
        case libsane.SANE_UNIT_BIT:
            self = .bit
        case libsane.SANE_UNIT_MM:
            self = .mm
        case libsane.SANE_UNIT_DPI:
            self = .dpi
        case libsane.SANE_UNIT_PERCENT:
            self = .percent
        case libsane.SANE_UNIT_MICROSECOND:
            self = .microsecond
        default:
            throw SANEError.invalidConversion
        }
    }
}

public struct SANECap: OptionSet {
    public let rawValue: Int
    
    public static let softSelect = SANECap(rawValue: 1)
    public static let hardSelect = SANECap(rawValue: 2)
    public static let softDetect = SANECap(rawValue: 4)
    public static let emulated = SANECap(rawValue: 8)
    public static let automatic = SANECap(rawValue: 16)
    public static let inactive = SANECap(rawValue: 32)
    public static let advanced = SANECap(rawValue: 64)

    public var isActive: Bool {
        return !self.contains(.inactive)
    }
    
    public var isSettable: Bool {
        return !self.contains(.softSelect)
    }
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

private protocol SANEWordConvertible {
    init(from saneValue: libsane.SANE_Word)
    var asSaneFixed: libsane.SANE_Word { get }
}

public struct SANERange<T> {
    public let min: T
    public let max: T
    public let quant: T?

    public init(min: T, max: T, quant: T?) {
        self.min = min
        self.max = max
        self.quant = quant
    }
}

extension SANERange where T: SANEWordConvertible {
    init(from range: SANE_Range) {
        self.min = T(from: range.min)
        self.max = T(from: range.max)
        self.quant = range.quant == 0 ? nil : T(from: range.quant)
    }
}

extension Int: SANEWordConvertible {
    init(from saneValue: libsane.SANE_Word) {
        self = Int(saneValue)
    }
    
    var asSaneFixed: libsane.SANE_Word {
        get {
            return SANE_Word(self)
        }
    }
}

extension Double: SANEWordConvertible {
    init(from saneValue: libsane.SANE_Word) {
        self = (Double(saneValue) / Double((Int(1) << Int(SANE_FIXED_SCALE_SHIFT))))
    }

    init(from saneInt: Int) {
        self = (Double(saneInt) / Double((Int(1) << Int(SANE_FIXED_SCALE_SHIFT))))
    }

    var asSaneInt: Int {
        return Int(((self) * Double(1 << SANE_FIXED_SCALE_SHIFT)))
    }

    var asSaneFixed: libsane.SANE_Word {
        get {
            return SANE_Word(self.asSaneInt)
        }
    }
}

private func convertWordList<T: SANEWordConvertible>(listPtr: UnsafePointer<SANE_Word>) -> [T] {
    let numItems = Int(listPtr.pointee)
    var currentItemPtr = listPtr

    var values = [T]()
    for _ in 0..<numItems {
        currentItemPtr = currentItemPtr + 1
        values.append(T(from: currentItemPtr.pointee))
    }
    
    return values
}

private func convertStringList(listPtr: UnsafePointer<SANE_String_Const?>) -> [String] {
    var currentPtr = listPtr
    var values = [String]()
    while let currentValue = currentPtr.pointee {
        values.append(String(cString: currentValue))
        currentPtr = currentPtr + 1
    }
    
    return values
}

public enum SANEConstraint {
    case none
    case intRange(range: SANERange<Int>)
    case fixedRange(range: SANERange<Double>)
    case intList(list: [Int])
    case fixedList(list: [Double])
    case stringList(list: [String])
    
    init(
        from constraintType: libsane.SANE_Constraint_Type,
        with constraint: SANE_Option_Descriptor.__Unnamed_union_constraint,
        with valueType: libsane.SANE_Value_Type) throws {
        switch constraintType {
        case SANE_CONSTRAINT_NONE:
            self = .none
        
        case SANE_CONSTRAINT_RANGE:
            switch valueType {
            case SANE_TYPE_INT:
                self = .intRange(range: SANERange<Int>(from: constraint.range.pointee))
            case SANE_TYPE_FIXED:
                self = .fixedRange(range: SANERange<Double>(from: constraint.range.pointee))
            default:
                throw SANEError.invalidConversion
            }

        case SANE_CONSTRAINT_WORD_LIST:
            switch valueType {
            case SANE_TYPE_INT:
                self = .intList(list: convertWordList(listPtr: constraint.word_list))
            case SANE_TYPE_FIXED:
                self = .fixedList(list: convertWordList(listPtr: constraint.word_list))
            default:
                throw SANEError.invalidConversion
            }
            
        case SANE_CONSTRAINT_STRING_LIST:
            self = .stringList(list: convertStringList(listPtr: constraint.string_list))
            
        default:
            throw SANEError.invalidConversion
        }
    }
}

public struct SANEOptionDescriptor {
    
    public let name: String
    public let title: String
    public let desc: String
    public let type: SANEValueType
    public let unit: SANEUnit
    public let size: Int
    public let cap: SANECap
    public let constraint: SANEConstraint

    init(from saneDescriptor: libsane.SANE_Option_Descriptor) throws {
        self.name = String(cString: saneDescriptor.name)
        self.title = String(cString: saneDescriptor.title)
        self.desc = String(cString: saneDescriptor.desc)
        self.type = try SANEValueType(from: saneDescriptor.type)
        self.unit = try SANEUnit(from: saneDescriptor.unit)
        self.size = Int(saneDescriptor.size)
        self.cap = SANECap(rawValue: Int(saneDescriptor.cap))
        self.constraint = try SANEConstraint(from: saneDescriptor.constraint_type, with: saneDescriptor.constraint, with: saneDescriptor.type)
    }

    public init(name: String, title: String, desc: String, type: SANEValueType, unit: SANEUnit, size: Int, cap: SANECap, constraint: SANEConstraint) {
        self.name = name
        self.title = title
        self.desc = desc
        self.type = type
        self.unit = unit
        self.size = size
        self.cap = cap
        self.constraint = constraint
    }
}

public enum SANEAction: UInt32 {
    case getValue = 0
    case setValue = 1
    case setAuto = 2

    var toSaneAction: libsane.SANE_Action {
        return libsane.SANE_Action(rawValue: self.rawValue)
    }
}

public struct SANEInfo: OptionSet {
    public let rawValue: Int
    
    public static let inexact = SANEInfo(rawValue: 1)
    public static let reloadOptions = SANEInfo(rawValue: 2)
    public static let reloadParams = SANEInfo(rawValue: 4)
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public typealias SANEAuthCallback = (_: String, _: String, _: String) -> Void

public struct SANEHandle {
    let handle: libsane.SANE_Handle
}

public typealias SANEActionValueCb = (UnsafeMutableRawPointer) throws -> Void

public protocol SANEActionValue {
    init()
    mutating func withRawPtr(cb: SANEActionValueCb) throws
}

extension String: SANEActionValue {
    public mutating func withRawPtr(cb: SANEActionValueCb) throws {

        self = try self.withCString() { ptr in
            let rawPtr = UnsafeMutableRawPointer(mutating: ptr)
            try cb(rawPtr)
            let returnValue = String(cString: ptr)
            return returnValue
        }
    }
}

extension Int: SANEActionValue {
    public mutating func withRawPtr(cb: SANEActionValueCb) throws {
        try withUnsafeMutableBytes(of: &self) { ptr in
            if let rawPtr = UnsafeMutableRawPointer(mutating: ptr.baseAddress) {
                try cb(rawPtr)
            }
        }
    }
}

extension Double: SANEActionValue {
    public mutating func withRawPtr(cb: SANEActionValueCb) throws {
        var wordValue = self.asSaneFixed
        try withUnsafeMutableBytes(of: &wordValue) { ptr in
            if let rawPtr = UnsafeMutableRawPointer(mutating: ptr.baseAddress) {
                try cb(rawPtr)
            }
        }
    }
}

extension Bool: SANEActionValue {
    public mutating func withRawPtr(cb: (UnsafeMutableRawPointer) throws -> Void) throws {
        var intValue = self ? 1 : 0
        
        try withUnsafeMutableBytes(of: &intValue) { ptr in
            if let rawPtr = UnsafeMutableRawPointer(mutating: ptr.baseAddress) {
                try cb(rawPtr)
            }
        }
        
        self = (intValue > 0)
    }
}

public enum SANEFrame {
    case gray
    case rgb
    case red
    case green
    case blue

    init(from frame: SANE_Frame) throws {
        switch frame {
        case SANE_FRAME_GRAY:
            self = .gray
        case SANE_FRAME_RGB:
            self = .rgb
        case SANE_FRAME_RED:
            self = .red
        case SANE_FRAME_GREEN:
            self = .green
        case SANE_FRAME_BLUE:
            self = .blue
        default:
            throw SANEError.invalidConversion
        }
    }
    
}

public struct SANEParameters {
    public let format: SANEFrame
    public let lastFrame: Bool
    public let bytesPerLine: Int
    public let pixelsPerLine: Int
    public let lines: Int
    public let depth: Int
    
    init(from params: SANE_Parameters) throws {
        self.format = try SANEFrame(from: params.format)
        self.lastFrame = params.last_frame > 0
        self.bytesPerLine = Int(params.bytes_per_line)
        self.pixelsPerLine = Int(params.pixels_per_line)
        self.lines = Int(params.lines)
        self.depth = Int(params.depth)
    }
}

public enum SANEWellKnownOptions: String {
    case resolution = "resolution"
    case preview = "preview"
    case tlX = "tl-x"
    case tlY = "tl-y"
    case brX = "br-x"
    case brY = "br-y"
}

// Actor to put SANE operations on a single thread
@globalActor
public struct SANEActor
{
    public actor ActorType { }
    public static let shared: ActorType = ActorType()
}

private class NullClass {} // Just used for bundle identification

@SANEActor
public func saneInit() throws -> Int {

    let bundle = Bundle(for: NullClass.self)
    let frameworkUrl = bundle.bundleURL
        .appendingPathComponent("Versions", isDirectory: true)
        .appendingPathComponent("Current", isDirectory: true)
        .appendingPathComponent("Frameworks", isDirectory: true)
        .appendingPathComponent("sane", isDirectory: true)

    let configUrl = bundle.bundleURL
        .appendingPathComponent("Resources", isDirectory: true)
        .appendingPathComponent("sane.d", isDirectory: true)

    setenv("SANE_CONFIG_DIR", configUrl.path, 1)
    setenv("LD_LIBRARY_PATH", frameworkUrl.path, 1)
    
    let version = UnsafeMutablePointer<SANE_Int>.allocate(capacity: 1)
    defer { version.deallocate() }
    
    let status = libsane.sane_init(version) { resource, user, pw in
        // TODO: Add auth
    }
    
    if status != SANE_STATUS_GOOD {
        throw SANEError(with: status)
    }

    errorStringMap[Int(libsane.SANE_STATUS_GOOD.rawValue)] = saneStrStatus(status: libsane.SANE_STATUS_GOOD)
    errorStringMap[Int(libsane.SANE_STATUS_UNSUPPORTED.rawValue)] = saneStrStatus(status: libsane.SANE_STATUS_UNSUPPORTED)
    errorStringMap[Int(libsane.SANE_STATUS_CANCELLED.rawValue)] = saneStrStatus(status: libsane.SANE_STATUS_CANCELLED)
    errorStringMap[Int(libsane.SANE_STATUS_DEVICE_BUSY.rawValue)] = saneStrStatus(status: libsane.SANE_STATUS_DEVICE_BUSY)
    errorStringMap[Int(libsane.SANE_STATUS_INVAL.rawValue)] = saneStrStatus(status: libsane.SANE_STATUS_INVAL)
    errorStringMap[Int(libsane.SANE_STATUS_EOF.rawValue)] = saneStrStatus(status: libsane.SANE_STATUS_EOF)
    errorStringMap[Int(libsane.SANE_STATUS_JAMMED.rawValue)] = saneStrStatus(status: libsane.SANE_STATUS_JAMMED)
    errorStringMap[Int(libsane.SANE_STATUS_NO_DOCS.rawValue)] = saneStrStatus(status: libsane.SANE_STATUS_NO_DOCS)
    errorStringMap[Int(libsane.SANE_STATUS_COVER_OPEN.rawValue)] = saneStrStatus(status: libsane.SANE_STATUS_COVER_OPEN)
    errorStringMap[Int(libsane.SANE_STATUS_IO_ERROR.rawValue)] = saneStrStatus(status: libsane.SANE_STATUS_IO_ERROR)
    errorStringMap[Int(libsane.SANE_STATUS_NO_MEM.rawValue)] = saneStrStatus(status: libsane.SANE_STATUS_NO_MEM)
    errorStringMap[Int(libsane.SANE_STATUS_ACCESS_DENIED.rawValue)] = saneStrStatus(status: libsane.SANE_STATUS_ACCESS_DENIED)

    return Int(version.pointee)
}

@SANEActor
public func saneExit() {
    libsane.sane_exit()
}

@SANEActor
public func saneGetDevices(localOnly: Bool) throws -> [SANEDevice] {
    
    let saneDeviceArrayPtr = UnsafeMutablePointer<UnsafeMutablePointer<UnsafePointer<libsane.SANE_Device>?>?>.allocate(capacity: 1)
    defer { saneDeviceArrayPtr.deallocate() }

    let status = libsane.sane_get_devices(saneDeviceArrayPtr, localOnly ? SANE_TRUE : SANE_FALSE);

    if status != SANE_STATUS_GOOD {
        throw SANEError(with: status)
    }

    var devices = [SANEDevice]();
    var currentSaneDevicePtr = saneDeviceArrayPtr.pointee
    while let currentSaneDevice = currentSaneDevicePtr, let saneDevice = currentSaneDevice.pointee?.pointee {
        devices.append(SANEDevice(from: saneDevice))
        currentSaneDevicePtr = currentSaneDevice + 1
    }
    
    return devices
}

@SANEActor
public func saneOpen(name: String) throws -> SANEHandle {
    let handlePtr = UnsafeMutablePointer<libsane.SANE_Handle?>.allocate(capacity: 1)
    defer { handlePtr.deallocate() }
    
    let status = libsane.sane_open(name.cString(using: .ascii), handlePtr)
    
    if status != SANE_STATUS_GOOD {
        throw SANEError(with: status)
    }
    
    guard let handle = handlePtr.pointee else {
        throw SANEError.failure
    }
    
    return SANEHandle(handle: handle)
}

@SANEActor
public func saneClose(handle: SANEHandle) {
    libsane.sane_close(handle.handle)
}

@SANEActor
public func saneGetOptionDescriptor(handle: SANEHandle, n: Int) throws -> SANEOptionDescriptor {
    let saneDescriptor = libsane.sane_get_option_descriptor(handle.handle, SANE_Int(n)).pointee
    return try SANEOptionDescriptor(from: saneDescriptor)
}

@SANEActor
@discardableResult
public func saneControlOption<T: SANEActionValue>(handle: SANEHandle, n: Int, action: SANEAction, value: inout T) throws -> SANEInfo {
    var returnValue = SANEInfo()

    try value.withRawPtr() { rawPtr in
        
        let infoPtr = UnsafeMutablePointer<SANE_Int>.allocate(capacity: 1)
        defer { infoPtr.deallocate() }
        
        let result = libsane.sane_control_option(handle.handle, libsane.SANE_Int(n), action.toSaneAction, rawPtr, infoPtr);
        if result != libsane.SANE_STATUS_GOOD {
            throw SANEError(with: result)
        }

        returnValue = SANEInfo(rawValue: Int(infoPtr.pointee))
    }
    
    return returnValue
}

@SANEActor
public func saneGetParameters(handle: SANEHandle) throws -> SANEParameters {
    
    let ptr = UnsafeMutablePointer<SANE_Parameters>.allocate(capacity: 1)
    defer { ptr.deallocate() }
    
    let result = libsane.sane_get_parameters(handle.handle, ptr)
    if result != libsane.SANE_STATUS_GOOD {
        throw SANEError(with: result)
    }

    return try SANEParameters(from: ptr.pointee)
}

@SANEActor
public func saneStart(handle: SANEHandle) throws {
    let result = libsane.sane_start(handle.handle)
    if result != libsane.SANE_STATUS_GOOD {
        throw SANEError(with: result)
    }
}

@SANEActor
public func saneRead(handle: SANEHandle, buf: UnsafeMutableRawPointer, maxLen: Int) throws -> Int? {
    let ptr = buf.bindMemory(to: libsane.SANE_Byte.self, capacity: maxLen)

    let length = UnsafeMutablePointer<SANE_Int>.allocate(capacity: 1)
    defer { length.deallocate() }
    
    let result = libsane.sane_read(handle.handle, ptr, SANE_Int(maxLen), length)
    if result == libsane.SANE_STATUS_EOF {
        return nil
    }

    if result != libsane.SANE_STATUS_GOOD {
        throw SANEError(with: result)
    }

    return Int(length.pointee)
}

// Note: Deliberately no @SANEActor here, as this call is thread-safe
public func saneCancel(handle: SANEHandle) throws {
    libsane.sane_cancel(handle.handle)
}

@SANEActor
public func saneSetIoMode(handle: SANEHandle, m: Bool) throws {
    let result = libsane.sane_set_io_mode(handle.handle, m ? SANE_TRUE : SANE_FALSE)
    if result != libsane.SANE_STATUS_GOOD {
        throw SANEError(with: result)
    }
}

// We don't publish this, error strings are published in the thrown Error object
@SANEActor
func saneStrStatus(status: libsane.SANE_Status) -> String {
    return String(cString: libsane.sane_strstatus(status))
}
