//
//  MainMenu.swift
//  Scane
//
//  Created by Matt Adam on 2022-01-29.
//

import Foundation
import AppKit

extension NSMenuItem {
    convenience init(title string: String, action selector: Selector?, keyEquivalent charCode: String, keyMask: NSEvent.ModifierFlags) {
        self.init(title: string, action: selector, keyEquivalent: charCode)
        self.keyEquivalentModifierMask = keyMask
    }
}

extension ScaneAppDelegate {
    
    func createMainMenu() {
        
        let app = NSApplication.shared

        let servicesMenu = NSMenu()
        let servicesMenuItem = NSMenuItem(title: "Services", action: nil, keyEquivalent: "")
        servicesMenuItem.submenu = servicesMenu
        
        let appMenu = NSMenuItem();
        appMenu.submenu = NSMenu(title: "App")
        appMenu.submenu?.items = [
            NSMenuItem(title: "About Scane", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""),
            NSMenuItem.separator(),
            servicesMenuItem,
            NSMenuItem.separator(),
            NSMenuItem(title: "Hide Scane", action: #selector(app.hide(_:)), keyEquivalent: "h"),
            NSMenuItem(title: "Hide Others", action: #selector(app.hideOtherApplications(_:)), keyEquivalent: "h", keyMask: [.option, .command]),
            NSMenuItem(title: "Show All", action: #selector(app.unhideAllApplications(_:)), keyEquivalent: ""),
            NSMenuItem.separator(),
            NSMenuItem(title: "Quit", action: #selector(app.terminate(_:)), keyEquivalent: "q")
        ]

        let editMenu = NSMenuItem();
        editMenu.submenu = NSMenu(title: "Edit")
        editMenu.submenu?.items = [
            NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z"),
            NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z"),
            NSMenuItem.separator(),
            NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"),
            NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"),
            NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"),
            NSMenuItem.separator(),
            NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        ]

        let viewMenu = NSMenuItem();
        viewMenu.submenu = NSMenu(title: "View")
        viewMenu.submenu?.items = [
            NSMenuItem(title: "Enter Full Screen", action: #selector(app.keyWindow?.toggleFullScreen(_:)), keyEquivalent: "f", keyMask: [.option, .command])
        ]

        let windowMenu = NSMenuItem();
        let windowSubMenu = NSMenu(title: "Window")
        windowMenu.submenu = windowSubMenu
        windowSubMenu.items = [
            NSMenuItem(title: "Minimize", action: #selector(app.keyWindow?.miniaturize(_:)), keyEquivalent: "m"),
            NSMenuItem(title: "Zoom", action: #selector(app.keyWindow?.zoom(_:)), keyEquivalent: ""),
            NSMenuItem.separator(),
            NSMenuItem(title: "Bring All to Front", action: #selector(app.arrangeInFront(_:)), keyEquivalent: ""),
            NSMenuItem.separator()
        ]

        let mainMenu = NSMenu();
        mainMenu.items = [
            appMenu,
            editMenu,
            viewMenu,
            windowMenu
        ]
        
        app.mainMenu = mainMenu
        app.servicesMenu = servicesMenu
        app.windowsMenu = windowSubMenu
    }
}
