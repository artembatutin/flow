//
//  MetricCardView.swift
//  Flow
//
//  Created by Artem Batutin on 2026-01-27.
//

import SwiftUI

struct MetricCardView: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let trend: AnalyticsManager.Trend?
    
    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        trend: AnalyticsManager.Trend? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.trend = trend
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.accentColor.opacity(0.18))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .foregroundColor(.accentColor)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            HStack {
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let trend = trend {
                    trendBadge(trend)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
    }
    
    @ViewBuilder
    private func trendBadge(_ trend: AnalyticsManager.Trend) -> some View {
        HStack(spacing: 2) {
            switch trend {
            case .up:
                Image(systemName: "arrow.up.right")
                    .font(.caption2)
            case .down:
                Image(systemName: "arrow.down.right")
                    .font(.caption2)
            case .neutral:
                EmptyView()
            }
            
            Text(trend.displayText)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(trendColor(trend))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(trendColor(trend).opacity(0.15))
        .cornerRadius(4)
    }
    
    private func trendColor(_ trend: AnalyticsManager.Trend) -> Color {
        switch trend {
        case .up:
            return .green
        case .down:
            return .red
        case .neutral:
            return .secondary
        }
    }
}

#Preview {
    HStack {
        MetricCardView(
            title: "Words",
            value: "1,234",
            subtitle: "This week",
            icon: "text.word.spacing",
            trend: .up(percent: 12)
        )
        
        MetricCardView(
            title: "Sessions",
            value: "45",
            subtitle: "This week",
            icon: "mic.fill",
            trend: .down(percent: 5)
        )
        
        MetricCardView(
            title: "Time Saved",
            value: "2h 15m",
            subtitle: "This week",
            icon: "clock.fill",
            trend: .neutral
        )
    }
    .padding()
    .frame(width: 500)
}
