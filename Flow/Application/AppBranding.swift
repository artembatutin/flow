//
//  AppBranding.swift
//  Flow
//
//  Created by Artem Batutin on 2026-01-27.
//

import Foundation

enum AppBranding {
    nonisolated static let displayName = "Flow"
    nonisolated static let legacyDisplayName = "FlowPrompter"
    nonisolated static let bundleIdentifier = "quartzarts.Flow"
    nonisolated static let onboardingWindowTitle = "Welcome to Flow"
    nonisolated static let dashboardWindowTitle = "Flow Dashboard"
    nonisolated static let settingsWindowTitle = "Flow Settings"
    nonisolated static let historyExportFileName = "Flow_History"
    nonisolated static let dictionaryExportFileName = "flow-dictionary.json"
    nonisolated static let snippetsExportFileName = "flow-snippets.json"
}

enum AppSupportPaths {
    private nonisolated static let currentDirectoryName = AppBranding.displayName
    private nonisolated static let legacyDirectoryName = AppBranding.legacyDisplayName

    nonisolated static func appSupportDirectory(fileManager: FileManager = .default) throws -> URL {
        let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let currentDirectory = applicationSupport.appendingPathComponent(currentDirectoryName, isDirectory: true)
        let legacyDirectory = applicationSupport.appendingPathComponent(legacyDirectoryName, isDirectory: true)

        if !fileManager.fileExists(atPath: currentDirectory.path),
           fileManager.fileExists(atPath: legacyDirectory.path) {
            try fileManager.moveItem(at: legacyDirectory, to: currentDirectory)
        }

        if !fileManager.fileExists(atPath: currentDirectory.path) {
            try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        }

        return currentDirectory
    }

    nonisolated static func fileURL(_ fileName: String, fileManager: FileManager = .default) throws -> URL {
        try appSupportDirectory(fileManager: fileManager).appendingPathComponent(fileName)
    }

    nonisolated static func modelsDirectory(fileManager: FileManager = .default) throws -> URL {
        let directory = try appSupportDirectory(fileManager: fileManager)
            .appendingPathComponent("Models", isDirectory: true)

        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        return directory
    }
}
