//
//  UsageDashboardView.swift
//  Flow
//
//  Created by Artem Batutin on 2026-01-27.
//

import SwiftUI

struct UsageDashboardView: View {
    @ObservedObject var analyticsManager: AnalyticsManager
    @State private var selectedPeriod: AnalyticsManager.Period = .week
    @State private var selectedChartMetric: UsageChartView.ChartMetric = .words

    private struct MetricCardConfig: Identifiable {
        let id = UUID()
        let title: String
        let value: String
        let subtitle: String
        let icon: String
        let accent: Color
        let trend: AnalyticsManager.Trend?
    }

    private var totals: (sessions: Int, words: Int, timeSaved: TimeInterval) {
        analyticsManager.getTotals(for: selectedPeriod)
    }

    private var averageWordsPerSession: Int {
        totals.sessions > 0 ? totals.words / totals.sessions : 0
    }

    private var chartData: [UsageMetrics.DailyMetric] {
        analyticsManager.getMetrics(for: selectedPeriod)
    }

    private var periodTrend: AnalyticsManager.Trend {
        analyticsManager.calculateTrend(for: selectedPeriod)
    }

    private var topApp: UsageMetrics.AppMetric? {
        analyticsManager.getTopApps(limit: 1).first
    }

    private var peakDay: UsageMetrics.DailyMetric? {
        chartData.max(by: { metricValue(for: $0, metric: selectedChartMetric) < metricValue(for: $1, metric: selectedChartMetric) })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroSection
                keyMetricsSection

                HStack(alignment: .top, spacing: 20) {
                    usageChartSection
                        .frame(maxWidth: .infinity)

                    insightsRail
                        .frame(width: 280)
                }

                HStack(alignment: .top, spacing: 20) {
                    appBreakdownSection
                    streaksSection
                }
            }
            .padding(.bottom, 6)
        }
        .scrollIndicators(.hidden)
        .background(Color.clear)
    }

    private var heroSection: some View {
        DashboardPanel {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("VOICE OUTPUT")
                            .font(.caption.weight(.bold))
                            .tracking(2.2)
                            .foregroundStyle(DashboardPalette.textMuted)

                        Text("See the pace of dictation, not just the totals.")
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .foregroundStyle(DashboardPalette.textPrimary)

                        Text("Track how output changes across the day, which apps absorb the most speech, and where the time savings compound.")
                            .font(.title3)
                            .foregroundStyle(DashboardPalette.textSecondary)
                            .frame(maxWidth: 640, alignment: .leading)
                    }

                    Spacer(minLength: 0)

                    DashboardPillPicker(options: AnalyticsManager.Period.allCases, selection: $selectedPeriod) { period, _ in
                        Text(period.rawValue)
                            .font(.subheadline.weight(.semibold))
                    }
                }

                HStack(spacing: 14) {
                    DashboardMetricStrip(
                        eyebrow: "Words",
                        value: formatNumber(totals.words),
                        caption: periodSubtitle,
                        accent: DashboardPalette.accentBlue
                    )

                    DashboardMetricStrip(
                        eyebrow: "Sessions",
                        value: "\(totals.sessions)",
                        caption: totals.sessions == 1 ? "single capture" : "captured sessions",
                        accent: DashboardPalette.accentCyan
                    )

                    DashboardMetricStrip(
                        eyebrow: "Time Saved",
                        value: formatTimeSaved(totals.timeSaved),
                        caption: "versus typing",
                        accent: DashboardPalette.accentAmber
                    )
                }
            }
        }
    }

    private var keyMetricsSection: some View {
        let cardConfigs: [MetricCardConfig] = [
            MetricCardConfig(
                title: "Words Dictated",
                value: formatNumber(totals.words),
                subtitle: periodSubtitle,
                icon: "text.word.spacing",
                accent: DashboardPalette.accentBlue,
                trend: selectedPeriod == .allTime ? nil : periodTrend
            ),
            MetricCardConfig(
                title: "Sessions",
                value: "\(totals.sessions)",
                subtitle: "dictation windows",
                icon: "waveform.badge.mic",
                accent: DashboardPalette.accentCyan,
                trend: nil
            ),
            MetricCardConfig(
                title: "Time Saved",
                value: formatTimeSaved(totals.timeSaved),
                subtitle: "typing time avoided",
                icon: "bolt.fill",
                accent: DashboardPalette.accentAmber,
                trend: nil
            ),
            MetricCardConfig(
                title: "Avg Words / Session",
                value: "\(averageWordsPerSession)",
                subtitle: "average density",
                icon: "chart.bar.xaxis",
                accent: DashboardPalette.accentRose,
                trend: nil
            )
        ]

        return LazyVGrid(columns: metricGridColumns, spacing: 16) {
            ForEach(cardConfigs) { config in
                MetricCardView(
                    title: config.title,
                    value: config.value,
                    subtitle: config.subtitle,
                    icon: config.icon,
                    accent: config.accent,
                    trend: config.trend
                )
            }
        }
    }

    private var metricGridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 220, maximum: 260), spacing: 16, alignment: .top)]
    }

    private var usageChartSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Activity curve")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(DashboardPalette.textPrimary)
                    Text("Switch metrics to compare raw output, cadence, and time returned.")
                        .font(.subheadline)
                        .foregroundStyle(DashboardPalette.textSecondary)
                }

                Spacer()

                DashboardPillPicker(options: UsageChartView.ChartMetric.allCases, selection: $selectedChartMetric) { metric, _ in
                    Text(metric.rawValue)
                        .font(.subheadline.weight(.semibold))
                }
            }

            UsageChartView(
                data: chartData,
                metric: selectedChartMetric
            )
        }
    }

    private var insightsRail: some View {
        VStack(spacing: 16) {
            DashboardPanel(padding: 20) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Pulse")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(DashboardPalette.textPrimary)

                    insightRow("Trend", value: periodTrend.displayText, accent: periodTrend.isPositive ? DashboardPalette.accentCyan : DashboardPalette.accentRose)
                    insightRow("Peak day", value: peakDay?.displayDate ?? "No data", accent: DashboardPalette.accentBlue)
                    insightRow("Top app", value: topApp?.appName ?? "Waiting", accent: DashboardPalette.accentAmber)
                }
            }

            DashboardPanel(padding: 20) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Throughput")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(DashboardPalette.textPrimary)

                    Text(formatNumber(totals.words))
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(DashboardPalette.textPrimary)

                    Text("Total dictated during the selected window.")
                        .font(.subheadline)
                        .foregroundStyle(DashboardPalette.textSecondary)

                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [DashboardPalette.accentBlue, DashboardPalette.accentCyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 10)
                        .overlay(alignment: .leading) {
                            Capsule(style: .continuous)
                                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                        }
                }
            }
        }
    }

    private var appBreakdownSection: some View {
        AppBreakdownView(apps: analyticsManager.topApps)
            .frame(maxWidth: .infinity)
    }

    private var streaksSection: some View {
        DashboardPanel(padding: 22) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Streaks")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(DashboardPalette.textPrimary)

                HStack(spacing: 14) {
                    streakCard(
                        title: "Current",
                        value: analyticsManager.metrics.currentStreak,
                        caption: "days in motion",
                        icon: "flame.fill",
                        accent: DashboardPalette.accentAmber
                    )

                    streakCard(
                        title: "Best",
                        value: analyticsManager.metrics.longestStreak,
                        caption: "days record",
                        icon: "trophy.fill",
                        accent: DashboardPalette.accentCyan
                    )
                }

                if let lastActive = analyticsManager.metrics.lastActiveDate {
                    Text("Last active \(formatLastActive(lastActive))")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(DashboardPalette.textSecondary)
                } else {
                    Text("No activity recorded yet.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(DashboardPalette.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func streakCard(
        title: String,
        value: Int,
        caption: String,
        icon: String,
        accent: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.18))
                    .frame(width: 54, height: 54)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(accent)
            }

            Text("\(value)")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(DashboardPalette.textPrimary)

            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(DashboardPalette.textPrimary)

            Text(caption)
                .font(.subheadline)
                .foregroundStyle(DashboardPalette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(DashboardPalette.outlineSoft, lineWidth: 1)
                )
        }
    }

    private func insightRow(_ title: String, value: String, accent: Color) -> some View {
        HStack {
            Circle()
                .fill(accent)
                .frame(width: 10, height: 10)

            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(DashboardPalette.textSecondary)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(DashboardPalette.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func metricValue(for metric: UsageMetrics.DailyMetric, metric selectedMetric: UsageChartView.ChartMetric) -> Int {
        switch selectedMetric {
        case .words:
            return metric.words
        case .sessions:
            return metric.sessions
        case .timeSaved:
            return Int(metric.timeSaved / 60)
        }
    }

    private var periodSubtitle: String {
        switch selectedPeriod {
        case .today:
            return "today"
        case .week:
            return "this week"
        case .month:
            return "this month"
        case .allTime:
            return "all time"
        }
    }

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    private func formatTimeSaved(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "< 1m"
        }
    }

    private func formatLastActive(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "today"
        } else if calendar.isDateInYesterday(date) {
            return "yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}
