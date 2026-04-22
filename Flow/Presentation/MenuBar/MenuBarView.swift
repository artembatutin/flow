//
//  MenuBarView.swift
//  Flow
//
//  Created by Artem Batutin on 2026-01-27.
//

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var hotkeyManager: HotkeyManager
    @EnvironmentObject var taskManager: TaskManager

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            summaryCard
            launcherButtons
            footer
        }
        .padding(16)
        .frame(width: 320)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: appState.recordingState.iconName)
                .font(.system(size: 26))
                .foregroundStyle(statusColor)
                .symbolEffect(.pulse, isActive: appState.recordingState == .listening)

            VStack(alignment: .leading, spacing: 4) {
                Text(AppBranding.displayName)
                    .font(.title3.weight(.semibold))

                Text(appState.recordingState.displayText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                summaryMetric(title: "Model", value: settingsStore.selectedModel)
                Spacer()
                summaryMetric(title: "Hotkey", value: hotkeyManager.currentKeyCombo.displayName)
            }

            Divider()

            HStack {
                summaryMetric(title: "Open Tasks", value: "\(openTaskCount)")
                Spacer()
                summaryMetric(title: "Last Capture", value: lastCaptureSummary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func summaryMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
        }
    }

    private var launcherButtons: some View {
        VStack(spacing: 8) {
            Button {
                DashboardWindowController.shared.showWindow()
            } label: {
                launcherLabel(title: "Open Dashboard", systemImage: "square.grid.2x2")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button {
                SettingsWindowController.shared.showWindow()
            } label: {
                launcherLabel(title: "Open Settings", systemImage: "gearshape")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    private func launcherLabel(title: String, systemImage: String) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        HStack {
            Text("Menu bar launcher")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.borderless)
        }
    }

    private var statusColor: Color {
        switch appState.recordingState {
        case .idle:
            return .secondary
        case .listening:
            return .red
        case .processing:
            return .orange
        case .error:
            return .red
        }
    }

    private var openTaskCount: Int {
        taskManager.tasks.filter { $0.status != .done }.count
    }

    private var lastCaptureSummary: String {
        guard let last = appState.lastTranscription, !last.isEmpty else {
            return "None"
        }
        return last.count > 18 ? String(last.prefix(18)) + "…" : last
    }
}

#Preview {
    let settingsStore = SettingsStore()
    return MenuBarView()
        .environmentObject(AppState())
        .environmentObject(settingsStore)
        .environmentObject(HotkeyManager(settingsStore: settingsStore))
        .environmentObject(TaskManager())
}
