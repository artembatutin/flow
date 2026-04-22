//
//  AudioLevelView.swift
//  Flow
//
//  Created by Artem Batutin on 2026-01-27.
//

import SwiftUI

/// A visual audio level indicator with animated bars
struct AudioLevelView: View {
    let level: Float
    let barCount: Int
    let style: Style
    
    enum Style {
        case bars
        case waveform
        case dot
    }
    
    init(level: Float, barCount: Int = 5, style: Style = .bars) {
        self.level = level
        self.barCount = barCount
        self.style = style
    }
    
    var body: some View {
        switch style {
        case .bars:
            barsView
        case .waveform:
            waveformView
        case .dot:
            dotView
        }
    }
    
    // MARK: - Bar Style
    
    private var barsView: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(barColor(for: index))
                    .frame(width: 3, height: barHeight(for: index))
                    .animation(.easeOut(duration: 0.1), value: level)
            }
        }
    }
    
    private func barColor(for index: Int) -> Color {
        let threshold = Float(index) / Float(barCount)
        if level > threshold {
            // Gradient from green to yellow to red
            if index < barCount / 2 {
                return .green
            } else if index < barCount * 3 / 4 {
                return .yellow
            } else {
                return .orange
            }
        }
        return Color.gray.opacity(0.3)
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        CGFloat(4 + index * 2)
    }
    
    // MARK: - Waveform Style
    
    private var waveformView: some View {
        HStack(spacing: 1) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.green)
                    .frame(width: 2, height: waveformHeight(for: index))
                    .animation(.easeInOut(duration: 0.15), value: level)
            }
        }
    }
    
    private func waveformHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 4
        let maxHeight: CGFloat = 16
        let variation = sin(Double(index) * 0.8) * 0.3 + 0.7
        return baseHeight + (maxHeight - baseHeight) * CGFloat(level) * CGFloat(variation)
    }
    
    // MARK: - Dot Style
    
    private var dotView: some View {
        Circle()
            .fill(dotColor)
            .frame(width: 8, height: 8)
            .scaleEffect(1.0 + CGFloat(level) * 0.5)
            .animation(.easeInOut(duration: 0.1), value: level)
    }
    
    private var dotColor: Color {
        if level > 0.7 {
            return .orange
        } else if level > 0.3 {
            return .green
        } else if level > 0.05 {
            return .green.opacity(0.7)
        }
        return .gray.opacity(0.5)
    }
}

/// A more elaborate recording indicator with pulsing animation
struct RecordingIndicator: View {
    let isRecording: Bool
    let audioLevel: Float
    
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Outer pulse ring
            if isRecording {
                Circle()
                    .stroke(Color.red.opacity(0.3), lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .scaleEffect(isPulsing ? 1.3 : 1.0)
                    .opacity(isPulsing ? 0.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: false),
                        value: isPulsing
                    )
            }
            
            // Inner circle
            Circle()
                .fill(isRecording ? Color.red : Color.gray)
                .frame(width: 12, height: 12)
                .scaleEffect(isRecording ? 1.0 + CGFloat(audioLevel) * 0.3 : 1.0)
                .animation(.easeOut(duration: 0.1), value: audioLevel)
        }
        .onChange(of: isRecording) { _, newValue in
            isPulsing = newValue
        }
        .onAppear {
            if isRecording {
                isPulsing = true
            }
        }
    }
}

/// Duration display for recording
struct RecordingDurationView: View {
    let duration: TimeInterval
    let maxDuration: TimeInterval?
    
    var body: some View {
        HStack(spacing: 4) {
            Text(formattedDuration)
                .font(.caption.monospacedDigit())
                .foregroundColor(.primary)
            
            if let max = maxDuration {
                Text("/")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatDuration(max))
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var formattedDuration: String {
        formatDuration(duration)
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Previews

#Preview("Audio Level Bars") {
    VStack(spacing: 20) {
        AudioLevelView(level: 0.0)
        AudioLevelView(level: 0.3)
        AudioLevelView(level: 0.6)
        AudioLevelView(level: 1.0)
    }
    .padding()
}

#Preview("Audio Level Waveform") {
    VStack(spacing: 20) {
        AudioLevelView(level: 0.3, style: .waveform)
        AudioLevelView(level: 0.7, style: .waveform)
    }
    .padding()
}

#Preview("Recording Indicator") {
    VStack(spacing: 20) {
        RecordingIndicator(isRecording: false, audioLevel: 0.0)
        RecordingIndicator(isRecording: true, audioLevel: 0.5)
    }
    .padding()
}

#Preview("Recording Duration") {
    VStack(spacing: 20) {
        RecordingDurationView(duration: 45, maxDuration: 120)
        RecordingDurationView(duration: 90, maxDuration: nil)
    }
    .padding()
}
