//
//  FlowWidget.swift
//  FlowWidget
//
//  Created by Codex on 2026-05-01.
//

import AppIntents
import SwiftUI
import WidgetKit

struct FlowTasksEntry: TimelineEntry {
    let date: Date
    let tasks: [TaskItem]
}

struct FlowTasksProvider: TimelineProvider {
    func placeholder(in context: Context) -> FlowTasksEntry {
        FlowTasksEntry(
            date: Date(),
            tasks: [
                TaskItem(title: "Review captured tasks", status: .next, priority: .high),
                TaskItem(title: "Send a follow-up", status: .inProgress, priority: .medium)
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FlowTasksEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FlowTasksEntry>) -> Void) {
        completion(Timeline(entries: [entry()], policy: .after(Date().addingTimeInterval(60))))
    }

    private func entry() -> FlowTasksEntry {
        let tasks = SharedTaskWorkspace.load().tasks.sortedForWidget
        return FlowTasksEntry(date: Date(), tasks: tasks)
    }
}

struct FlowWidget: Widget {
    let kind = SharedTaskWorkspace.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FlowTasksProvider()) { entry in
            FlowTasksWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    FlowWidgetBackground()
                }
        }
        .configurationDisplayName("Flow Tasks")
        .description("Review tasks from Flow and update them from your desktop.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct FlowTasksWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: FlowTasksEntry

    private var openTasks: [TaskItem] {
        entry.tasks.filter { $0.status != .done }
    }

    private var visibleTasks: [TaskItem] {
        Array(openTasks.prefix(taskLimit))
    }

    private var taskLimit: Int {
        switch family {
        case .systemSmall:
            return 2
        case .systemMedium:
            return 3
        default:
            return 6
        }
    }

    private var tasksURL: URL {
        URL(string: "flow://tasks")!
    }

    private var newTaskURL: URL {
        URL(string: "flow://tasks/new")!
    }

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 8 : 12) {
            header

            if visibleTasks.isEmpty {
                emptyState
            } else {
                VStack(spacing: family == .systemSmall ? 6 : 8) {
                    ForEach(visibleTasks) { task in
                        FlowWidgetTaskRow(task: task, compact: family == .systemSmall)
                    }
                }
            }

            Spacer(minLength: 0)

            if family != .systemSmall {
                footer
            }
        }
        .padding(family == .systemSmall ? 12 : 16)
        .widgetURL(tasksURL)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 9) {
            HStack(spacing: 7) {
                Image(systemName: "waveform")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 6, style: .continuous))

                Text("Flow")
                    .font(.headline.weight(.semibold))
            }

            Spacer(minLength: 0)

            Text("\(openTasks.count) open")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.primary.opacity(0.07), in: Capsule())

            Link(destination: newTaskURL) {
                Image(systemName: "plus")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 28)
                    .background(.blue.gradient, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "checkmark.circle")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.green)

            Text("No open tasks")
                .font(.subheadline.weight(.semibold))

            Text("Your captured tasks are clear.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Link(destination: newTaskURL) {
                Label("New", systemImage: "plus")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(height: 32)
                    .padding(.horizontal, 14)
                    .background(.blue.gradient, in: Capsule())
            }
            .buttonStyle(.plain)

            Link(destination: tasksURL) {
                Label("Open Flow", systemImage: "arrow.up.forward.app")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(height: 32)
                    .padding(.horizontal, 12)
                    .background(.primary.opacity(0.08), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}

private struct FlowWidgetTaskRow: View {
    let task: TaskItem
    let compact: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Button(intent: UpdateTaskStatusIntent(taskID: task.id.uuidString, status: TaskStatus.done.rawValue)) {
                ZStack {
                    Circle()
                        .stroke(task.priority.tintColor, lineWidth: 2)
                        .frame(width: compact ? 16 : 18, height: compact ? 16 : 18)

                    Circle()
                        .fill(task.priority.tintColor.opacity(0.14))
                        .frame(width: compact ? 8 : 10, height: compact ? 8 : 10)
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(compact ? 2 : 1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 6) {
                    FlowWidgetBadge(title: task.status.shortName, color: task.status.tintColor)
                    FlowWidgetBadge(title: task.priority.displayName, color: task.priority.tintColor)
                }
                .lineLimit(1)
            }

            Spacer(minLength: 0)

            if !compact, task.status != .next {
                Button(intent: PromoteTaskIntent(taskID: task.id.uuidString)) {
                    Text("Next")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.14), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, compact ? 9 : 12)
        .padding(.vertical, compact ? 8 : 10)
        .background(.primary.opacity(0.075), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(task.priority.tintColor)
                .frame(width: 3)
                .padding(.vertical, 10)
        }
    }
}

private struct FlowWidgetBadge: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
    }
}

private struct FlowWidgetBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(nsColor: .windowBackgroundColor),
                Color(nsColor: .controlBackgroundColor),
                Color.blue.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(.primary.opacity(0.035))
    }
}

private extension Array where Element == TaskItem {
    var sortedForWidget: [TaskItem] {
        sorted { lhs, rhs in
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
}
