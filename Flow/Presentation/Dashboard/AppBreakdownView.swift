//
//  AppBreakdownView.swift
//  Flow
//
//  Created by Artem Batutin on 2026-01-27.
//

import SwiftUI

struct AppBreakdownView: View {
    let apps: [UsageMetrics.AppMetric]

    private var totalWords: Int {
        apps.reduce(0) { $0 + $1.words }
    }

    private var totalSessions: Int {
        apps.reduce(0) { $0 + $1.sessions }
    }

    var body: some View {
        DashboardPanel(padding: 22) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Top apps")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(DashboardPalette.textPrimary)

                        Text(apps.isEmpty ? "Waiting for app-level data." : "\(totalSessions) sessions across \(apps.count) destinations.")
                            .font(.subheadline)
                            .foregroundStyle(DashboardPalette.textSecondary)
                    }

                    Spacer()
                }

                if apps.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 12) {
                        ForEach(apps) { app in
                            appRow(app)
                        }
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Image(systemName: "app.badge")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(DashboardPalette.accentBlue)

            Text("No app breakdown yet")
                .font(.headline)
                .foregroundStyle(DashboardPalette.textPrimary)

            Text("As dictation is used in different apps, this panel will show where voice work lands.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(DashboardPalette.textSecondary)
                .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(DashboardPalette.outlineSoft, lineWidth: 1)
                )
        }
    }

    private func appRow(_ app: UsageMetrics.AppMetric) -> some View {
        let share = percentage(for: app)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(DashboardPalette.accentBlue.opacity(0.16))
                        .frame(width: 46, height: 46)

                    Image(systemName: appIcon(for: app.appName))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DashboardPalette.accentCyan)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(app.appName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(DashboardPalette.textPrimary)

                    Text("\(app.words) words")
                        .font(.subheadline)
                        .foregroundStyle(DashboardPalette.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(app.sessions)")
                        .font(.headline.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(DashboardPalette.textPrimary)

                    Text("\(share)%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(DashboardPalette.textSecondary)
                }
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 8)

                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [DashboardPalette.accentBlue, DashboardPalette.accentCyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(18, proxy.size.width * CGFloat(share) / 100), height: 8)
                }
            }
            .frame(height: 8)
        }
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

    private func percentage(for app: UsageMetrics.AppMetric) -> Int {
        guard totalWords > 0 else { return 0 }
        let percent = (Double(app.words) / Double(totalWords)) * 100
        return Int(percent.rounded())
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
        .padding()
        .background(DashboardPalette.background)
        .frame(width: 420)
}
