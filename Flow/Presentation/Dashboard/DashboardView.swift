//
//  DashboardView.swift
//  Flow
//
//  Created by Codex on 2026-04-22.
//

import SwiftUI

enum DashboardPalette {
    static let background = Color(nsColor: NSColor(calibratedRed: 0.05, green: 0.06, blue: 0.08, alpha: 1))
    static let backgroundSecondary = Color(nsColor: NSColor(calibratedRed: 0.08, green: 0.09, blue: 0.12, alpha: 1))
    static let surfaceTop = Color(nsColor: NSColor(calibratedRed: 0.15, green: 0.16, blue: 0.20, alpha: 0.94))
    static let surfaceBottom = Color(nsColor: NSColor(calibratedRed: 0.10, green: 0.11, blue: 0.14, alpha: 0.96))
    static let surfaceRaised = Color(nsColor: NSColor(calibratedRed: 0.19, green: 0.20, blue: 0.24, alpha: 0.92))
    static let outline = Color.white.opacity(0.09)
    static let outlineSoft = Color.white.opacity(0.05)
    static let textPrimary = Color.white.opacity(0.96)
    static let textSecondary = Color.white.opacity(0.68)
    static let textMuted = Color.white.opacity(0.5)
    static let accentBlue = Color(nsColor: NSColor(calibratedRed: 0.22, green: 0.56, blue: 1.00, alpha: 1))
    static let accentCyan = Color(nsColor: NSColor(calibratedRed: 0.23, green: 0.87, blue: 0.86, alpha: 1))
    static let accentAmber = Color(nsColor: NSColor(calibratedRed: 0.98, green: 0.72, blue: 0.25, alpha: 1))
    static let accentRose = Color(nsColor: NSColor(calibratedRed: 1.00, green: 0.45, blue: 0.57, alpha: 1))
    static let accentViolet = Color(nsColor: NSColor(calibratedRed: 0.56, green: 0.46, blue: 1.00, alpha: 1))
    static let shadow = Color.black.opacity(0.34)
}

struct DashboardSceneBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [DashboardPalette.background, DashboardPalette.backgroundSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(DashboardPalette.accentBlue.opacity(0.18))
                .frame(width: 460, height: 460)
                .blur(radius: 130)
                .offset(x: 280, y: -220)

            Circle()
                .fill(DashboardPalette.accentAmber.opacity(0.14))
                .frame(width: 340, height: 340)
                .blur(radius: 120)
                .offset(x: -260, y: -170)

            Circle()
                .fill(DashboardPalette.accentCyan.opacity(0.10))
                .frame(width: 420, height: 420)
                .blur(radius: 150)
                .offset(x: -240, y: 250)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.03), Color.clear, Color.white.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.screen)
                .ignoresSafeArea()
        }
    }
}

struct DashboardPanel<Content: View>: View {
    let padding: CGFloat
    let radius: CGFloat
    @ViewBuilder var content: Content

    init(
        padding: CGFloat = 24,
        radius: CGFloat = 28,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.radius = radius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(panelShape)
            .shadow(color: DashboardPalette.shadow, radius: 24, x: 0, y: 18)
    }

