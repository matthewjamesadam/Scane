//
//  ScaneApp.swift
//  Scane
//
//  Created by Matt Adam on 2021-11-29.
//

import SwiftUI
import SaneKit

class ScaneAppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        createMainMenu()
        
        // Create the window and set the content view.
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            content: MainView())
        
        window.title = "Scane"
        window.tabbingMode = .disallowed
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("Scane")
        window.makeKeyAndOrderFront(nil)
        
        self.window = window
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true;
    }
}

@main
struct ScaneAppEntryPoint {
    static func main() {
        let appDelegate = ScaneAppDelegate()
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)

        app.delegate = appDelegate
        app.activate(ignoringOtherApps: true)
        app.run()
    }
}


/*
    To be used if we drop support for OS < 11

 @main
struct ScaneApp: App {
    
    var body: some Scene {
        WindowGroup {
            ScaneAppView()
        }
        .commands {
            CommandGroup(replacing: .newItem, addition: {})
        }
    }
}
*/
