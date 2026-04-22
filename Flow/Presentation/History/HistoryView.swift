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
    
    @State private var selectedSession: TranscriptionSession?
    @State private var showDeleteConfirmation = false
    @State private var showClearConfirmation = false
    @State private var showExportSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search transcriptions...", text: $sessionManager.searchQuery)
                    .textFieldStyle(.plain)
                
                if !sessionManager.searchQuery.isEmpty {
                    Button {
                        sessionManager.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            if sessionManager.filteredSessions.isEmpty {
                emptyStateView
            } else {
                sessionListView
            }
            
            Divider()
            
            // Bottom toolbar
            HStack {
                Text("\(sessionManager.sessions.count) sessions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    showExportSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.borderless)
                .disabled(sessionManager.sessions.isEmpty)
                .help("Export history")
                
                Button {
                    showClearConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .disabled(sessionManager.sessions.isEmpty)
                .help("Clear all history")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(minWidth: 400, minHeight: 300)
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
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            if sessionManager.searchQuery.isEmpty {
                Text("No Transcription History")
                    .font(.headline)
                Text("Your transcriptions will appear here")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("No Results")
                    .font(.headline)
                Text("No transcriptions match '\(sessionManager.searchQuery)'")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var sessionListView: some View {
        List(selection: $selectedSession) {
            ForEach(sessionManager.filteredSessions) { session in
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
                .tag(session)
            }
            .onDelete { offsets in
                sessionManager.deleteSessions(at: offsets)
            }
        }
        .listStyle(.inset)
    }
}

// MARK: - Session Row View

struct SessionRowView: View {
    let session: TranscriptionSession
    let onCopy: () -> Void
    let onReinject: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovering = false
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.formattedTimestamp)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Label(session.formattedDuration, systemImage: "clock")
                        Label("\(session.wordCount) words", systemImage: "text.word.spacing")
                        if let app = session.targetApp {
                            Label(app, systemImage: "app")
                        }
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isHovering {
                    HStack(spacing: 4) {
                        Button {
                            onCopy()
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.borderless)
                        .help("Copy to clipboard")
                        
                        Button {
                            onReinject()
                        } label: {
                            Image(systemName: "text.cursor")
                        }
                        .buttonStyle(.borderless)
                        .help("Re-inject text")
                        
                        Button {
                            onDelete()
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.red)
                        .help("Delete")
                    }
                }
            }
            
            // Transcription text
            Text(isExpanded ? session.transcription : session.truncatedTranscription)
                .font(.body)
                .lineLimit(isExpanded ? nil : 3)
            
            if session.transcription.count > 100 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(isExpanded ? "Show less" : "Show more")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            
            // Model badge
            HStack {
                Text(session.modelUsed)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundColor(.accentColor)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Export History View

struct ExportHistoryView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.dismiss) var dismiss
    
    @State private var exportFormat: ExportFormat = .text
    
    enum ExportFormat: String, CaseIterable {
        case text = "Plain Text"
        case json = "JSON"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Export History")
                .font(.headline)
            
            Picker("Format", selection: $exportFormat) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            
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
        .padding(20)
        .frame(width: 300)
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

// MARK: - Statistics View

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

// MARK: - Preview

#Preview {
    HistoryView()
        .environmentObject(SessionManager(settingsStore: SettingsStore()))
        .environmentObject(TextInjectionService(
            textInjector: TextInjector(),
            settingsStore: SettingsStore(),
            permissionsManager: PermissionsManager()
        ))
}