    private var panelShape: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [DashboardPalette.surfaceTop, DashboardPalette.surfaceBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(DashboardPalette.outline, lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
                    .blur(radius: 18)
                    .mask(
                        LinearGradient(
                            colors: [Color.white, Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
    }
}

struct DashboardPillPicker<Selection: Hashable, Label: View>: View {
    let options: [Selection]
    @Binding var selection: Selection
    let label: (Selection, Bool) -> Label

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.self) { option in
                let isSelected = selection == option

                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        selection = option
                    }
                } label: {
                    label(option, isSelected)
                        .foregroundStyle(isSelected ? DashboardPalette.textPrimary : DashboardPalette.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .frame(minHeight: 40)
                        .background {
                            Capsule(style: .continuous)
                                .fill(
                                    isSelected
                                        ? AnyShapeStyle(
                                            LinearGradient(
                                                colors: [DashboardPalette.accentBlue, DashboardPalette.accentCyan],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        : AnyShapeStyle(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.07), Color.white.opacity(0.03)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .overlay(
                                    Capsule(style: .continuous)
                                        .strokeBorder(isSelected ? Color.white.opacity(0.12) : DashboardPalette.outlineSoft, lineWidth: 1)
                                )
                        }
                        .scaleEffect(isSelected ? 1 : 0.98)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background {
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.24))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(DashboardPalette.outlineSoft, lineWidth: 1)
                )
        }
    }
}

struct DashboardMetricStrip: View {
    let eyebrow: String
    let value: String
    let caption: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(accent)
                    .frame(width: 8, height: 8)
                Text(eyebrow.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(DashboardPalette.textMuted)
            }

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(DashboardPalette.textPrimary)

            Text(caption)
                .font(.subheadline)
                .foregroundStyle(DashboardPalette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(DashboardPalette.outlineSoft, lineWidth: 1)
                )
        }
    }
}

private enum DashboardMode: String, CaseIterable, Identifiable {
    case tasks = "Tasks"
    case dictation = "Dictation"

    var id: String { rawValue }
}

private enum TaskSidebarSelection: Hashable {
    case allTasks
    case project(UUID)
}

private enum DictationMode: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case history = "History"

    var id: String { rawValue }
}

struct DashboardView: View {
    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var textInjectionService: TextInjectionService
    @EnvironmentObject var analyticsManager: AnalyticsManager

    @State private var mode: DashboardMode = .tasks

    private var openTasks: Int {
        taskManager.tasks.filter { $0.status != .done }.count
    }

    private var completedTasks: Int {
        taskManager.tasks.filter { $0.status == .done }.count
    }

    private var weeklyTotals: (sessions: Int, words: Int, timeSaved: TimeInterval) {
        analyticsManager.getTotals(for: .week)
    }

