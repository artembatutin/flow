//
//  ClaudeCodeAdapter.swift
//  FlowPrompter
//
//  Created by Artem Batutin on 2026-01-28.
//

import Foundation
import AppKit

/// Adapter for Claude Code terminal sessions
/// Claude Code runs within terminal applications, so we detect it by window title or context
final class ClaudeCodeAdapter: TargetAdapter {
    
    // MARK: - TargetAdapter Properties
    
    /// Claude Code runs in terminals, so we check for terminal bundle IDs
    /// but with additional context detection
    let bundleIdentifiers: [String] = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "io.alacritty",
        "com.github.wez.wezterm",
        "co.zeit.hyper",
        "net.kovidgoyal.kitty"
    ]
    
    let displayName: String = "Claude Code"
    
    var priority: Int { 20 }  // Higher than terminal adapter
    
    var preferredMode: InjectionMode { .clipboardPaste }
    
    // MARK: - Configuration
    
    /// Keywords to detect Claude Code sessions in window titles
    private let claudeCodeIndicators: [String] = [
        "claude",
        "Claude",
        "CLAUDE",
        "claude-code",
        "anthropic"
    ]
    
    /// Whether command mode is enabled (for special Claude commands)
    var commandModeEnabled: Bool = true
    
    /// Command prefixes that trigger special handling
    private let commandPrefixes: [String] = [
        "/",
        "!",
        "@"
    ]
    
    // MARK: - TargetAdapter Methods
    
    func canHandle(bundleId: String) -> Bool {
        // First check if it's a terminal
        guard bundleIdentifiers.contains(bundleId) else {
            return false
        }
        
        // Then check if it appears to be a Claude Code session
        return isClaudeCodeSession()
    }
    
    func isActive() -> Bool {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
              let bundleId = frontmostApp.bundleIdentifier else {
            return false
        }
        return canHandle(bundleId: bundleId)
    }
    
    func inject(text: String, using injector: TextInjector) async throws -> InjectionResult {
        let preparedText = prepareText(text)
        
        // Use clipboard paste for Claude Code (most reliable)
        return try await injector.inject(text: preparedText, mode: .clipboardPaste)
    }
    
    func prepareText(_ text: String) -> String {
        var result = text
        
        // Handle command mode if enabled
        if commandModeEnabled {
            result = processCommands(result)
        }
        
        return result
    }
    
    // MARK: - Claude Code Detection
    
    /// Attempts to detect if the current terminal session is Claude Code
    private func isClaudeCodeSession() -> Bool {
        // Try to get the window title of the frontmost application
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return false
        }
        
        // Check window titles using Accessibility API
        let appElement = AXUIElementCreateApplication(frontmostApp.processIdentifier)
        
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)
        
        guard result == .success, let windows = windowsRef as? [AXUIElement] else {
            return false
        }
        
        for window in windows {
            var titleRef: CFTypeRef?
            let titleResult = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
            
            if titleResult == .success, let title = titleRef as? String {
                for indicator in claudeCodeIndicators {
                    if title.contains(indicator) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    // MARK: - Command Processing
    
    /// Processes special commands in the text
    private func processCommands(_ text: String) -> String {
        // Check if text starts with a command prefix
        for prefix in commandPrefixes {
            if text.hasPrefix(prefix) {
                // This is a command - pass through as-is
                return text
            }
        }
        
        return text
    }
    
    // MARK: - Claude Code Specific Methods
    
    /// Sends a command to Claude Code
    func sendCommand(_ command: String, using injector: TextInjector) async throws -> InjectionResult {
        let commandText = command.hasPrefix("/") ? command : "/\(command)"
        return try await injector.inject(text: commandText + "\n", mode: .clipboardPaste)
    }
    
    /// Sends a multi-turn message (useful for long prompts)
    func sendMultilineMessage(_ message: String, using injector: TextInjector) async throws -> InjectionResult {
        // For multiline messages, we use clipboard paste
        // Claude Code handles multiline input well
        return try await injector.inject(text: message, mode: .clipboardPaste)
    }
}
