//
//  AppDelegate.swift
//  Flow
//
//  Created by Artem Batutin on 2026-01-27.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock - app runs as menu bar only
        NSApp.setActivationPolicy(.accessory)
        
        // Start hotkey listening after a short delay to ensure permissions are checked
        Task { @MainActor in
            // Load the selected model
            await AppDependencies.shared.loadSelectedModel()
            
            // Start listening for hotkeys if permissions are granted
            AppDependencies.shared.startHotkeyListening()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Stop hotkey listening
        Task { @MainActor in
            AppDependencies.shared.stopHotkeyListening()
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running even when all windows are closed (menu bar app)
        return false
    }
}
