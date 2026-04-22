//
//  AppBreakdownView.swift
//  Flow
//
//  Created by Artem Batutin on 2026-01-27.
//

import SwiftUI

struct AppBreakdownView: View {
    let apps: [UsageMetrics.AppMetric]
    
    private var totalSessions: Int {
        apps.reduce(0) { $0 + $1.sessions }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Apps")
                .font(.headline)
                .fontWeight(.semibold)
            
            if apps.isEmpty {
                emptyStateView
            } else {
                appListView
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "app.badge")
                .font(.system(size: 28))
                .foregroundColor(.secondary)
            Text("No app data yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var appListView: some View {
        VStack(spacing: 10) {
            ForEach(apps) { app in
                appRow(app)
            }
        }
    }
    
    private func appRow(_ app: UsageMetrics.AppMetric) -> some View {
        HStack(spacing: 12) {
            Image(systemName: appIcon(for: app.appName))
                .font(.system(size: 16))
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.appName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("\(app.words) words")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(app.sessions)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(percentage(for: app))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func percentage(for app: UsageMetrics.AppMetric) -> String {
        guard totalSessions > 0 else { return "0%" }
        let percent = (Double(app.sessions) / Double(totalSessions)) * 100
        return String(format: "%.0f%%", percent)
    }
    
    private func appIcon(for appName: String) -> String {
        let lowercased = appName.lowercased()
        
        if lowercased.contains("cursor") || lowercased.contains("windsurf") || lowercased.contains("code") {
            return "chevron.left.forwardslash.chevron.right"
        } else if lowercased.contains("xcode") {
            return "hammer"
        } else if lowercased.contains("safari") {
            return "safari"
        } else if lowercased.contains("chrome") {
            return "globe"
        } else if lowercased.contains("slack") || lowercased.contains("discord") || lowercased.contains("teams") {
            return "message"
        } else if lowercased.contains("mail") || lowercased.contains("outlook") {
            return "envelope"
        } else if lowercased.contains("notes") {
            return "note.text"
        } else if lowercased.contains("pages") || lowercased.contains("word") {
            return "doc.text"
        } else if lowercased.contains("terminal") || lowercased.contains("iterm") {
            return "terminal"
        } else if lowercased.contains("finder") {
            return "folder"
        }
        
        return "app"
    }
}

#Preview {
    let sampleApps: [UsageMetrics.AppMetric] = [
        UsageMetrics.AppMetric(bundleId: "com.cursor", appName: "Cursor", sessions: 45, words: 2500),
        UsageMetrics.AppMetric(bundleId: "com.slack", appName: "Slack", sessions: 20, words: 800),
        UsageMetrics.AppMetric(bundleId: "com.apple.mail", appName: "Mail", sessions: 15, words: 600),
        UsageMetrics.AppMetric(bundleId: "com.apple.safari", appName: "Safari", sessions: 10, words: 300),
        UsageMetrics.AppMetric(bundleId: "com.apple.notes", appName: "Notes", sessions: 5, words: 150),
    ]
    
    AppBreakdownView(apps: sampleApps)
        .frame(width: 300)
        .padding()
}
