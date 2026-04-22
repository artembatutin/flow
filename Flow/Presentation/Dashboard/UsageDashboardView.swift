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
        let subtitle: String?
        let icon: String
        let trend: AnalyticsManager.Trend?
        
        init(title: String, value: String, subtitle: String?, icon: String, trend: AnalyticsManager.Trend? = nil) {
            self.title = title
            self.value = value
            self.subtitle = subtitle
            self.icon = icon
            self.trend = trend
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                periodPicker
                keyMetricsSection
                usageChartSection
                
                HStack(alignment: .top, spacing: 16) {
                    appBreakdownSection
                    streaksSection
                }
            }
            .padding(24)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Period Picker
    
    private var periodPicker: some View {
        HStack {
            Text("Dashboard")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            Picker("Period", selection: $selectedPeriod) {
                ForEach(AnalyticsManager.Period.allCases) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 250)
        }
    }
    
    // MARK: - Key Metrics Section
    
    private var keyMetricsSection: some View {
        let totals = analyticsManager.getTotals(for: selectedPeriod)
        let trend = analyticsManager.calculateTrend(for: selectedPeriod)
        
        let cardConfigs: [MetricCardConfig] = [
            MetricCardConfig(
                title: "Words Dictated",
                value: formatNumber(totals.words),
                subtitle: periodSubtitle,
                icon: "text.word.spacing",
                trend: selectedPeriod != .allTime ? trend : nil
            ),
            MetricCardConfig(
                title: "Sessions",
                value: "\(totals.sessions)",
                subtitle: periodSubtitle,
                icon: "mic.fill"
            ),
            MetricCardConfig(
                title: "Time Saved",
                value: formatTimeSaved(totals.timeSaved),
                subtitle: "vs typing",
                icon: "clock.fill"
            ),
            MetricCardConfig(
                title: "Avg Words/Session",
                value: totals.sessions > 0 ? "\(totals.words / max(1, totals.sessions))" : "0",
                subtitle: "per session",
                icon: "chart.bar.fill"
            )
        ]
        
        return LazyVGrid(columns: metricGridColumns, spacing: 16) {
            ForEach(cardConfigs) { config in
                MetricCardView(
                    title: config.title,
                    value: config.value,
                    subtitle: config.subtitle,
                    icon: config.icon,
                    trend: config.trend
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var metricGridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 220, maximum: 260), spacing: 16, alignment: .top)]
    }
    
    // MARK: - Usage Chart Section
    
    private var usageChartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Spacer()
                Picker("Metric", selection: $selectedChartMetric) {
                    ForEach(UsageChartView.ChartMetric.allCases) { metric in
                        Text(metric.rawValue).tag(metric)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            
            UsageChartView(
                data: chartData,
                metric: selectedChartMetric
            )
        }
    }
    
    private var chartData: [UsageMetrics.DailyMetric] {
        analyticsManager.getMetrics(for: selectedPeriod)
    }
    
    // MARK: - App Breakdown Section
    
    private var appBreakdownSection: some View {
        AppBreakdownView(apps: analyticsManager.topApps)
            .frame(maxWidth: .infinity)
    }
    
    // MARK: - Streaks Section
    
    private var streaksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Streaks")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                streakCard(
                    title: "Current",
                    value: analyticsManager.metrics.currentStreak,
                    icon: "flame.fill",
                    color: .orange
                )
                
                streakCard(
                    title: "Best",
                    value: analyticsManager.metrics.longestStreak,
                    icon: "trophy.fill",
                    color: .yellow
                )
            }
            
            if let lastActive = analyticsManager.metrics.lastActiveDate {
                Text("Last active: \(formatLastActive(lastActive))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func streakCard(title: String, value: Int, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            
            Text("\(value)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            
            Text("\(title) \(value == 1 ? "day" : "days")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
    
    // MARK: - Helpers
    
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
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

#Preview {
    UsageDashboardView(analyticsManager: AnalyticsManager())
        .frame(width: 500, height: 500)
}
