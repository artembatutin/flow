//
//  OnboardingView.swift
//  FlowPrompter
//
//  Created by Artem Batutin on 2026-01-27.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var permissionsManager: PermissionsManager
    
    @State private var currentStep = 0
    @Environment(\.dismiss) private var dismiss
    
    private let totalSteps = 4
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                .padding()
            
            // Content
            TabView(selection: $currentStep) {
                welcomeStep
                    .tag(0)
                
                microphoneStep
                    .tag(1)
                
                accessibilityStep
                    .tag(2)
                
                completionStep
                    .tag(3)
            }
            .tabViewStyle(.automatic)
            
            // Navigation
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                if currentStep < totalSteps - 1 {
                    Button("Next") {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started") {
                        settingsStore.hasCompletedOnboarding = true
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!permissionsManager.criticalPermissionsGranted)
                }
            }
            .padding()
        }
        .frame(width: 500, height: 450)
    }
    
    // MARK: - Welcome Step
    
    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text("Welcome to FlowPrompter")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Voice dictation that works everywhere on your Mac.\nHold the Fn key to speak, release to inject text.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Microphone Step
    
    private var microphoneStep: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "mic.fill")
                .font(.system(size: 60))
                .foregroundColor(permissionsManager.microphoneGranted ? .green : .orange)
            
            Text("Microphone Access")
                .font(.title)
                .fontWeight(.bold)
            
            Text("FlowPrompter needs access to your microphone to capture your voice for transcription.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            if permissionsManager.microphoneGranted {
                Label("Microphone access granted", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Button("Grant Microphone Access") {
                    Task {
                        await permissionsManager.requestMicrophoneAccess()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Accessibility Step
    
    private var accessibilityStep: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 60))
                .foregroundColor(permissionsManager.accessibilityGranted ? .green : .orange)
            
            Text("Accessibility Access")
                .font(.title)
                .fontWeight(.bold)
            
            Text("FlowPrompter needs Accessibility access to inject transcribed text into applications and detect global hotkeys.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            if permissionsManager.accessibilityGranted {
                Label("Accessibility access granted", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                VStack(spacing: 12) {
                    Button("Open System Settings") {
                        permissionsManager.openAccessibilitySettings()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Text("Add FlowPrompter to the list and enable it.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Check Again") {
                        _ = permissionsManager.checkAccessibilityAccess(prompt: false)
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Completion Step
    
    private var completionStep: some View {
        VStack(spacing: 24) {
            Spacer()
            
            if permissionsManager.criticalPermissionsGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("FlowPrompter is ready to use.\nHold the Fn key to start dictating.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                Text("Permissions Required")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Please grant the required permissions to use FlowPrompter.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    permissionStatus("Microphone", granted: permissionsManager.microphoneGranted)
                    permissionStatus("Accessibility", granted: permissionsManager.accessibilityGranted)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func permissionStatus(_ name: String, granted: Bool) -> some View {
        HStack {
            Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(granted ? .green : .red)
            Text(name)
            Spacer()
            Text(granted ? "Granted" : "Required")
                .foregroundColor(granted ? .green : .red)
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(SettingsStore())
        .environmentObject(PermissionsManager())
}
