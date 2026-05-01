//
//  DashboardView.swift
//  Flow
//
//  Created by Codex on 2026-04-22.
//

import SwiftUI

enum DashboardSection: String, CaseIterable, Identifiable {
    case tasks = "Tasks"
    case dictation = "Dictation"
    case history = "History"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .tasks:
            return "checklist"
        case .dictation:
            return "waveform.badge.mic"
        case .history:
            return "clock.arrow.circlepath"
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject var dashboardNavigation: DashboardNavigation
    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var textInjectionService: TextInjectionService
    @EnvironmentObject var analyticsManager: AnalyticsManager

    private var openTasks: Int {
        taskManager.tasks.filter { $0.status != .done }.count
    }

    private var weeklyTotals: (sessions: Int, words: Int, timeSaved: TimeInterval) {
        analyticsManager.getTotals(for: .week)
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 228)

            Divider()

            mainContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(DashboardMetrics.contentPadding)
        }
        .background(DashboardPalette.background)
        .frame(minWidth: 1120, minHeight: 760)
        .tint(DashboardPalette.accentBlue)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Flow Dashboard")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(DashboardPalette.textPrimary)

                Text("Workspace")
                    .font(.caption)
                    .foregroundStyle(DashboardPalette.textSecondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("WORKSPACE")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(DashboardPalette.textMuted)

                ForEach(DashboardSection.allCases) { item in
                    DashboardSidebarRow(
                        title: item.rawValue,
                        icon: item.icon,
                        selected: dashboardNavigation.section == item
                    ) {
                        dashboardNavigation.section = item
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("THIS WEEK")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(DashboardPalette.textMuted)

                DashboardStatBadge(title: "Open", value: "\(openTasks)", accent: DashboardPalette.accentBlue)
                DashboardStatBadge(title: "Sessions", value: "\(weeklyTotals.sessions)", accent: DashboardPalette.accentCyan)
                DashboardStatBadge(title: "Saved", value: formatTimeSaved(weeklyTotals.timeSaved), accent: DashboardPalette.accentAmber)
            }

            Spacer(minLength: 0)
        }
        .padding(DashboardMetrics.sidebarPadding)
        .background(DashboardPalette.sidebarBackground)
    }

    @ViewBuilder
    private var mainContent: some View {
        switch dashboardNavigation.section {
        case .tasks:
            TasksWorkspaceView()
                .environmentObject(taskManager)
                .environmentObject(dashboardNavigation)
        case .dictation:
            UsageDashboardView(analyticsManager: analyticsManager)
        case .history:
            HistoryView()
                .environmentObject(sessionManager)
                .environmentObject(textInjectionService)
        }
    }

    private func formatTimeSaved(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        if minutes > 0 {
            return "\(minutes)m"
        }
        return "<1m"
    }
}

private struct TasksWorkspaceView: View {
    @EnvironmentObject var dashboardNavigation: DashboardNavigation
    @EnvironmentObject var taskManager: TaskManager

    @State private var selectedProjectID: UUID?
    @State private var showingNewTaskSheet = false
    @State private var showingTaxonomySheet = false

    var body: some View {
        let filteredTasks = taskManager.filteredTasks()

        ScrollView {
            content(filteredTasks: filteredTasks)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showingNewTaskSheet) {
            NewTaskSheet()
                .environmentObject(taskManager)
        }
        .sheet(isPresented: $showingTaxonomySheet) {
            TaskTaxonomySheet()
                .environmentObject(taskManager)
        }
        .onAppear {
            syncSelection()
            presentNewTaskIfRequested()
        }
        .onChange(of: selectedProjectID) { _, _ in
            syncSelection()
        }
        .onChange(of: dashboardNavigation.newTaskRequestID) { _, _ in
            presentNewTaskIfRequested()
        }
    }

    private func content(filteredTasks: [TaskItem]) -> some View {
        VStack(alignment: .leading, spacing: DashboardMetrics.sectionSpacing) {
            header
            primaryControlBar(filteredTasks: filteredTasks)
            secondaryFilterBar
            taskList(filteredTasks: filteredTasks)
        }
        .padding(.bottom, 8)
    }

