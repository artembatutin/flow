//
//  DashboardWindowController.swift
//  Flow
//
//  Created by Codex on 2026-04-22.
//

import Cocoa
import SwiftUI

@MainActor
class DashboardWindowController {
    static let shared = DashboardWindowController()

    private var window: NSWindow?

    private init() {}

    func showWindow() {
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let dependencies = AppDependencies.shared
        let dashboardView = DashboardView()
            .environmentObject(dependencies.taskManager)
            .environmentObject(dependencies.sessionManager)
            .environmentObject(dependencies.textInjectionService)
            .environmentObject(dependencies.analyticsManager)

        let hostingController = NSHostingController(rootView: dashboardView)
        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = AppBranding.dashboardWindowTitle
        newWindow.identifier = NSUserInterfaceItemIdentifier("dashboard")
        newWindow.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        newWindow.setContentSize(NSSize(width: 1180, height: 760))
        newWindow.minSize = NSSize(width: 980, height: 640)
        newWindow.center()
        newWindow.setFrameAutosaveName("DashboardWindow")
        newWindow.isReleasedWhenClosed = false
        newWindow.toolbarStyle = .unified

        window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
