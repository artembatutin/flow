//
//  TaskManager.swift
//  Flow
//
//  Created by Codex on 2026-04-22.
//

import Foundation
import Combine

@MainActor
class TaskManager: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []
    @Published private(set) var projects: [TaskProject] = []
    @Published private(set) var labels: [TaskLabel] = []
    @Published var filters: TaskFilterState = .default

    private let fileManager: FileManager
    private let customWorkspaceFileURL: URL?

    private var workspaceFileURL: URL {
        if let customWorkspaceFileURL {
            return customWorkspaceFileURL
        }
        return (try? AppSupportPaths.fileURL("task_workspace.json", fileManager: fileManager)) ??
            fileManager.temporaryDirectory.appendingPathComponent("task_workspace.json")
    }

    init(fileManager: FileManager = .default, workspaceFileURL: URL? = nil) {
        self.fileManager = fileManager
        self.customWorkspaceFileURL = workspaceFileURL
        loadWorkspace()
    }

    var activeProjects: [TaskProject] {
        projects
            .filter { !$0.isArchived }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var activeLabels: [TaskLabel] {
        labels
            .filter { !$0.isArchived }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func filteredTasks(using filter: TaskFilterState? = nil) -> [TaskItem] {
        let applied = filter ?? filters
        let trimmedSearch = applied.searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return tasks
            .filter { task in
                if let projectID = applied.selectedProjectID, task.projectID != projectID {
                    return false
                }
                if let labelID = applied.selectedLabelID, !task.labelIDs.contains(labelID) {
                    return false
                }
                if let status = applied.selectedStatus, task.status != status {
                    return false
                }
                if let priority = applied.selectedPriority, task.priority != priority {
                    return false
                }
                if trimmedSearch.isEmpty {
                    return true
                }

                let projectName = task.projectID.flatMap(projectName(for:))?.lowercased() ?? ""
                let labelNames = task.labelIDs.compactMap(labelName(for:)).joined(separator: " ").lowercased()
                let haystack = [
                    task.title.lowercased(),
                    task.notes?.lowercased() ?? "",
                    projectName,
                    labelNames
                ].joined(separator: " ")
                return haystack.contains(trimmedSearch)
            }
            .sorted(by: taskSort)
    }

    func createTask(
        title: String,
        notes: String? = nil,
        status: TaskStatus = .inbox,
        priority: TaskPriority = .medium,
        projectID: UUID? = nil,
        labelIDs: [UUID] = [],
        source: TaskSource = .manual,
        originalTranscript: String? = nil
    ) -> TaskItem {
        let timestamp = Date()
        let task = TaskItem(
            title: title,
            notes: notes?.nilIfBlank,
            status: status,
            priority: priority,
            projectID: projectID,
            labelIDs: labelIDs,
            source: source,
            createdAt: timestamp,
            updatedAt: timestamp,
            completedAt: status == .done ? timestamp : nil,
            originalTranscript: originalTranscript?.nilIfBlank
        )
        tasks.append(task)
        saveWorkspace()
        return task
    }

    func updateTask(_ task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        var updated = task
        updated.title = task.title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.notes = task.notes?.nilIfBlank
        updated.updatedAt = Date()
        if updated.status == .done {
            updated.completedAt = updated.completedAt ?? updated.updatedAt
        } else {
            updated.completedAt = nil
        }
        tasks[index] = updated
        saveWorkspace()
    }

    func updateTask(
        id: UUID,
        title: String? = nil,
        notes: String? = nil,
        status: TaskStatus? = nil,
        priority: TaskPriority? = nil,
        labelIDs: [UUID]? = nil
    ) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        var task = tasks[index]
        if let title {
            task.title = title
        }
        if let notes {
            task.notes = notes
        }
        if let status {
            task.status = status
        }
        if let priority {
            task.priority = priority
        }
        if let labelIDs {
            task.labelIDs = labelIDs
        }
        updateTask(task)
    }

    func setTaskProject(id: UUID, projectID: UUID?) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        var task = tasks[index]
        task.projectID = projectID
        updateTask(task)
    }

    func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        saveWorkspace()
    }

    func createProject(name: String) -> TaskProject? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard !projects.contains(where: { $0.name.compare(trimmed, options: .caseInsensitive) == .orderedSame }) else {
            return nil
        }

        let project = TaskProject(name: trimmed)
        projects.append(project)
        saveWorkspace()
        return project
    }

    func createLabel(name: String, colorToken: TaxonomyColorToken = .blue) -> TaskLabel? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard !labels.contains(where: { $0.name.compare(trimmed, options: .caseInsensitive) == .orderedSame }) else {
            return nil
        }

        let label = TaskLabel(name: trimmed, colorToken: colorToken)
        labels.append(label)
        saveWorkspace()
        return label
    }

    func updateProject(_ project: TaskProject) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        var updated = project
        updated.name = project.name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.updatedAt = Date()
        projects[index] = updated
        saveWorkspace()
    }

    func updateLabel(_ label: TaskLabel) {
        guard let index = labels.firstIndex(where: { $0.id == label.id }) else { return }
        var updated = label
        updated.name = label.name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.updatedAt = Date()
        labels[index] = updated
        saveWorkspace()
    }

    func archiveProject(_ project: TaskProject) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[index].isArchived = true
        projects[index].updatedAt = Date()
        for taskIndex in tasks.indices where tasks[taskIndex].projectID == project.id {
            tasks[taskIndex].projectID = nil
            tasks[taskIndex].updatedAt = Date()
        }
        if filters.selectedProjectID == project.id {
            filters.selectedProjectID = nil
        }
        saveWorkspace()
    }

    func archiveLabel(_ label: TaskLabel) {
        guard let index = labels.firstIndex(where: { $0.id == label.id }) else { return }
        labels[index].isArchived = true
        labels[index].updatedAt = Date()
        for taskIndex in tasks.indices where tasks[taskIndex].labelIDs.contains(label.id) {
            tasks[taskIndex].labelIDs.removeAll { $0 == label.id }
            tasks[taskIndex].updatedAt = Date()
        }
        if filters.selectedLabelID == label.id {
            filters.selectedLabelID = nil
        }
        saveWorkspace()
    }

    func projectName(for id: UUID) -> String? {
        projects.first(where: { $0.id == id })?.name
    }

    func labelName(for id: UUID) -> String? {
        labels.first(where: { $0.id == id })?.name
    }

    func label(for id: UUID) -> TaskLabel? {
        labels.first(where: { $0.id == id })
    }

    func visibleProject(for id: UUID?) -> TaskProject? {
        guard let id else { return nil }
        return activeProjects.first(where: { $0.id == id })
    }

    private func loadWorkspace() {
        guard fileManager.fileExists(atPath: workspaceFileURL.path) else { return }
        do {
            let data = try Data(contentsOf: workspaceFileURL)
            let decoder = JSONDecoder()
            let workspace = try decoder.decode(TaskWorkspaceStore.self, from: data)
            tasks = workspace.tasks
            projects = workspace.projects
            labels = workspace.labels
        } catch {
            print("Failed to load task workspace: \(error)")
        }
    }

    private func saveWorkspace() {
        let workspace = TaskWorkspaceStore(tasks: tasks, projects: projects, labels: labels)
        do {
            try fileManager.createDirectory(
                at: workspaceFileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(workspace)
            try data.write(to: workspaceFileURL, options: .atomic)
        } catch {
            print("Failed to save task workspace: \(error)")
        }
    }

    private func taskSort(lhs: TaskItem, rhs: TaskItem) -> Bool {
        if lhs.status == .done, rhs.status != .done {
            return false
        }
        if lhs.status != .done, rhs.status == .done {
            return true
        }
        if lhs.priority.sortRank != rhs.priority.sortRank {
            return lhs.priority.sortRank > rhs.priority.sortRank
        }
        return lhs.updatedAt > rhs.updatedAt
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
