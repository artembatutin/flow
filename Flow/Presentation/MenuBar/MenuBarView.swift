//
//  MenuBarView.swift
//  Flow
//
//  Created by Artem Batutin on 2026-01-27.
//

import SwiftUI
import AppKit

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var hotkeyManager: HotkeyManager
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var taskManager: TaskManager
    @State private var didCopyLastCapture = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            summaryCard
            lastCaptureCard
            launcherButtons
            footer
        }
        .padding(18)
        .frame(width: 340)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: appState.recordingState.iconName)
                .font(.system(size: 28))
                .foregroundStyle(statusColor)
                .symbolEffect(.pulse, isActive: appState.recordingState == .listening)
                .frame(width: 42, height: 42)
                .background(
                    Circle()
                        .fill(statusColor.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(AppBranding.displayName)
                    .font(.title3.weight(.semibold))

                Text(appState.recordingState.displayText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            statusBadge
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                summaryMetric(title: "Model", value: settingsStore.selectedModel)
                Spacer()
                summaryMetric(title: "Hotkey", value: hotkeyManager.currentKeyCombo.displayName)
            }

            Divider()

            HStack {
                summaryMetric(title: "Open Tasks", value: "\(openTaskCount)")
                Spacer()
                summaryMetric(title: "Captures", value: "\(sessionManager.sessions.count)")
            }
        }
        .padding(14)
        .menuPanelBackground()
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var lastCaptureCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Last Capture")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Spacer()

                Button {
                    copyLastCapture()
                } label: {
                    Label(didCopyLastCapture ? "Copied" : "Copy", systemImage: didCopyLastCapture ? "checkmark" : "doc.on.doc")
                        .font(.callout.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(lastCaptureText == nil)
            }

            Text(lastCaptureText ?? "No captures yet")
                .font(.callout.weight(.medium))
                .foregroundStyle(lastCaptureText == nil ? .secondary : .primary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .menuPanelBackground()
    }

    private var launcherButtons: some View {
        HStack(spacing: 10) {
            Button {
                DashboardWindowController.shared.showWindow()
            } label: {
                launcherLabel(title: "Dashboard", systemImage: "square.grid.2x2")
            }
            .buttonStyle(.plain)

            Button {
                SettingsWindowController.shared.showWindow()
            } label: {
                launcherLabel(title: "Settings", systemImage: "gearshape")
            }
            .buttonStyle(.plain)
        }
    }

    private func launcherLabel(title: String, systemImage: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 22)

            Text(title)
                .font(.callout.weight(.semibold))
        }
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private var footer: some View {
        HStack {
            Spacer()

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
        }
    }

    private var statusBadge: some View {
        Text(statusBadgeText)
            .font(.caption.weight(.semibold))
            .foregroundStyle(statusColor)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.12))
            )
    }

    private var statusBadgeText: String {
        switch appState.recordingState {
        case .idle:
            return "Ready"
        case .listening, .processing:
            return "Active"
        case .error:
            return "Error"
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

    private var lastCaptureText: String? {
        if let last = appState.lastTranscription?.trimmingCharacters(in: .whitespacesAndNewlines), !last.isEmpty {
            return last
        }

        if let last = sessionManager.recentSessions.first?.transcription.trimmingCharacters(in: .whitespacesAndNewlines), !last.isEmpty {
            return last
        }

        return nil
    }

    private func copyLastCapture() {
        guard let text = lastCaptureText else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        didCopyLastCapture = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            didCopyLastCapture = false
        }
    }
}

private extension View {
    func menuPanelBackground() -> some View {
        background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

#Preview {
    let settingsStore = SettingsStore()
    return MenuBarView()
        .environmentObject(AppState())
        .environmentObject(settingsStore)
        .environmentObject(HotkeyManager(settingsStore: settingsStore))
        .environmentObject(SessionManager(settingsStore: settingsStore))
        .environmentObject(TaskManager())
}
