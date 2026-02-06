//
//  IDEAdapter.swift
//  FlowPrompter
//
//  Created by Artem Batutin on 2026-01-28.
//

import Foundation
import AppKit

/// Adapter for IDEs (VS Code, Windsurf, Xcode, JetBrains, etc.)
final class IDEAdapter: TargetAdapter {
    
    // MARK: - TargetAdapter Properties
    
    let bundleIdentifiers: [String] = [
        // VS Code variants
        "com.microsoft.VSCode",
        "com.microsoft.VSCodeInsiders",
        "com.visualstudio.code.oss",
        "com.todesktop.230313mzl4w4u92",  // Windsurf/Cursor
        "com.cursor.Cursor",
        
        // Xcode
        "com.apple.dt.Xcode",
        
        // JetBrains IDEs
        "com.jetbrains.intellij",
        "com.jetbrains.intellij.ce",
        "com.jetbrains.WebStorm",
        "com.jetbrains.PhpStorm",
        "com.jetbrains.pycharm",
        "com.jetbrains.pycharm.ce",
        "com.jetbrains.CLion",
        "com.jetbrains.AppCode",
        "com.jetbrains.goland",
        "com.jetbrains.rubymine",
        "com.jetbrains.rider",
        "com.jetbrains.datagrip",
        
        // Other IDEs
        "com.github.atom",
        "org.vim.MacVim",
        "com.panic.Nova",
        "com.panic.Coda2"
    ]
    
    let displayName: String = "IDE"
    
    var priority: Int { 15 }
    
    var preferredMode: InjectionMode { .clipboardPaste }
    
    // MARK: - Configuration
    
    /// Whether to preserve indentation when pasting
    var preserveIndentation: Bool = true
    
    /// Whether to add a trailing newline for code blocks
    var addTrailingNewline: Bool = false
    
    // MARK: - TargetAdapter Methods
    
    func inject(text: String, using injector: TextInjector) async throws -> InjectionResult {
        let preparedText = prepareText(text)
        return try await injector.inject(text: preparedText, mode: preferredMode)
    }
    
    func prepareText(_ text: String) -> String {
        var result = text
        
        // Optionally add trailing newline for code
        if addTrailingNewline && !result.hasSuffix("\n") {
            result += "\n"
        }
        
        return result
    }
    
    // MARK: - IDE-Specific Methods
    
    /// Checks if the IDE is a VS Code variant
    func isVSCodeVariant(bundleId: String) -> Bool {
        let vsCodeVariants = [
            "com.microsoft.VSCode",
            "com.microsoft.VSCodeInsiders",
            "com.visualstudio.code.oss",
            "com.todesktop.230313mzl4w4u92",
            "com.cursor.Cursor"
        ]
        return vsCodeVariants.contains(bundleId)
    }
    
    /// Checks if the IDE is Xcode
    func isXcode(bundleId: String) -> Bool {
        bundleId == "com.apple.dt.Xcode"
    }
    
    /// Checks if the IDE is a JetBrains product
    func isJetBrains(bundleId: String) -> Bool {
        bundleId.hasPrefix("com.jetbrains.")
    }
}
