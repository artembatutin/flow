//
//  SharedTaskWorkspace.swift
//  Flow
//
//  Created by Codex on 2026-05-01.
//

import Foundation

enum SharedTaskWorkspace {
    nonisolated static let appGroupIdentifier = "group.quartzarts.Flow"
    nonisolated static let fileName = "task_workspace.json"
    nonisolated static let widgetKind = "FlowTasksWidget"

    nonisolated static func fileURL(fileManager: FileManager = .default) throws -> URL {
        if let sharedContainer = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            let directory = sharedContainer.appendingPathComponent("Tasks", isDirectory: true)
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

            let sharedFile = directory.appendingPathComponent(fileName)
            try reconcileLegacyWorkspaceIfNeeded(with: sharedFile, fileManager: fileManager)
            return sharedFile
        }

        return try legacyFileURL(fileManager: fileManager)
    }

    nonisolated static func load(fileManager: FileManager = .default) -> TaskWorkspaceStore {
        guard let url = try? fileURL(fileManager: fileManager),
              fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let workspace = try? JSONDecoder().decode(TaskWorkspaceStore.self, from: data)
        else {
            return TaskWorkspaceStore()
        }

        return workspace
    }

    nonisolated static func save(_ workspace: TaskWorkspaceStore, fileManager: FileManager = .default) throws {
        let url = try fileURL(fileManager: fileManager)
        try writeWorkspace(workspace, to: url, fileManager: fileManager)
    }

    private nonisolated static func reconcileLegacyWorkspaceIfNeeded(
        with sharedFile: URL,
        fileManager: FileManager
    ) throws {
        let legacyFile = try legacyFileURL(fileManager: fileManager)
        guard fileManager.fileExists(atPath: legacyFile.path) else { return }

        guard fileManager.fileExists(atPath: sharedFile.path) else {
            try fileManager.copyItem(at: legacyFile, to: sharedFile)
            return
        }

        guard let legacyWorkspace = readWorkspace(at: legacyFile),
              let sharedWorkspace = readWorkspace(at: sharedFile)
        else {
            return
        }

        let mergedWorkspace = merged(sharedWorkspace: sharedWorkspace, legacyWorkspace: legacyWorkspace)
        guard mergedWorkspace != sharedWorkspace else { return }

        try writeWorkspace(mergedWorkspace, to: sharedFile, fileManager: fileManager)
    }

    private nonisolated static func readWorkspace(at url: URL) -> TaskWorkspaceStore? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(TaskWorkspaceStore.self, from: data)
    }

    private nonisolated static func writeWorkspace(
        _ workspace: TaskWorkspaceStore,
        to url: URL,
        fileManager: FileManager
    ) throws {
        try fileManager.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(workspace)
        try data.write(to: url, options: .atomic)
    }

    private nonisolated static func merged(
        sharedWorkspace: TaskWorkspaceStore,
        legacyWorkspace: TaskWorkspaceStore
    ) -> TaskWorkspaceStore {
        var merged = sharedWorkspace
        merged.schemaVersion = max(sharedWorkspace.schemaVersion, legacyWorkspace.schemaVersion)
        merged.tasks = mergedItems(primary: sharedWorkspace.tasks, secondary: legacyWorkspace.tasks) { $0.updatedAt }
        merged.projects = mergedItems(primary: sharedWorkspace.projects, secondary: legacyWorkspace.projects) { $0.updatedAt }
        merged.labels = mergedItems(primary: sharedWorkspace.labels, secondary: legacyWorkspace.labels) { $0.updatedAt }
        return merged
    }

    private nonisolated static func mergedItems<Item: Identifiable>(
        primary: [Item],
        secondary: [Item],
        updatedAt: (Item) -> Date
    ) -> [Item] where Item.ID == UUID {
        var items = primary

        for legacyItem in secondary {
            if let index = items.firstIndex(where: { $0.id == legacyItem.id }) {
                if updatedAt(legacyItem) > updatedAt(items[index]) {
                    items[index] = legacyItem
                }
            } else {
                items.append(legacyItem)
            }
        }

        return items
    }

    private nonisolated static func legacyFileURL(fileManager: FileManager) throws -> URL {
        let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let flowDirectory = applicationSupport.appendingPathComponent("Flow", isDirectory: true)

        if !fileManager.fileExists(atPath: flowDirectory.path) {
            try fileManager.createDirectory(at: flowDirectory, withIntermediateDirectories: true)
        }

        return flowDirectory.appendingPathComponent(fileName)
    }
}
