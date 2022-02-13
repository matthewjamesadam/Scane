//
//  ViewExtensions.swift
//  Scane
//
//  Created by Matt Adam on 2022-01-29.
//

import SwiftUI
import Combine

/*
 Polyfill for View.onChange on MacOS 10
 Cheers to @jegnux https://gist.github.com/jegnux/c3aee7957f6c372bf31a46c893a6e2a2
 */
public struct ChangeObserver<V: Equatable>: ViewModifier {
    public init(newValue: V, action: @escaping (V) -> Void) {
        self.newValue = newValue
        self.newAction = action
    }

    private typealias Action = (V) -> Void

    private let newValue: V
    private let newAction: Action

    @State private var state: (V, Action)?

    public func body(content: Content) -> some View {
        if #available(macOS 11, *) {
            assertionFailure()
        }
        return content
            .onAppear()
            .onReceive(Just(newValue)) { newValue in
                if let (currentValue, action) = state, newValue != currentValue {
                    action(newValue)
                }
                state = (newValue, newAction)
            }
    }
}

extension View {
    @_disfavoredOverload
    @ViewBuilder public func onChange<V>(of value: V, perform action: @escaping (V) -> Void) -> some View where V: Equatable {
        if #available(macOS 11, *) {
            onChange(of: value, perform: action)
        } else {
            modifier(ChangeObserver(newValue: value, action: action))
        }
    }
}
