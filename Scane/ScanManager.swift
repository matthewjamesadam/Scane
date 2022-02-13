//
//  ScanManager.swift
//  Scane
//
//  Created by Matt Adam on 2021-12-11.
//

import SwiftUI
import SaneKit

let SCAN_BUFFER_SIZE = 100000

private struct OptionTuple {
    let descriptor: SANEOptionDescriptor
    let index: Int
}

@MainActor
class ScanManager: ObservableObject {
    
    @Published var isLoading = false
    @Published var isScanning = false
    @Published var deviceInfo: SaneKit.SANEDevice?
    @Published var canPreview = false
    @Published var canSetRoi = false
    @Published var options = Array<IScanOption>()
    
    @Published var scanProgress: Double = 0

    @SANEActor
    private var handle: SANEHandle?
    
    private var previewOptionIdx: Int?

    private var resolutionOption: IScanOption?
    
    private var roi_ = CGRect(x: 0, y: 0, width: 1, height: 1)

    @SANEActor
    private var roiManager = RoiManager()
    
    init() {
    }
    
    func initDevice() async throws {
        
        self.isLoading = true;
        defer { self.isLoading = false }

        let (handle, device, options) = try await doInitDevice();
        
        var scanOptions: [IScanOption] = []

        var isInAdvancedGroup = false
        for option in options {
            let descriptor = option.descriptor
            
            // Skip advanced settings
            if descriptor.type == .group {
                isInAdvancedGroup = descriptor.cap.contains(.advanced)
            }
            
            if isInAdvancedGroup || descriptor.cap.contains(.advanced) {
                continue
            }
            
            if descriptor.name == SANEWellKnownOptions.preview.rawValue {
                canPreview = true
                previewOptionIdx = option.index
                continue
            }

            var scanOption: IScanOption?

            switch descriptor.type {
            case .bool:
                scanOption = ScanOption<Bool>(descriptor: descriptor, index: option.index, scanManager: self)

            case .int:
                scanOption = ScanOption<Int>(descriptor: descriptor, index: option.index, scanManager: self)

            case .fixed:
                scanOption = ScanOption<Double>(descriptor: descriptor, index: option.index, scanManager: self)

            case .string:
                scanOption = ScanOption<String>(descriptor: descriptor, index: option.index, scanManager: self)
            default: break
            }
            
            if let scanOption = scanOption {
                
                try await scanOption.update(handle: handle, updateDescriptor: false)
                
                scanOptions.append(scanOption)
                
                if descriptor.name == SANEWellKnownOptions.resolution.rawValue {
                    self.resolutionOption = scanOption
                }
            }
        }
        
        self.deviceInfo = device
        self.options = scanOptions
        self.canSetRoi = await roiManager.isValid
    }

    @SANEActor
    private func doInitDevice() throws -> (SANEHandle, SANEDevice?, [OptionTuple]) {
        
        var options = Array<OptionTuple>()
        
        _ = try saneInit();

        let handle: SANEHandle
        var device: SANEDevice? = nil

        if let theHandle = self.handle {
            handle = theHandle
        } else {
            let devices = try saneGetDevices(localOnly: true)
            
            if devices.isEmpty {
                throw ScaneError.noDevicesFound
            }
            
            device = devices.first
            handle = try saneOpen(name: devices.first?.name ?? "")
            self.handle = handle
        }

        var numParams = 0;
        try saneControlOption(handle: handle, n: 0, action: .getValue, value: &numParams)

        for i in 1..<numParams {
            let descriptor = try saneGetOptionDescriptor(handle: handle, n: i)
            options.append(OptionTuple(descriptor: descriptor, index: i))
            roiManager.addOption(index: i, descriptor: descriptor)
        }
        
        return (handle, device, options)
    }
    
    func setValue<T: ScanOptionValue>(index: Int, value: T) async {
        do {
            try await self.doSetValue(options: self.options, index: index, value: value)
        }
        catch {
            
        }
    }
    
    @SANEActor
    private func doSetValue<T: ScanOptionValue>(options: [IScanOption], index: Int, value: T) async throws {
        guard let handle = self.handle else {
            return;
        }

        var valueToSet = value
        let result = try saneControlOption(handle: handle, n: index, action: .setValue, value: &valueToSet)
        
        // Reload params if required
        if result.contains(.reloadParams) {

            for option in options {
                if option.index != index {
                    try await option.update(handle: handle, updateDescriptor: true)
                }
            }
        }
    }
    
    var roi: Binding<CGRect> {
        return Binding(
            get: { self.roi_},
            set: { newRoi in
                Task {
                    await self.updateRoi(newRoi: newRoi)
                }
            }
        )
    }
    
    private func updateRoi(newRoi: CGRect) async {
        self.objectWillChange.send()
        self.roi_ = newRoi

        Task { @SANEActor in
            if let handle = self.handle {
                do {
                    try self.roiManager.setRoi(handle: handle, roi: newRoi)
                }
                catch {}
            }
        }
    }
    
    func scan(preview: Bool) async throws -> CGImage {

        guard let handle = await self.handle else {
            throw ScaneError.failure;
        }
        
        self.scanProgress = 0
        self.isScanning = true
        defer { self.isScanning = false }

        // If we're doing a preview scan, reset our ROI
        if preview {
            await updateRoi(newRoi: CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0))
        }
        
        // If we support preview mode, set it now and reset resolution to lowest value
        var userSelectedResolution: SANEActionValue?

        if let previewIdx = self.previewOptionIdx {

            // Set preview mode
            var previewValue = preview
            try await saneControlOption(handle: handle, n: previewIdx, action: .setValue, value: &previewValue)
        }

        // For preview mode, set resolution to lowest available option
        if preview, let resolutionOption = self.resolutionOption {
            userSelectedResolution = resolutionOption.userSelectedValue

            if var resolutionValue = resolutionOption.minimumPossibleValue {
                try await resolutionValue.controlOption(handle: handle, index: resolutionOption.index, action: .setValue)
            }
        }

        let image = try await self.doScan(preview: preview)
        
        // Restore the user-selected original resolution value

        if let resolutionOption = self.resolutionOption, var resolutionValue = userSelectedResolution {
            try await resolutionValue.controlOption(handle: handle, index: resolutionOption.index, action: .setValue)
        }

        
        return image
    }
    
    @SANEActor
    private func doScan(preview: Bool) async throws -> CGImage {
        guard let handle = self.handle else {
            throw ScaneError.failure;
        }
        
        // Do the scan
        try saneStart(handle: handle)
        
        let params = try saneGetParameters(handle: handle)
        
        let memory = UnsafeMutableRawPointer.allocate(byteCount: SCAN_BUFFER_SIZE, alignment: 1)
        defer { memory.deallocate() }

        var done = false
        
        let imageBuffer = ImageBuffer(param: params)
        
        let expectedReadBytes = params.lines * params.bytesPerLine
        var readBytes = 0
        
        while !done {
            if let bytesRead = try saneRead(handle: handle, buf: memory, maxLen: SCAN_BUFFER_SIZE) {
                imageBuffer.addBytes(buffer: memory, length: bytesRead)
                
                readBytes += bytesRead
                let bytesToSet = readBytes

                Task { @MainActor in
                    self.scanProgress = Double(bytesToSet) / Double(expectedReadBytes)
                }
            }
            else {
                done = true
            }
        }
        
        try saneCancel(handle: handle)
        
        guard let image = imageBuffer.save() else {
            throw ScaneError.imageCreationFailed
        }

        return image
    }
}