    var body: some View {
        ZStack {
            DashboardSceneBackground()

            VStack(spacing: 24) {
                header

                Group {
                    switch mode {
                    case .tasks:
                        TasksWorkspaceView()
                    case .dictation:
                        DictationWorkspaceView()
                    }
                }
            }
            .padding(24)
        }
        .frame(minWidth: 1120, minHeight: 760)
        .tint(DashboardPalette.accentBlue)
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        DashboardPanel(padding: 30, radius: 34) {
            HStack(alignment: .top, spacing: 28) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("FLOW WORKSPACE")
                        .font(.caption.weight(.bold))
                        .tracking(2.4)
                        .foregroundStyle(DashboardPalette.textMuted)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Command the work, not the window chrome.")
                            .font(.system(size: 38, weight: .bold, design: .serif))
                            .foregroundStyle(DashboardPalette.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("A single control room for captured tasks, dictation volume, and execution pace.")
                            .font(.title3)
                            .foregroundStyle(DashboardPalette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: 14) {
                        DashboardMetricStrip(
                            eyebrow: "Open Tasks",
                            value: "\(openTasks)",
                            caption: completedTasks == 0 ? "Ready to route" : "\(completedTasks) completed",
                            accent: DashboardPalette.accentAmber
                        )

                        DashboardMetricStrip(
                            eyebrow: "Voice Sessions",
                            value: "\(weeklyTotals.sessions)",
                            caption: "This week",
                            accent: DashboardPalette.accentCyan
                        )

                        DashboardMetricStrip(
                            eyebrow: "Time Saved",
                            value: formatTimeSaved(weeklyTotals.timeSaved),
                            caption: "Recovered this week",
                            accent: DashboardPalette.accentBlue
                        )
                    }
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 18) {
                    DashboardPillPicker(options: DashboardMode.allCases, selection: $mode) { option, _ in
                        Text(option.rawValue)
                            .font(.subheadline.weight(.semibold))
                    }

                    VStack(alignment: .trailing, spacing: 10) {
                        Label("Live workspace sync", systemImage: "sparkles")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(DashboardPalette.textPrimary)

                        Text(mode == .tasks ? "Task operations stay editable without leaving the dashboard." : "Analytics and transcription history sit in the same motion system.")
                            .font(.subheadline)
                            .foregroundStyle(DashboardPalette.textSecondary)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 320, alignment: .trailing)
                    }
                    .padding(18)
                    .background {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.black.opacity(0.22))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .strokeBorder(DashboardPalette.outlineSoft, lineWidth: 1)
                            )
                    }
                }
            }
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
    @EnvironmentObject var taskManager: TaskManager

    @State private var sidebarSelection: TaskSidebarSelection = .allTasks
    @State private var showingNewTaskSheet = false
    @State private var showingTaxonomySheet = false

    private var filteredTasks: [TaskItem] {
        taskManager.filteredTasks()
    }

    private var selectedProject: TaskProject? {
        switch sidebarSelection {
        case .allTasks:
            return nil
        case .project(let id):
            return taskManager.visibleProject(for: id)
        }
    }

    private var filteredCompletedTasks: Int {
        filteredTasks.filter { $0.status == .done }.count
    }

    private var filteredHighPriorityTasks: Int {
        filteredTasks.filter { $0.priority == .high || $0.priority == .urgent }.count
    }

    private var filteredVoiceTasks: Int {
        filteredTasks.filter { $0.source == .voiceTask }.count
    }

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 24) {
                sidebar
                    .frame(width: 280)

                VStack(spacing: 20) {
                    taskHero
                    filtersBar
                    taskList
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .padding(.bottom, 6)
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
        }
        .onChange(of: sidebarSelection) { _, _ in
            syncSelection()
        }
    }

    private var sidebar: some View {
        VStack(spacing: 20) {
            DashboardPanel(padding: 22) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Task Map")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(DashboardPalette.textPrimary)

                    VStack(spacing: 10) {
                        sidebarButton(
                            title: "All Tasks",
                            subtitle: "Everything captured so far",
                            icon: "square.stack.3d.up.fill",
                            count: taskManager.tasks.count,
                            selected: sidebarSelection == .allTasks
                        ) {
                            sidebarSelection = .allTasks
                        }

                        ForEach(taskManager.activeProjects) { project in
                            sidebarButton(
                                title: project.name,
                                subtitle: projectTaskCount(project.id) == 0 ? "Quiet lane" : "\(projectTaskCount(project.id)) routed tasks",
                                icon: "circle.grid.2x2.fill",
                                count: projectTaskCount(project.id),
                                selected: sidebarSelection == .project(project.id)
                            ) {
                                sidebarSelection = .project(project.id)
                            }
                        }

                        if taskManager.activeProjects.isEmpty {
                            Text("Create a project to give task capture a lane, then route work with one click.")
                                .font(.subheadline)
                                .foregroundStyle(DashboardPalette.textSecondary)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(Color.black.opacity(0.18))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .strokeBorder(DashboardPalette.outlineSoft, lineWidth: 1)
                                        )
                                }
                        }
                    }
                }
            }

            DashboardPanel(padding: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Signals")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(DashboardPalette.textPrimary)

                    dashboardSignal(title: "Active", value: "\(taskManager.tasks.filter { $0.status != .done }.count)", accent: DashboardPalette.accentBlue)
                    dashboardSignal(title: "Urgent + High", value: "\(taskManager.tasks.filter { $0.priority == .urgent || $0.priority == .high }.count)", accent: DashboardPalette.accentRose)
                    dashboardSignal(title: "Voice Captured", value: "\(taskManager.tasks.filter { $0.source == .voiceTask }.count)", accent: DashboardPalette.accentAmber)
                }
            }
        }
    }

    private var taskHero: some View {
        DashboardPanel {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(selectedProject?.name ?? "All captured work")
                            .font(.system(size: 30, weight: .bold, design: .serif))
                            .foregroundStyle(DashboardPalette.textPrimary)

                        Text(selectedProject == nil ? "Triage captured work, keep pressure on priority, and turn voice input into finished output." : "Focused lane for \(selectedProject!.name).")
                            .font(.title3)
                            .foregroundStyle(DashboardPalette.textSecondary)
                    }

                    Spacer(minLength: 0)

                    HStack(spacing: 12) {
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

                HStack(spacing: 14) {
                    heroStat(title: "Visible", value: "\(filteredTasks.count)", caption: "tasks in scope", accent: DashboardPalette.accentBlue)
                    heroStat(title: "High Pressure", value: "\(filteredHighPriorityTasks)", caption: "high or urgent", accent: DashboardPalette.accentRose)
                    heroStat(title: "Voice Flow", value: "\(filteredVoiceTasks)", caption: "voice-captured", accent: DashboardPalette.accentAmber)
                    heroStat(title: "Done", value: "\(filteredCompletedTasks)", caption: "closed out", accent: DashboardPalette.accentCyan)
                }
            }
        }
    }

    private var filtersBar: some View {
        DashboardPanel(padding: 18) {
            VStack(spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    filterField("Label", width: 170) {
                        Picker("Label", selection: labelFilterBinding) {
                            Text("All Labels").tag(Optional<UUID>.none)
                            ForEach(taskManager.activeLabels) { label in
                                Text(label.name).tag(Optional(label.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }

                    filterField("Status", width: 170) {
                        Picker("Status", selection: statusFilterBinding) {
                            Text("All Statuses").tag(Optional<TaskStatus>.none)
                            ForEach(TaskStatus.allCases) { status in
                                Text(status.displayName).tag(Optional(status))
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }

                    filterField("Priority", width: 170) {
                        Picker("Priority", selection: priorityFilterBinding) {
                            Text("All Priorities").tag(Optional<TaskPriority>.none)
                            ForEach(TaskPriority.allCases) { priority in
                                Text(priority.displayName).tag(Optional(priority))
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }

                    filterField("Search", width: nil) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(DashboardPalette.textMuted)
                            TextField("Search titles, notes, projects, labels", text: searchBinding)
                                .textFieldStyle(.plain)
                                .foregroundStyle(DashboardPalette.textPrimary)
                        }
                    }
                }

                HStack {
                    Text(filtersActive ? "Filters active on \(filteredTasks.count) tasks" : "\(filteredTasks.count) tasks currently visible")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(DashboardPalette.textSecondary)

                    Spacer()

                    if filtersActive {
                        Button("Reset Filters") {
                            taskManager.filters = TaskFilterState(selectedProjectID: activeProjectID)
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(DashboardPalette.accentCyan)
                    }
                }
            }
        }
    }

    private var taskList: some View {
        DashboardPanel(padding: 22) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Execution Queue")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(DashboardPalette.textPrimary)

                    Spacer()

                    Text(filteredTasks.isEmpty ? "Nothing in scope" : "\(filteredTasks.count) items")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(DashboardPalette.textSecondary)
                }

                if filteredTasks.isEmpty {
                    emptyTasksView
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredTasks) { task in
                            TaskTableRow(taskID: task.id)
                                .environmentObject(taskManager)
                        }
                    }
                }
            }
        }
    }

    private var emptyTasksView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checklist.checked")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(DashboardPalette.accentCyan)

            Text("No tasks in this lane")
                .font(.title2.weight(.bold))
                .foregroundStyle(DashboardPalette.textPrimary)

            Text("Create a task manually or capture one with a voice command starting with \"task\".")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(DashboardPalette.textSecondary)
                .frame(maxWidth: 460)

            Button("Create Task") {
                showingNewTaskSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 54)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
                        .foregroundStyle(DashboardPalette.outline)
                )
        }
    }

    private var filtersActive: Bool {
        let filters = taskManager.filters
        return filters.selectedLabelID != nil ||
            filters.selectedStatus != nil ||
            filters.selectedPriority != nil ||
            !filters.searchText.isEmpty
    }

    private var activeProjectID: UUID? {
        switch sidebarSelection {
        case .allTasks:
            return nil
        case .project(let id):
            return id
        }
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
        taskManager.filters.selectedProjectID = activeProjectID
    }

    private func projectTaskCount(_ projectID: UUID) -> Int {
        taskManager.tasks.filter { $0.projectID == projectID }.count
    }

    private func sidebarButton(
        title: String,
        subtitle: String,
        icon: String,
        count: Int,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(selected ? DashboardPalette.accentBlue.opacity(0.20) : Color.white.opacity(0.05))
                        .frame(width: 42, height: 42)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(selected ? DashboardPalette.accentCyan : DashboardPalette.textSecondary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DashboardPalette.textPrimary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(DashboardPalette.textSecondary)
                }

                Spacer()

                Text("\(count)")
                    .font(.caption.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(selected ? DashboardPalette.textPrimary : DashboardPalette.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background {
                        Capsule(style: .continuous)
                            .fill(Color.black.opacity(selected ? 0.18 : 0.12))
                    }
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        selected
                            ? LinearGradient(
                                colors: [
                                    DashboardPalette.accentBlue.opacity(0.28),
                                    DashboardPalette.surfaceRaised.opacity(0.92)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.06), Color.white.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(selected ? Color.white.opacity(0.12) : DashboardPalette.outlineSoft, lineWidth: 1)
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private func dashboardSignal(title: String, value: String, accent: Color) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(DashboardPalette.textSecondary)

            Spacer()

            Text(value)
                .font(.headline.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(DashboardPalette.textPrimary)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(accent.opacity(0.20), lineWidth: 1)
                )
        }
    }

    private func heroStat(title: String, value: String, caption: String, accent: Color) -> some View {
        DashboardMetricStrip(eyebrow: title, value: value, caption: caption, accent: accent)
    }

    private func filterField<Content: View>(
        _ title: String,
        width: CGFloat?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(1.1)
                .foregroundStyle(DashboardPalette.textMuted)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.black.opacity(0.18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(DashboardPalette.outlineSoft, lineWidth: 1)
                        )
                }
        }
        .frame(width: width)
    }
}

