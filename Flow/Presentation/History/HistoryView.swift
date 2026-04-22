//
//  HistoryView.swift
//  Flow
//
//  Created by Artem Batutin on 2026-01-27.
//

import SwiftUI
import UniformTypeIdentifiers

struct HistoryView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var textInjectionService: TextInjectionService

    @State private var showClearConfirmation = false
    @State private var showExportSheet = false
    @State private var selectedCaptureKind: CaptureKind?

    var body: some View {
        VStack(spacing: 20) {
            controls

            if displayedSessions.isEmpty {
                emptyStateView
            } else {
                sessionStream
            }
        }
        .alert("Clear History", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                sessionManager.clearHistory()
            }
        } message: {
            Text("Are you sure you want to delete all transcription history? This cannot be undone.")
        }
        .sheet(isPresented: $showExportSheet) {
            ExportHistoryView()
        }
    }

    private var controls: some View {
        DashboardPanel {
            VStack(spacing: 16) {
                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Session history")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundStyle(DashboardPalette.textPrimary)

                        Text("Inspect raw captures, search for phrases, and move useful text back into the active app.")
                            .font(.title3)
                            .foregroundStyle(DashboardPalette.textSecondary)
                    }

                    Spacer()

                    HStack(spacing: 10) {
                        Button("Export") {
                            showExportSheet = true
                        }
                        .buttonStyle(.bordered)
                        .disabled(sessionManager.sessions.isEmpty)

                        Button("Clear") {
                            showClearConfirmation = true
                        }
                        .buttonStyle(.bordered)
                        .disabled(sessionManager.sessions.isEmpty)
                    }
                }

                HStack(spacing: 12) {
                    DashboardPillPicker(
                        options: [Optional<CaptureKind>.none] + CaptureKind.allCases.map(Optional.some),
                        selection: $selectedCaptureKind
                    ) { kind, _ in
                        Text(kind?.displayName ?? "All Captures")
                            .font(.subheadline.weight(.semibold))
                    }

                    searchField
                        .frame(maxWidth: .infinity)

                    Text("\(displayedSessions.count) sessions")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DashboardPalette.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.black.opacity(0.18))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(DashboardPalette.outlineSoft, lineWidth: 1)
                                )
                        }
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DashboardPalette.textMuted)

            TextField("Search transcriptions", text: $sessionManager.searchQuery)
                .textFieldStyle(.plain)
                .foregroundStyle(DashboardPalette.textPrimary)

            if !sessionManager.searchQuery.isEmpty {
                Button {
                    sessionManager.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DashboardPalette.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(DashboardPalette.outlineSoft, lineWidth: 1)
                )
        }
    }

    private var emptyStateView: some View {
        DashboardPanel {
            VStack(spacing: 14) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(DashboardPalette.accentCyan)

                Text(sessionManager.searchQuery.isEmpty ? "No transcription history yet" : "No sessions match your search")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(DashboardPalette.textPrimary)

                Text(sessionManager.searchQuery.isEmpty ? "Your captured voice sessions will appear here once dictation starts." : "Try a broader phrase or switch the capture filter.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DashboardPalette.textSecondary)
                    .frame(maxWidth: 460)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 70)
        }
    }

    private var sessionStream: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(displayedSessions) { session in
                    SessionRowView(
                        session: session,
                        onCopy: {
                            sessionManager.copyToClipboard(session)
                        },
                        onReinject: {
                            Task {
                                try? await textInjectionService.inject(text: session.transcription)
                            }
                        },
                        onDelete: {
                            sessionManager.deleteSession(session)
                        }
                    )
                }
            }
            .padding(2)
        }
        .scrollIndicators(.hidden)
    }

    private var displayedSessions: [TranscriptionSession] {
        let sessions = sessionManager.filteredSessions
        guard let selectedCaptureKind else { return sessions }
        return sessions.filter { $0.captureKind == selectedCaptureKind }
    }
}

struct SessionRowView: View {
    let session: TranscriptionSession
    let onCopy: () -> Void
    let onReinject: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false
    @State private var isExpanded = false

    var body: some View {
        DashboardPanel(padding: 20, radius: 24) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(session.formattedTimestamp)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DashboardPalette.textMuted)

                        HStack(spacing: 8) {
                            badge(
                                text: session.captureKind.displayName,
                                color: session.captureKind == .task ? DashboardPalette.accentAmber : DashboardPalette.accentBlue
                            )
                            badge(text: session.formattedDuration, color: DashboardPalette.accentCyan)
                            badge(text: "\(session.wordCount) words", color: DashboardPalette.accentRose)

                            if let app = session.targetApp {
                                badge(text: app, color: DashboardPalette.textSecondary)
                            }
                        }
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        actionButton(systemName: "doc.on.doc", action: onCopy)