    private var header: some View {
        DashboardSectionHeader(
            title: "Tasks",
            subtitle: "Review and route captured work."
        ) {
            HStack(spacing: 8) {
                Button("Manage Taxonomy") {
                    showingTaxonomySheet = true
                }
                .buttonStyle(.bordered)

                Button("New Task") {
                    showingNewTaskSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func primaryControlBar(filteredTasks: [TaskItem]) -> some View {
        let completedTasks = filteredTasks.filter { $0.status == .done }.count
        let highPriorityTasks = filteredTasks.filter { $0.priority == .high || $0.priority == .urgent }.count
        let voiceTasks = filteredTasks.filter { $0.source == .voiceTask }.count

        return DashboardToolbar {
            HStack(alignment: .bottom, spacing: DashboardMetrics.controlGap) {
                DashboardInlinePickerField(title: "Scope", width: 180) {
                    Picker("Scope", selection: $selectedProjectID) {
                        Text("All Tasks").tag(Optional<UUID>.none)
                        ForEach(taskManager.activeProjects) { project in
                            Text(project.name).tag(Optional(project.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                DashboardSearchField(
                    title: "Search",
                    placeholder: "Search titles, notes, projects, labels",
                    text: searchBinding
                )
                .frame(maxWidth: .infinity)

                HStack(spacing: 8) {
                    DashboardStatBadge(title: "Open", value: "\(filteredTasks.count)", accent: DashboardPalette.accentBlue)
                        .frame(width: 84)
                    DashboardStatBadge(title: "High", value: "\(highPriorityTasks)", accent: DashboardPalette.accentRose)
                        .frame(width: 84)
                    DashboardStatBadge(title: "Voice", value: "\(voiceTasks)", accent: DashboardPalette.accentAmber)
                        .frame(width: 84)
                    DashboardStatBadge(title: "Done", value: "\(completedTasks)", accent: DashboardPalette.accentGreen)
                        .frame(width: 84)
                }
                .frame(width: 360)
            }
        }
    }

    private var secondaryFilterBar: some View {
        DashboardToolbar {
            HStack(alignment: .bottom, spacing: DashboardMetrics.controlGap) {
                DashboardInlinePickerField(title: "Status", width: 146) {
                    Picker("Status", selection: statusFilterBinding) {
                        Text("All Statuses").tag(Optional<TaskStatus>.none)
                        ForEach(TaskStatus.allCases) { status in
                            Text(status.displayName).tag(Optional(status))
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                DashboardInlinePickerField(title: "Priority", width: 146) {
                    Picker("Priority", selection: priorityFilterBinding) {
                        Text("All Priorities").tag(Optional<TaskPriority>.none)
                        ForEach(TaskPriority.allCases) { priority in
                            Text(priority.displayName).tag(Optional(priority))
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                DashboardInlinePickerField(title: "Label", width: 160) {
                    Picker("Label", selection: labelFilterBinding) {
                        Text("All Labels").tag(Optional<UUID>.none)
                        ForEach(taskManager.activeLabels) { label in
                            Text(label.name).tag(Optional(label.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                Spacer(minLength: 0)

                if filtersActive {
                    Button("Reset Filters") {
                        taskManager.filters = TaskFilterState(selectedProjectID: selectedProjectID)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(DashboardPalette.accentBlue)
                }
            }
        }
    }

    private func taskList(filteredTasks: [TaskItem]) -> some View {
        DashboardSurface(padding: 0, radius: DashboardMetrics.surfaceRadius) {
            VStack(spacing: 0) {
                taskTableHeader
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)

                Divider()

                if filteredTasks.isEmpty {
                    emptyTasksView
                        .padding(.horizontal, 24)
                        .padding(.vertical, 44)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(filteredTasks.enumerated()), id: \.element.id) { index, task in
                            TaskTableRow(task: task)
                                .environmentObject(taskManager)

                            if index < filteredTasks.index(before: filteredTasks.endIndex) {
                                Divider()
                                    .padding(.leading, 12)
                            }
                        }
                    }
                }
            }
        }
    }

    private var taskTableHeader: some View {
        HStack(spacing: 12) {
            Text("Title")
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Status")
                .frame(width: 104, alignment: .leading)

            Text("Priority")
                .frame(width: 104, alignment: .leading)

            Text("Project")
                .frame(width: 132, alignment: .leading)

            Text("Labels")
                .frame(width: 150, alignment: .leading)

            Text("Updated")
                .frame(width: 80, alignment: .leading)

            Text("")
                .frame(width: DashboardMetrics.minHitArea)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(DashboardPalette.textSecondary)
    }

    private var emptyTasksView: some View {
        VStack(spacing: 10) {
            Text("No tasks in scope")
                .font(.headline)
                .foregroundStyle(DashboardPalette.textPrimary)

            Text("Create a task manually or capture one with a voice command starting with \"task\".")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(DashboardPalette.textSecondary)
                .frame(maxWidth: 420)

            Button("Create Task") {
                showingNewTaskSheet = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }

    private var filtersActive: Bool {
        let filters = taskManager.filters
        return filters.selectedLabelID != nil ||
            filters.selectedStatus != nil ||
            filters.selectedPriority != nil ||
            !filters.searchText.isEmpty
    }

    private var labelFilterBinding: Binding<UUID?> {
        Binding(
            get: { taskManager.filters.selectedLabelID },
            set: { taskManager.filters.selectedLabelID = $0 }
        )
    }

    private var statusFilterBinding: Binding<TaskStatus?> {
        Binding(
            get: { taskManager.filters.selectedStatus },
            set: { taskManager.filters.selectedStatus = $0 }
        )
    }

    private var priorityFilterBinding: Binding<TaskPriority?> {
        Binding(
            get: { taskManager.filters.selectedPriority },
            set: { taskManager.filters.selectedPriority = $0 }
        )
    }

    private var searchBinding: Binding<String> {
        Binding(
            get: { taskManager.filters.searchText },
            set: { taskManager.filters.searchText = $0 }
        )
    }

    private func syncSelection() {
        taskManager.filters.selectedProjectID = selectedProjectID
    }

    private func presentNewTaskIfRequested() {
        guard dashboardNavigation.newTaskRequestID != nil else { return }
        showingNewTaskSheet = true
        dashboardNavigation.consumeNewTaskRequest()
    }
}

private struct TaskTableRow: View {
    @EnvironmentObject var taskManager: TaskManager

    let task: TaskItem
    @State private var showingLabelsPopover = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            titleColumn(for: task)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

            inlinePicker(width: 104) {
                Picker("", selection: Binding(
                    get: { task.status },
                    set: { taskManager.updateTask(id: task.id, status: $0) }
                )) {
                    ForEach(TaskStatus.allCases) { status in
                        Text(status.displayName).tag(status)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            inlinePicker(width: 104) {
                Picker("", selection: Binding(
                    get: { task.priority },
                    set: { taskManager.updateTask(id: task.id, priority: $0) }
                )) {
                    ForEach(TaskPriority.allCases) { priority in
                        Text(priority.displayName).tag(priority)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            inlinePicker(width: 132) {
                Picker("", selection: Binding(
                    get: { task.projectID },
                    set: { taskManager.setTaskProject(id: task.id, projectID: $0) }
                )) {
                    Text("No Project").tag(Optional<UUID>.none)
                    ForEach(taskManager.activeProjects) { project in
                        Text(project.name).tag(Optional(project.id))
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            labelsColumn(for: task)
                .frame(width: 150, alignment: .leading)

            Text(relativeDate(task.updatedAt))
                .font(.caption2)
                .foregroundStyle(DashboardPalette.textSecondary)
                .frame(width: 80, alignment: .leading)

            DashboardIconActionButton(systemName: "trash", role: .destructive) {
                taskManager.deleteTask(task)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(minHeight: 72, alignment: .topLeading)
    }

    private func titleColumn(for task: TaskItem) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            TextField(
                "Task title",
                text: Binding(
                    get: { task.title },
                    set: { taskManager.updateTask(id: task.id, title: $0) }
                ),
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(DashboardPalette.textPrimary)
            .lineLimit(3)
            .multilineTextAlignment(.leading)
            .help(task.title)

            HStack(spacing: 6) {
                TextField(
                    "Add note",
                    text: Binding(
                        get: { task.notes ?? "" },
                        set: { taskManager.updateTask(id: task.id, notes: $0) }
                    ),
                    axis: .vertical
                )
                .textFieldStyle(.plain)
                .font(.caption2)
                .foregroundStyle(DashboardPalette.textSecondary)
                .lineLimit(2)

                if task.source == .voiceTask {
                    DashboardMetaBadge(text: "Voice", tint: DashboardPalette.accentAmber, compact: true)
                }
            }
        }
    }

    private func inlinePicker<Content: View>(width: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        DashboardControlSurface {
            content()
        }
        .frame(width: width)
    }

    private func labelsColumn(for task: TaskItem) -> some View {
        let labels = task.labelIDs.compactMap(taskManager.label(for:))
        let visibleLabels = Array(labels.prefix(2))
        let remainingCount = max(0, labels.count - visibleLabels.count)

        return Button {
            showingLabelsPopover = true
        } label: {
            DashboardControlSurface(padding: 10) {
                HStack(spacing: 6) {
                    if visibleLabels.isEmpty {
                        Text("No labels")
                            .font(.caption2)
                            .foregroundStyle(DashboardPalette.textSecondary)
                    } else {
                        HStack(spacing: 4) {
                            ForEach(visibleLabels) { label in
                                DashboardMetaBadge(text: label.name, tint: label.colorToken.color, compact: true)
                            }

                            if remainingCount > 0 {
                                DashboardMetaBadge(text: "+\(remainingCount)", tint: DashboardPalette.textSecondary, compact: true)
                            }
                        }
                        .lineLimit(1)
                    }

                    Spacer(minLength: 4)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(DashboardPalette.textMuted)
                }
            }
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingLabelsPopover, arrowEdge: .top) {
            TaskLabelSelectionPopover(
                labels: taskManager.activeLabels,
                selectedLabelIDs: task.labelIDs,
                toggleLabel: { labelID in
                    toggleLabel(labelID, on: task)
                }
            )
        }
    }

    private func toggleLabel(_ labelID: UUID, on task: TaskItem) {
        var labelIDs = task.labelIDs
        if let index = labelIDs.firstIndex(of: labelID) {
            labelIDs.remove(at: index)
        } else {
            labelIDs.append(labelID)
        }
        taskManager.updateTask(id: task.id, labelIDs: labelIDs)
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

private struct TaskLabelSelectionPopover: View {
    let labels: [TaskLabel]
    let selectedLabelIDs: [UUID]
    let toggleLabel: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Labels")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DashboardPalette.textSecondary)

            if labels.isEmpty {
                Text("No labels available")
                    .font(.caption)
                    .foregroundStyle(DashboardPalette.textMuted)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(labels) { label in
                            Button {
                                toggleLabel(label.id)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: selectedLabelIDs.contains(label.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedLabelIDs.contains(label.id) ? DashboardPalette.accentBlue : DashboardPalette.textMuted)

                                    Circle()
                                        .fill(label.colorToken.color)
                                        .frame(width: 8, height: 8)

                                    Text(label.name)
                                        .font(.caption)
                                        .foregroundStyle(DashboardPalette.textPrimary)

                                    Spacer(minLength: 0)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(selectedLabelIDs.contains(label.id) ? DashboardPalette.surfaceTertiary.opacity(0.42) : Color.clear)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 180)
            }
        }
        .padding(12)
        .frame(width: 220)
    }
}

private struct NewTaskSheet: View {
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var notes = ""
    @State private var status: TaskStatus = .todo
    @State private var priority: TaskPriority = .medium
    @State private var projectID: UUID?
    @State private var labelIDs: Set<UUID> = []

    var body: some View {
        ZStack {
            DashboardSceneBackground()

            DashboardPanel {
                VStack(alignment: .leading, spacing: 18) {
                    DashboardSectionHeader(
                        title: "New Task",
                        subtitle: "Capture work with enough context to route it immediately."
                    )

                    TextField("Task title", text: $title)
                        .textFieldStyle(.roundedBorder)

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                        .textFieldStyle(.roundedBorder)

                    HStack(spacing: 12) {
                        Picker("Status", selection: $status) {
                            ForEach(TaskStatus.allCases) { status in
                                Text(status.displayName).tag(status)
                            }
                        }

                        Picker("Priority", selection: $priority) {
                            ForEach(TaskPriority.allCases) { priority in
                                Text(priority.displayName).tag(priority)
                            }
                        }
                    }

                    Picker("Project", selection: $projectID) {
                        Text("No Project").tag(Optional<UUID>.none)
                        ForEach(taskManager.activeProjects) { project in
                            Text(project.name).tag(Optional(project.id))
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Labels")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(DashboardPalette.textSecondary)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], spacing: 8) {
                            ForEach(taskManager.activeLabels) { label in
                                Button {
                                    if labelIDs.contains(label.id) {
                                        labelIDs.remove(label.id)
                                    } else {
                                        labelIDs.insert(label.id)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: labelIDs.contains(label.id) ? "checkmark.circle.fill" : "circle")
                                        Text(label.name)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(label.colorToken.color.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Spacer(minLength: 0)

                    HStack {
                        Spacer()

                        Button("Cancel") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)

                        Button("Create Task") {
                            _ = taskManager.createTask(
                                title: title,
                                notes: notes,
                                status: status,
                                priority: priority,
                                projectID: projectID,
                                labelIDs: Array(labelIDs).sorted { $0.uuidString < $1.uuidString }
                            )
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .padding(24)
        }
        .frame(width: 560, height: 520)
    }
}

private struct TaskTaxonomySheet: View {
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.dismiss) private var dismiss

    @State private var newProjectName = ""
    @State private var newLabelName = ""
    @State private var newLabelColor: TaxonomyColorToken = .blue

    var body: some View {
        ZStack {
            DashboardSceneBackground()

            DashboardPanel {
                VStack(alignment: .leading, spacing: 18) {
                    DashboardSectionHeader(
                        title: "Projects & Labels",
                        subtitle: "Shape the routing system behind task capture."
                    ) {
                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    HStack(alignment: .top, spacing: 16) {
                        projectsColumn
                        labelsColumn
                    }
                }
            }
            .padding(24)
        }
        .frame(width: 820, height: 560)
    }

    private var projectsColumn: some View {
        DashboardSurface(padding: 14, radius: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Projects")
                    .font(.headline)
                    .foregroundStyle(DashboardPalette.textPrimary)

                HStack(spacing: 8) {
                    TextField("New project", text: $newProjectName)
                        .textFieldStyle(.roundedBorder)

                    Button("Add") {
                        if taskManager.createProject(name: newProjectName) != nil {
                            newProjectName = ""
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

                List {
                    ForEach(taskManager.activeProjects) { project in
                        HStack {
                            TextField("Project Name", text: Binding(
                                get: { project.name },
                                set: { updatedName in
                                    var updated = project
                                    updated.name = updatedName
                                    taskManager.updateProject(updated)
                                }
                            ))

                            Spacer()

                            Button("Archive") {
                                taskManager.archiveProject(project)
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(DashboardPalette.destructive)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var labelsColumn: some View {
        DashboardSurface(padding: 14, radius: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Labels")
                    .font(.headline)
                    .foregroundStyle(DashboardPalette.textPrimary)

                HStack(spacing: 8) {
                    TextField("New label", text: $newLabelName)
                        .textFieldStyle(.roundedBorder)

                    Picker("Color", selection: $newLabelColor) {
                        ForEach(TaxonomyColorToken.allCases) { color in
                            Text(color.displayName).tag(color)
                        }
                    }
                    .frame(width: 110)

                    Button("Add") {
                        if taskManager.createLabel(name: newLabelName, colorToken: newLabelColor) != nil {
                            newLabelName = ""
                            newLabelColor = .blue
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

                List {
                    ForEach(taskManager.activeLabels) { label in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(label.colorToken.color)
                                .frame(width: 10, height: 10)

                            TextField("Label Name", text: Binding(
                                get: { label.name },
                                set: { updatedName in
                                    var updated = label
                                    updated.name = updatedName
                                    taskManager.updateLabel(updated)
                                }
                            ))

                            Spacer()

                            Button("Archive") {
                                taskManager.archiveLabel(label)
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(DashboardPalette.destructive)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let taskManager = TaskManager()
    let settingsStore = SettingsStore()
    let permissionsManager = PermissionsManager()

    DashboardView()
        .environmentObject(DashboardNavigation())
        .environmentObject(taskManager)
        .environmentObject(SessionManager(settingsStore: settingsStore))
        .environmentObject(
            TextInjectionService(
                textInjector: TextInjector(),
                settingsStore: settingsStore,
                permissionsManager: permissionsManager,
                adapterRegistry: AdapterRegistry(),
                inputFieldDetector: InputFieldDetector()
            )
        )
        .environmentObject(AnalyticsManager())
}
