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
    @EnvironmentObject var permissionsManager: PermissionsManager
    @EnvironmentObject var hotkeyManager: HotkeyManager
    
    @State private var showingSettings = false
    @State private var showingAbout = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Status Header
            statusHeader
            
            Divider()
            
            // Permissions Warning (if needed)
            if !permissionsManager.criticalPermissionsGranted {
                permissionsWarning
                Divider()
            }
            
            // Last Transcription
            if let transcription = appState.lastTranscription {
                lastTranscriptionView(transcription)
                Divider()
            }
            
            // Quick Actions
            quickActions
            
            Divider()
            
            // Footer
            footerActions
        }
        .padding()
        .frame(width: 300)
    }
    
    // MARK: - Status Header
    
    private var statusHeader: some View {
        HStack(spacing: 12) {
            statusIcon
            
            VStack(alignment: .leading, spacing: 2) {
                Text(AppBranding.displayName)
                    .font(.headline)
                
                Text(appState.recordingState.displayText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if appState.recordingState == .listening {
                audioLevelIndicator
            }
        }
    }
    
    private var statusIcon: some View {
        Image(systemName: appState.recordingState.iconName)
            .font(.title2)
            .foregroundColor(statusColor)
            .symbolEffect(.pulse, isActive: appState.recordingState == .listening)
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
    
    private var audioLevelIndicator: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(index < Int(appState.audioLevel * 5) ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 3, height: CGFloat(4 + index * 2))
            }
        }
    }
    
    // MARK: - Permissions Warning
    
    private var permissionsWarning: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Permissions Required", systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundColor(.orange)
            
            if !permissionsManager.microphoneGranted {
                permissionRow(title: "Microphone", granted: false) {
                    Task {
                        await permissionsManager.requestMicrophoneAccess()
                    }
                }
            }
            
            if !permissionsManager.accessibilityGranted {
                permissionRow(title: "Accessibility", granted: false) {
                    permissionsManager.openAccessibilitySettings()
                }
            }
            
            if !permissionsManager.inputMonitoringGranted {
                permissionRow(title: "Input Monitoring", granted: false) {
                    permissionsManager.openInputMonitoringSettings()
                }
            }
        }
        .padding(8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func permissionRow(title: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(granted ? .green : .red)
                .font(.caption)
            
            Text(title)
                .font(.caption)
            
            Spacer()
            
            if !granted {
                Button("Grant") {
                    action()
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
        }
    }
    
    // MARK: - Last Transcription
    
    private func lastTranscriptionView(_ transcription: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Last Transcription")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(transcription)
                .font(.callout)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(transcription, forType: .string)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
        }
    }
    
    // MARK: - Quick Actions
    
    private var quickActions: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Model")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(settingsStore.selectedModel)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            
            HStack {
                Text("Trigger")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(settingsStore.triggerMode.displayName)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            
            HStack {
                Text("Hotkey")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Text(hotkeyManager.currentKeyCombo.displayName)
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundColor(.accentColor)
                        .cornerRadius(4)
                    
                    if hotkeyManager.isListening {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    // MARK: - Footer Actions
    
    private var footerActions: some View {
        HStack {
            Button {
                showingSettings = true
                if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "settings" }) {
                    window.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                } else {
                    SettingsWindowController.shared.showWindow()
                }
            } label: {
                Label("Settings", systemImage: "gear")
            }
            .buttonStyle(.borderless)
            
            Spacer()
            
            Button {
                showingAbout = true
            } label: {
                Label("About", systemImage: "info.circle")
            }
            .buttonStyle(.borderless)
            .popover(isPresented: $showingAbout) {
                AboutView()
            }
            
            Spacer()
            
            Button {
                NSApp.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
            }
            .buttonStyle(.borderless)
        }
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            
            Text(AppBranding.displayName)
                .font(.headline)
            
            Text("Version 1.0")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Voice dictation for macOS")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 200)
    }
}

#Preview {
    let settingsStore = SettingsStore()
    return MenuBarView()
        .environmentObject(AppState())
        .environmentObject(settingsStore)
        .environmentObject(PermissionsManager())
        .environmentObject(HotkeyManager(settingsStore: settingsStore))
}