                        if session.captureKind == .dictation {
                            actionButton(systemName: "text.cursor", action: onReinject)
                        }

                        actionButton(systemName: "trash", role: .destructive, action: onDelete)
                    }
                    .opacity(isHovering ? 1 : 0.72)
                }

                Text(isExpanded ? session.transcription : session.truncatedTranscription)
                    .font(.body)
                    .foregroundStyle(DashboardPalette.textPrimary)
                    .lineLimit(isExpanded ? nil : 4)

                HStack {
                    if session.transcription.count > 100 {
                        Button(isExpanded ? "Show less" : "Show more") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded.toggle()
                            }
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(DashboardPalette.accentCyan)
                    }

                    Spacer()

                    badge(text: session.modelUsed, color: DashboardPalette.accentBlue)
                }
            }
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private func badge(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.14))
            .clipShape(Capsule(style: .continuous))
    }

    private func actionButton(
        systemName: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(role: role, action: action) {
            Image(systemName: systemName)
                .frame(width: 34, height: 34)
        }
        .buttonStyle(.plain)
        .background {
            Circle()
                .fill(role == .destructive ? Color.red.opacity(0.16) : Color.white.opacity(0.08))
        }
        .foregroundStyle(role == .destructive ? Color.red.opacity(0.95) : DashboardPalette.textPrimary)
    }
}

struct ExportHistoryView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.dismiss) var dismiss

    @State private var exportFormat: ExportFormat = .text

    enum ExportFormat: String, CaseIterable {
        case text = "Plain Text"
        case json = "JSON"
    }

    var body: some View {
        ZStack {
            DashboardSceneBackground()

            DashboardPanel {
                VStack(spacing: 20) {
                    Text("Export History")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(DashboardPalette.textPrimary)

                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)

                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .keyboardShortcut(.cancelAction)

                        Button("Export") {
                            exportHistory()
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                }
            }
            .padding(24)
        }
        .frame(width: 360, height: 240)
        .preferredColorScheme(.dark)
    }

    private func exportHistory() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = exportFormat == .json ? [.json] : [.plainText]
        panel.nameFieldStringValue = "\(AppBranding.historyExportFileName).\(exportFormat == .json ? "json" : "txt")"

        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    if exportFormat == .json {
                        if let data = sessionManager.exportSessionsAsJSON() {
                            try data.write(to: url)
                        }
                    } else {
                        let text = sessionManager.exportSessionsAsText()
                        try text.write(to: url, atomically: true, encoding: .utf8)
                    }
                } catch {
                    print("Export failed: \(error)")
                }
            }
            dismiss()
        }
    }
}

struct StatisticsView: View {
    @EnvironmentObject var sessionManager: SessionManager

    @State private var showResetConfirmation = false

    var body: some View {
        Form {
            Section {
                StatRow(title: "Total Sessions", value: "\(sessionManager.statistics.totalSessions)")
                StatRow(title: "Total Words", value: "\(sessionManager.statistics.totalWords)")
                StatRow(title: "Total Characters", value: "\(sessionManager.statistics.totalCharacters)")
                StatRow(title: "Total Recording Time", value: sessionManager.statistics.formattedTotalDuration)
            } header: {
                Text("All Time")
            }

            Section {
                StatRow(title: "Sessions Today", value: "\(sessionManager.statistics.sessionsToday)")
                StatRow(title: "Words Today", value: "\(sessionManager.statistics.wordsToday)")
            } header: {
                Text("Today")
            }

            Section {
                StatRow(title: "Estimated Time Saved", value: sessionManager.statistics.estimatedTimeSaved)
                Text("Based on average typing speed of 40 WPM vs speaking at 150 WPM")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Productivity")
            }

            Section {
                Button("Reset Statistics") {
                    showResetConfirmation = true
                }
                .foregroundColor(.red)
            }
        }
        .formStyle(.grouped)
        .alert("Reset Statistics", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                sessionManager.resetStatistics()
            }
        } message: {
            Text("Are you sure you want to reset all usage statistics? This cannot be undone.")
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(SessionManager(settingsStore: SettingsStore()))
        .environmentObject(TextInjectionService(
            textInjector: TextInjector(),
            settingsStore: SettingsStore(),
            permissionsManager: PermissionsManager()
        ))
}
