//
//  ImageBuffer.swift
//  Scane
//
//  Created by Matt Adam on 2021-12-19.
//

import SaneKit
import Foundation
import AppKit

extension SANEFrame {
    var expectedFrames: Int {
        switch self {
        case .gray, .rgb:
            return 1
        case .red, .green, .blue:
            return 3
        }
    }
    
    var bytesPerSample: Int {
        switch self {
        case .rgb:
            return 4
        case .red, .green, .blue, .gray:
            return 1
        }
    }
}

class ImageBuffer {
    
    private var scanBuffer: UnsafeMutablePointer<UInt8>
    private var scanCurrent: UnsafeMutablePointer<UInt8>
    private var scanWrite: UnsafeMutablePointer<UInt8>

    private var imageBuffer: UnsafeMutablePointer<UInt8>
    private var imageCurrent: UnsafeMutablePointer<UInt8>

    private var param: SANEParameters

    init(param: SANEParameters) {
        self.param = param

        let imageBytesPerSample = param.format.bytesPerSample * param.depth / 8
        
        scanBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: param.bytesPerLine * param.lines)
        scanCurrent = scanBuffer
        scanWrite = scanBuffer
        
        imageBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: param.pixelsPerLine * param.lines * imageBytesPerSample)
        imageCurrent = imageBuffer
    }

    func addBytes(buffer: UnsafeMutableRawPointer, length: Int) {
        let byteBuffer = buffer.bindMemory(to: UInt8.self, capacity: length)

        // Copy into scan buffer
        scanWrite.update(from: byteBuffer, count: length)
        scanWrite += length
        
        // Process a line repeatedly, while we have enough data for a line
        while scanCurrent.distance(to: scanWrite) >= param.bytesPerLine {

            // RGB line: copy pixel-by-pixel, padding additional alpha value
            if param.format == .rgb {
                
                // Write alpha values
                imageCurrent.update(repeating: 255, count: param.pixelsPerLine * param.depth / 2)
                
                // Write each pixel
                var scanPixel = scanCurrent
                for _ in 0..<param.pixelsPerLine {
                    imageCurrent.update(from: scanPixel, count: 3 * param.depth / 8)
                    imageCurrent += (4 * param.depth / 8)
                    scanPixel += (3 * param.depth / 8)
                }
            }
            
            // Grey/red/green/blue line: copy all pixels in one go
            else {
                let toCopy = param.pixelsPerLine * param.depth / 8
                imageCurrent.update(from: scanCurrent, count: toCopy)
                imageCurrent += toCopy
            }
            
            scanCurrent += param.bytesPerLine
        }
    }
    
    func save() -> CGImage? {
        
        let memory = UnsafeMutableRawPointer(self.imageBuffer)
        
        let bytesPerRow = param.format == .rgb ?
            (param.pixelsPerLine * param.depth / 2) :
            (param.pixelsPerLine * param.depth / 8)

        let space = param.format == .gray ?
            CGColorSpaceCreateDeviceGray() :
            CGColorSpaceCreateDeviceRGB()

        var imageInfo = param.format == .rgb ?
            CGImageAlphaInfo.noneSkipLast.rawValue :
            CGImageAlphaInfo.none.rawValue
        
        if param.depth == 16 {
            imageInfo |= CGImageByteOrderInfo.order16Little.rawValue
        }

        if let context = CGContext.init(
            data: memory,
            width: param.pixelsPerLine,
            height: param.lines,
            bitsPerComponent: param.depth,
            bytesPerRow: bytesPerRow,
            space: space,
            bitmapInfo: imageInfo) {
            return context.makeImage()
        }

        return nil
    }

    deinit {
        scanBuffer.deallocate()
        imageBuffer.deallocate()
    }
}
