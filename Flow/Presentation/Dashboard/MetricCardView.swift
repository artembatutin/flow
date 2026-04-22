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
    let subtitle: String
    let icon: String
    let accent: Color
    let trend: AnalyticsManager.Trend?

    init(
        title: String,
        value: String,
        subtitle: String,
        icon: String,
        accent: Color = DashboardPalette.accentBlue,
        trend: AnalyticsManager.Trend? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.accent = accent
        self.trend = trend
    }

    var body: some View {
        DashboardPanel(padding: 20, radius: 26) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    ZStack {
                        Circle()
                            .fill(accent.opacity(0.18))
                            .frame(width: 46, height: 46)

                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(accent)
                    }

                    Spacer()

                    if let trend {
                        trendBadge(trend)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(title.uppercased())
                        .font(.caption.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(DashboardPalette.textMuted)

                    Text(value)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(DashboardPalette.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(DashboardPalette.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private func trendBadge(_ trend: AnalyticsManager.Trend) -> some View {
        HStack(spacing: 4) {
            switch trend {
            case .up:
                Image(systemName: "arrow.up.right")
                    .font(.caption2.weight(.bold))
            case .down:
                Image(systemName: "arrow.down.right")
                    .font(.caption2.weight(.bold))
            case .neutral:
                Image(systemName: "minus")
                    .font(.caption2.weight(.bold))
            }

            Text(trend.displayText)
                .font(.caption.weight(.bold))
                .monospacedDigit()
        }
        .foregroundStyle(trendColor(trend))
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(trendColor(trend).opacity(0.14))
        .clipShape(Capsule(style: .continuous))
    }

    private func trendColor(_ trend: AnalyticsManager.Trend) -> Color {
        switch trend {
        case .up:
            return DashboardPalette.accentCyan
        case .down:
            return DashboardPalette.accentRose
        case .neutral:
            return DashboardPalette.textSecondary
        }
    }
}

#Preview {
    HStack {
        MetricCardView(
            title: "Words",
            value: "1,234",
            subtitle: "this week",
            icon: "text.word.spacing",
            accent: DashboardPalette.accentBlue,
            trend: .up(percent: 12)
        )

        MetricCardView(
            title: "Sessions",
            value: "45",
            subtitle: "dictation windows",
            icon: "waveform.badge.mic",
            accent: DashboardPalette.accentCyan,
            trend: .down(percent: 5)
        )

        MetricCardView(
            title: "Time Saved",
            value: "2h 15m",
            subtitle: "typing avoided",
            icon: "bolt.fill",
            accent: DashboardPalette.accentAmber,
            trend: .neutral
        )
    }
    .padding()
    .background(DashboardPalette.background)
    .frame(width: 780)
}
