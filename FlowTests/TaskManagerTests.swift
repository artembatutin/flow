import XCTest

@MainActor
final class TaskManagerTests: XCTestCase {
    func testTaskWorkspacePersistsAcrossReloads() throws {
        let workspaceURL = temporaryURL()
        let manager = TaskManager(workspaceFileURL: workspaceURL)
        let project = try XCTUnwrap(manager.createProject(name: "Operations"))
        let label = try XCTUnwrap(manager.createLabel(name: "Admin", colorToken: .amber))

        let task = manager.createTask(
            title: "Close the month-end checklist",
            status: .next,
            priority: .urgent,
            projectID: project.id,
            labelIDs: [label.id],
            source: .voiceTask,
            originalTranscript: "task operations admin urgent close the month-end checklist"
        )

        let reloaded = TaskManager(workspaceFileURL: workspaceURL)

        XCTAssertEqual(reloaded.tasks.count, 1)
        XCTAssertEqual(reloaded.projects.count, 1)
        XCTAssertEqual(reloaded.labels.count, 1)
        XCTAssertEqual(reloaded.tasks.first?.id, task.id)
        XCTAssertEqual(reloaded.tasks.first?.projectID, project.id)
        XCTAssertEqual(reloaded.tasks.first?.labelIDs, [label.id])
        XCTAssertEqual(reloaded.tasks.first?.source, .voiceTask)
    }

    func testFilteringCombinesSidebarAndToolbarFilters() throws {
        let manager = TaskManager(workspaceFileURL: temporaryURL())
        let engineering = try XCTUnwrap(manager.createProject(name: "Engineering"))
        let marketing = try XCTUnwrap(manager.createProject(name: "Marketing"))
        let urgent = try XCTUnwrap(manager.createLabel(name: "Urgent", colorToken: .coral))
        let writing = try XCTUnwrap(manager.createLabel(name: "Writing", colorToken: .blue))

        _ = manager.createTask(
            title: "Ship the onboarding update",
            status: .next,
            priority: .urgent,
            projectID: engineering.id,
            labelIDs: [urgent.id]
        )
        _ = manager.createTask(
            title: "Draft blog post outline",
            status: .inbox,
            priority: .medium,
            projectID: marketing.id,
            labelIDs: [writing.id]
        )

        let filtered = manager.filteredTasks(using: TaskFilterState(
            selectedProjectID: engineering.id,
            selectedLabelID: urgent.id,
            selectedStatus: .next,
            selectedPriority: .urgent,
            searchText: "onboarding"
        ))

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.title, "Ship the onboarding update")
    }

    private func temporaryURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("task_workspace.json")
    }
}
