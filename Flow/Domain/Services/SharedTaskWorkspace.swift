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
    nonisolated private static let widgetPageKeyPrefix = "widget.task-page"

    nonisolated static func fileURL(fileManager: FileManager = .default) throws -> URL {
        if let sharedContainer = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            let sharedFile = sharedFileURL(in: sharedContainer)
            try fileManager.createDirectory(
                at: sharedFile.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try reconcileLegacyWorkspaceIfNeeded(with: sharedFile, fileManager: fileManager)
            return sharedFile
        }

        if let groupContainersFile = fallbackGroupContainersFileURL(fileManager: fileManager),
           fileManager.fileExists(atPath: groupContainersFile.path) {
            try fileManager.createDirectory(
                at: groupContainersFile.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            return groupContainersFile
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

    nonisolated static func widgetTaskPageIndex(for familyIdentifier: String) -> Int {
        let key = widgetTaskPageKey(for: familyIdentifier)
        return max(widgetDefaults.integer(forKey: key), 0)
    }

    @discardableResult
    nonisolated static func clampWidgetTaskPageIndex(pageCount: Int, for familyIdentifier: String) -> Int {
        let currentPage = widgetTaskPageIndex(for: familyIdentifier)
        let clampedPage = min(currentPage, max(pageCount - 1, 0))

        if clampedPage != currentPage {
            setWidgetTaskPageIndex(clampedPage, for: familyIdentifier)
        }

        return clampedPage
    }

    nonisolated static func setWidgetTaskPageIndex(_ pageIndex: Int, for familyIdentifier: String) {
        let key = widgetTaskPageKey(for: familyIdentifier)
        widgetDefaults.set(max(pageIndex, 0), forKey: key)
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

    private nonisolated static var widgetDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }

    private nonisolated static func widgetTaskPageKey(for familyIdentifier: String) -> String {
        "\(widgetPageKeyPrefix).\(familyIdentifier)"
    }

    private nonisolated static func sharedFileURL(in sharedContainer: URL) -> URL {
        sharedContainer
            .appendingPathComponent("Tasks", isDirectory: true)
            .appendingPathComponent(fileName)
    }

    private nonisolated static func fallbackGroupContainersFileURL(fileManager: FileManager) -> URL? {
        let homeDirectory = unsandboxedHomeDirectory(from: fileManager.homeDirectoryForCurrentUser)
        return homeDirectory?
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Group Containers", isDirectory: true)
            .appendingPathComponent(appGroupIdentifier, isDirectory: true)
            .appendingPathComponent("Tasks", isDirectory: true)
            .appendingPathComponent(fileName)
    }

    private nonisolated static func unsandboxedHomeDirectory(from homeDirectory: URL) -> URL? {
        let standardized = homeDirectory.standardizedFileURL
        let components = standardized.pathComponents

        if let libraryIndex = components.firstIndex(of: "Library"),
           components.indices.contains(libraryIndex + 3),
           components[libraryIndex + 1] == "Containers",
           components[libraryIndex + 3] == "Data" {
            return URL(fileURLWithPath: components.prefix(libraryIndex).joined(separator: "/"), isDirectory: true)
        }

        return standardized
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
