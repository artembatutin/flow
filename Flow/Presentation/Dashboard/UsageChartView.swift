//
//  UsageChartView.swift
//  Flow
//
//  Created by Artem Batutin on 2026-01-27.
//

import SwiftUI
import Charts

struct UsageChartView: View {
    let data: [UsageMetrics.DailyMetric]
    let metric: ChartMetric
    
    enum ChartMetric: String, CaseIterable, Identifiable {
        case words = "Words"
        case sessions = "Sessions"
        case timeSaved = "Time Saved"
        
        var id: String { rawValue }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            if data.isEmpty || data.allSatisfy({ getValue(for: $0) == 0 }) {
                emptyStateView
            } else {
                chartView
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
            Image(systemName: "chart.bar")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            Text("No data yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Start dictating to see your stats here")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.8))
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }
    
    private var chartView: some View {
        Chart(data) { metric in
            BarMark(
                x: .value("Date", metric.displayDate),
                y: .value(self.metric.rawValue, getValue(for: metric))
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.accentColor, .accentColor.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel {
                    if let dateStr = value.as(String.self) {
                        Text(dateStr)
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text(formatYAxisValue(intValue))
                            .font(.caption2)
                    }
                }
            }
        }
        .frame(height: 150)
    }
    
    private func getValue(for metric: UsageMetrics.DailyMetric) -> Int {
        switch self.metric {
        case .words:
            return metric.words
        case .sessions:
            return metric.sessions
        case .timeSaved:
            return Int(metric.timeSaved / 60)
        }
    }
    
    private func formatYAxisValue(_ value: Int) -> String {
        switch metric {
        case .words:
            if value >= 1000 {
                return "\(value / 1000)k"
            }
            return "\(value)"
        case .sessions:
            return "\(value)"
        case .timeSaved:
            return "\(value)m"
        }
    }
}

#Preview {
    let sampleData: [UsageMetrics.DailyMetric] = [
        UsageMetrics.DailyMetric(dateString: "2026-01-21", sessions: 5, words: 150),
        UsageMetrics.DailyMetric(dateString: "2026-01-22", sessions: 8, words: 280),
        UsageMetrics.DailyMetric(dateString: "2026-01-23", sessions: 3, words: 90),
        UsageMetrics.DailyMetric(dateString: "2026-01-24", sessions: 12, words: 450),
        UsageMetrics.DailyMetric(dateString: "2026-01-25", sessions: 6, words: 200),
        UsageMetrics.DailyMetric(dateString: "2026-01-26", sessions: 9, words: 320),
        UsageMetrics.DailyMetric(dateString: "2026-01-27", sessions: 4, words: 180),
    ]
    
    UsageChartView(data: sampleData, metric: .words)
        .frame(width: 450)
        .padding()
}
