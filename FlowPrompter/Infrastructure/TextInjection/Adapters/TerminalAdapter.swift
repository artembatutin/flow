//
//  TerminalAdapter.swift
//  FlowPrompter
//
//  Created by Artem Batutin on 2026-01-28.
//

import Foundation
import AppKit

/// Adapter for Terminal applications (Terminal.app, iTerm2)
final class TerminalAdapter: TargetAdapter {
    
    // MARK: - TargetAdapter Properties
    
    let bundleIdentifiers: [String] = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "io.alacritty",
        "com.github.wez.wezterm",
        "co.zeit.hyper",
        "net.kovidgoyal.kitty"
    ]
    
    let displayName: String = "Terminal"
    
    var priority: Int { 10 }
    
    var preferredMode: InjectionMode { .clipboardPaste }
    
    // MARK: - Configuration
    
    /// Whether to use bracketed paste mode for multiline text
    var useBracketedPaste: Bool = true
    
    /// Delay before paste in terminal (terminals may need slightly longer)
    var terminalPasteDelay: TimeInterval = 0.08
    
    // MARK: - TargetAdapter Methods
    
    func inject(text: String, using injector: TextInjector) async throws -> InjectionResult {
        let preparedText = prepareText(text)
        
        // Save original settings
        let originalDelay = injector.focusDelay
        injector.focusDelay = terminalPasteDelay
        
        defer {
            injector.focusDelay = originalDelay
        }
        
        return try await injector.inject(text: preparedText, mode: preferredMode)
    }
    
    func prepareText(_ text: String) -> String {
        // For terminals, we may want to handle multiline text specially
        // Bracketed paste mode helps prevent command execution on paste
        if useBracketedPaste && text.contains("\n") {
            // Most modern terminals support bracketed paste automatically
            // The terminal itself handles this, so we just return the text
            return text
        }
        return text
    }
    
    // MARK: - Terminal-Specific Methods
    
    /// Checks if the current terminal supports bracketed paste
    func supportsBracketedPaste(bundleId: String) -> Bool {
        // Most modern terminals support bracketed paste
        let supportedTerminals = [
            "com.googlecode.iterm2",
            "io.alacritty",
            "com.github.wez.wezterm",
            "net.kovidgoyal.kitty"
        ]
        return supportedTerminals.contains(bundleId)
    }
    
    /// Executes text as a command in the terminal using AppleScript (optional)
    func executeCommand(_ command: String, in terminal: String) async throws {
        let script: String
        
        switch terminal {
        case "com.apple.Terminal":
            script = """
            tell application "Terminal"
                do script "\(escapeForAppleScript(command))" in front window
            end tell
            """
        case "com.googlecode.iterm2":
            script = """
            tell application "iTerm"
                tell current session of current window
                    write text "\(escapeForAppleScript(command))"
                end tell
            end tell
            """
        default:
            return
        }
        
        try await runAppleScript(script)
    }
    
    // MARK: - Private Helpers
    
    private func escapeForAppleScript(_ text: String) -> String {
        text.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
    
    private func runAppleScript(_ script: String) async throws {
        let appleScript = NSAppleScript(source: script)
        var errorInfo: NSDictionary?
        appleScript?.executeAndReturnError(&errorInfo)
        
        if let error = errorInfo {
            throw NSError(
                domain: "TerminalAdapter",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: error.description]
            )
        }
    }
}