private struct TaskTableRow: View {
    @EnvironmentObject var taskManager: TaskManager

    let taskID: UUID

    var body: some View {
        if let task = currentTask {
            DashboardPanel(padding: 0, radius: 26) {
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [task.status.tintColor.opacity(0.95), task.priority.tintColor.opacity(0.65)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 4)

                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .top, spacing: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    statusBadge(task.status)
                                    priorityBadge(task.priority)
                                    sourceBadge(task.source)
                                }

                                TextField("Task title", text: Binding(
                                    get: { task.title },
                                    set: { taskManager.updateTask(id: task.id, title: $0) }
                                ))
                                .textFieldStyle(.plain)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(DashboardPalette.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .background(fieldBackground)

                                TextField("Add a note", text: Binding(
                                    get: { task.notes ?? "" },
                                    set: { taskManager.updateTask(id: task.id, notes: $0) }
                                ), axis: .vertical)
                                .lineLimit(2...4)
                                .textFieldStyle(.plain)
                                .foregroundStyle(DashboardPalette.textSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(fieldBackground)
                            }

                            VStack(alignment: .trailing, spacing: 10) {
                                Text(relativeDate(task.updatedAt))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(DashboardPalette.textMuted)

                                Button(role: .destructive) {
                                    taskManager.deleteTask(task)
                                } label: {
                                    Image(systemName: "trash")
                                        .frame(width: 38, height: 38)
                                }
                                .buttonStyle(.plain)
                                .background {
                                    Circle()
                                        .fill(Color.red.opacity(0.16))
                                }
                                .foregroundStyle(Color.red.opacity(0.95))
                            }
                        }

                        HStack(spacing: 12) {
                            menuField("Status", width: 160) {
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

                            menuField("Priority", width: 150) {
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

                            menuField("Project", width: 180) {
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

                            labelsField(for: task)
                        }
                    }
                    .padding(22)
                }
            }
        }
    }

