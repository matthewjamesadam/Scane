//
//  File.swift
//  Scane
//
//  Created by Matt Adam on 2022-02-12.
//

import Foundation
import SwiftUI
import SaneKit

struct ErrorDefinition: Identifiable {
    let id: String
    
    let error: Error
    let context: String
    
    init(_ error: Error, _ context: String) {
        self.error = error
        self.context = context
        self.id = UUID().uuidString
    }
    
    func toAlert() -> Alert {
        return error.toAlert(context: context)
    }
}

extension Error {
    func toAlert(context: String) -> Alert {
        return Alert(title: Text(context), message: Text(self.localizedDescription))
    }
}

enum ScaneError: LocalizedError {
    case noDevicesFound
    case failure
    case imageCreationFailed
    
    public var errorDescription: String? {
        switch self {
        case .noDevicesFound:
            return "Could not find any connected scanners"
            
        case .failure:
            return "An unexpected error occurred"
            
        case .imageCreationFailed:
            return "Could not create an image from the scanner data"
        }
    }
}
