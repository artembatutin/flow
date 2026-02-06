//
//  StreamingTextView.swift
//  FlowPrompter
//
//  Created by Artem Batutin on 2026-01-27.
//

import SwiftUI

/// A view that displays streaming transcription text with visual distinction
/// between confirmed and pending (uncertain) text
struct StreamingTextView: View {
    @ObservedObject var transcriber: StreamingTranscriber
    
    var body: some View {
        HStack(spacing: 0) {
            if !transcriber.confirmedText.isEmpty || !transcriber.pendingText.isEmpty {
                Text(transcriber.confirmedText)
                    .foregroundColor(.primary)
                
                Text(transcriber.pendingText)
                    .foregroundColor(.secondary.opacity(0.7))
                    .animation(.easeInOut(duration: 0.2), value: transcriber.pendingText)
            } else if transcriber.isStreaming {
                Text("Listening...")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .font(.system(.body, design: .rounded))
        .lineLimit(3)
        .truncationMode(.head)
    }
}

/// A more detailed streaming text view with confidence indicator
struct DetailedStreamingTextView: View {
    @ObservedObject var transcriber: StreamingTranscriber
    let showConfidence: Bool
    
    init(transcriber: StreamingTranscriber, showConfidence: Bool = false) {
        self.transcriber = transcriber
        self.showConfidence = showConfidence
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 0) {
                Text(transcriber.confirmedText)
                    .foregroundColor(.primary)
                
                Text(transcriber.pendingText)
                    .foregroundColor(pendingTextColor)
                    .animation(.easeInOut(duration: 0.15), value: transcriber.pendingText)
                
                if transcriber.isStreaming && transcriber.pendingText.isEmpty && transcriber.confirmedText.isEmpty {
                    TypingIndicator()
                }
            }
            .font(.system(size: 13, design: .rounded))
            .lineLimit(4)
            .truncationMode(.head)
            
            if showConfidence && transcriber.isStreaming {
                HStack(spacing: 4) {
                    Circle()
                        .fill(confidenceColor)
                        .frame(width: 6, height: 6)
                    
                    Text(confidenceLabel)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var pendingTextColor: Color {
        let confidence = transcriber.streamingState.confidence
        if confidence > 0.8 {
            return .secondary.opacity(0.8)
        } else if confidence > 0.5 {
            return .orange.opacity(0.7)
        } else {
            return .red.opacity(0.6)
        }
    }
    
    private var confidenceColor: Color {
        let confidence = transcriber.streamingState.confidence
        if confidence > 0.8 {
            return .green
        } else if confidence > 0.5 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var confidenceLabel: String {
        let confidence = transcriber.streamingState.confidence
        if confidence > 0.8 {
            return "High confidence"
        } else if confidence > 0.5 {
            return "Medium confidence"
        } else {
            return "Low confidence"
        }
    }
}

/// A simple typing indicator animation
struct TypingIndicator: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 4, height: 4)
                    .opacity(animationPhase == index ? 1.0 : 0.3)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

/// Compact streaming indicator for the overlay
struct CompactStreamingIndicator: View {
    @ObservedObject var transcriber: StreamingTranscriber
    
    var body: some View {
        HStack(spacing: 6) {
            if transcriber.isStreaming {
                PulsingDot()
                
                if !transcriber.streamingText.isEmpty {
                    Text(truncatedText)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                } else {
                    Text("Listening...")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
    }
    
    private var truncatedText: String {
        let text = transcriber.streamingText
        if text.count > 50 {
            return "..." + String(text.suffix(47))
        }
        return text
    }
}

/// A pulsing dot indicator
struct PulsingDot: View {
    @State private var isPulsing = false
    
    var body: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 8, height: 8)
            .scaleEffect(isPulsing ? 1.2 : 0.8)
            .opacity(isPulsing ? 1.0 : 0.6)
            .animation(
                .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

#Preview("Streaming Text View") {
    let transcriber = StreamingTranscriber()
    
    return VStack(spacing: 20) {
        StreamingTextView(transcriber: transcriber)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        
        DetailedStreamingTextView(transcriber: transcriber, showConfidence: true)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        
        CompactStreamingIndicator(transcriber: transcriber)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
    }
    .padding()
}