    private var currentTask: TaskItem? {
        taskManager.tasks.first(where: { $0.id == taskID })
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.black.opacity(0.18))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(DashboardPalette.outlineSoft, lineWidth: 1)
            )
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return "Updated \(formatter.localizedString(for: date, relativeTo: Date()))"
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

    private func menuField<Content: View>(
        _ title: String,
        width: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(1)
                .foregroundStyle(DashboardPalette.textMuted)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(fieldBackground)
        }
        .frame(width: width, alignment: .leading)
    }

    private func labelsField(for task: TaskItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LABELS")
                .font(.caption2.weight(.bold))
                .tracking(1)
                .foregroundStyle(DashboardPalette.textMuted)

            Menu {
                ForEach(taskManager.activeLabels) { label in
                    Button {
                        toggleLabel(label.id, on: task)
                    } label: {
                        HStack {
                            Image(systemName: task.labelIDs.contains(label.id) ? "checkmark.circle.fill" : "circle")
                            Text(label.name)
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if task.labelIDs.compactMap(taskManager.label(for:)).isEmpty {
                        Text("Add labels")
                            .foregroundStyle(DashboardPalette.textSecondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(task.labelIDs.compactMap(taskManager.label(for:)).prefix(4)) { label in
                                    Text(label.name)
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 5)
                                        .background(label.colorToken.color.opacity(0.18))
                                        .foregroundStyle(label.colorToken.color)
                                        .clipShape(Capsule(style: .continuous))
                                }
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(DashboardPalette.textMuted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(fieldBackground)
            }
            .menuStyle(.borderlessButton)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statusBadge(_ status: TaskStatus) -> some View {
        badge(text: status.displayName, color: status.tintColor)
    }

    private func priorityBadge(_ priority: TaskPriority) -> some View {
        badge(text: priority.displayName, color: priority.tintColor)
    }

    private func sourceBadge(_ source: TaskSource) -> some View {
        badge(text: source == .voiceTask ? "Voice" : "Manual", color: source == .voiceTask ? DashboardPalette.accentAmber : DashboardPalette.accentBlue)
    }

    private func badge(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.16))
            .clipShape(Capsule(style: .continuous))
    }
}

private struct DictationWorkspaceView: View {
    @EnvironmentObject var analyticsManager: AnalyticsManager

    @State private var mode: DictationMode = .overview

    private var totals: (sessions: Int, words: Int, timeSaved: TimeInterval) {
        analyticsManager.getTotals(for: .week)
    }

    var body: some View {
        VStack(spacing: 20) {
            DashboardPanel {
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Voice intelligence")
                            .font(.system(size: 30, weight: .bold, design: .serif))
                            .foregroundStyle(DashboardPalette.textPrimary)

                        Text("Track output, pressure-test speaking habits, and revisit every captured session without leaving the workspace.")
                            .font(.title3)
                            .foregroundStyle(DashboardPalette.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 14) {
                        DashboardPillPicker(options: DictationMode.allCases, selection: $mode) { option, _ in
                            Text(option.rawValue)
                                .font(.subheadline.weight(.semibold))
                        }

                        HStack(spacing: 10) {
                            compactSignal("Words", value: "\(totals.words)")
                            compactSignal("Sessions", value: "\(totals.sessions)")
                            compactSignal("Saved", value: formatTimeSaved(totals.timeSaved))
                        }
                    }
                }
            }

            Group {
                switch mode {
                case .overview:
                    UsageDashboardView(analyticsManager: analyticsManager)
                case .history:
                    HistoryView()
                }
            }
        }
    }

    private func compactSignal(_ title: String, value: String) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(1)
                .foregroundStyle(DashboardPalette.textMuted)
            Text(value)
                .font(.headline.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(DashboardPalette.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(DashboardPalette.outlineSoft, lineWidth: 1)
                )
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

private struct NewTaskSheet: View {
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var notes = ""
    @State private var status: TaskStatus = .inbox
    @State private var priority: TaskPriority = .medium
    @State private var projectID: UUID?
    @State private var labelIDs: Set<UUID> = []

    var body: some View {
        ZStack {
            DashboardSceneBackground()

            DashboardPanel {
                VStack(alignment: .leading, spacing: 18) {
                    Text("New Task")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(DashboardPalette.textPrimary)

                    Text("Capture work with enough context to route it immediately.")
                        .font(.title3)
                        .foregroundStyle(DashboardPalette.textSecondary)

                    TextField("Task title", text: $title)
                        .textFieldStyle(.roundedBorder)

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                        .textFieldStyle(.roundedBorder)

                    HStack {
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
        .preferredColorScheme(.dark)
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
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Projects & Labels")
                                .font(.system(size: 28, weight: .bold, design: .serif))
                                .foregroundStyle(DashboardPalette.textPrimary)

                            Text("Shape the routing system behind task capture.")
                                .font(.title3)
                                .foregroundStyle(DashboardPalette.textSecondary)
                        }

                        Spacer()

                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    HSplitView {
                        projectsColumn
                        labelsColumn
                    }
                }
            }
            .padding(24)
        }
        .frame(width: 820, height: 560)
        .preferredColorScheme(.dark)
    }

    private var projectsColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Projects")
                .font(.headline)
                .foregroundStyle(DashboardPalette.textPrimary)

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

                        Button(role: .destructive) {
                            taskManager.archiveProject(project)
                        } label: {
                            Image(systemName: "archivebox")
                        }
                        .buttonStyle(.borderless)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)

            HStack {
                TextField("New project", text: $newProjectName)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    _ = taskManager.createProject(name: newProjectName)
                    newProjectName = ""
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var labelsColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Labels")
                .font(.headline)
                .foregroundStyle(DashboardPalette.textPrimary)

            List {
                ForEach(taskManager.activeLabels) { label in
                    HStack {
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

                        Picker("", selection: Binding(
                            get: { label.colorToken },
                            set: { newValue in
                                var updated = label
                                updated.colorToken = newValue
                                taskManager.updateLabel(updated)
                            }
                        )) {
                            ForEach(TaxonomyColorToken.allCases) { token in
                                Text(token.displayName).tag(token)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 110)

                        Button(role: .destructive) {
                            taskManager.archiveLabel(label)
                        } label: {
                            Image(systemName: "archivebox")
                        }
                        .buttonStyle(.borderless)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)

            HStack {
                TextField("New label", text: $newLabelName)
                    .textFieldStyle(.roundedBorder)

                Picker("", selection: $newLabelColor) {
                    ForEach(TaxonomyColorToken.allCases) { token in
                        Text(token.displayName).tag(token)
                    }
                }
                .labelsHidden()
                .frame(width: 110)

                Button("Add") {
                    _ = taskManager.createLabel(name: newLabelName, colorToken: newLabelColor)
                    newLabelName = ""
                    newLabelColor = .blue
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(TaskManager())
        .environmentObject(SessionManager(settingsStore: SettingsStore()))
        .environmentObject(TextInjectionService(
            textInjector: TextInjector(),
            settingsStore: SettingsStore(),
            permissionsManager: PermissionsManager()
        ))
        .environmentObject(AnalyticsManager())
}
