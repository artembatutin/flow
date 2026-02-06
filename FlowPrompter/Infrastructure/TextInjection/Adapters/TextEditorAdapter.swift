//
//  TextEditorAdapter.swift
//  FlowPrompter
//
//  Created by Artem Batutin on 2026-01-28.
//

import Foundation
import AppKit

/// Adapter for text editors (Sublime Text, TextEdit, BBEdit, etc.)
final class TextEditorAdapter: TargetAdapter {
    
    // MARK: - TargetAdapter Properties
    
    let bundleIdentifiers: [String] = [
        "com.sublimetext.4",
        "com.sublimetext.3",
        "com.sublimetext.2",
        "com.apple.TextEdit",
        "com.barebones.bbedit",
        "com.coteditor.CotEditor",
        "com.macromates.TextMate",
        "com.macromates.TextMate.preview",
        "abnerworks.Typora",
        "com.electron.logseq",
        "md.obsidian",
        "com.apple.Notes"
    ]
    
    let displayName: String = "Text Editor"
    
    var priority: Int { 5 }
    
    var preferredMode: InjectionMode { .clipboardPaste }
    
    // MARK: - TargetAdapter Methods
    
    func inject(text: String, using injector: TextInjector) async throws -> InjectionResult {
        let preparedText = prepareText(text)
        return try await injector.inject(text: preparedText, mode: preferredMode)
    }
    
    func prepareText(_ text: String) -> String {
        // Text editors generally handle text as-is
        // No special preparation needed
        return text
    }
}
