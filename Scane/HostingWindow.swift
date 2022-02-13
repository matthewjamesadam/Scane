//
//  HostingWindow.swift
//  Scane
//
//  Created by Matt Adam on 2022-01-16.
//

import SwiftUI

// An environment that allows SwiftUI views to know which window they are hosted by

struct HostingWindow {
    
    private weak var _window: NSWindow?

    init(window: NSWindow) {
        self._window = window
    }

    var window: NSWindow? {
        return _window
    }
}

struct HostingWindowKey: EnvironmentKey {

    typealias Value = HostingWindow?
    static let defaultValue: Self.Value = nil
}

extension EnvironmentValues {
    var hostingWindow: HostingWindowKey.Value {
        get {
            return self[HostingWindowKey.self]
        }
        set {
            self[HostingWindowKey.self] = newValue
        }
    }
}
