# Feature 4.1 — Real-time Streaming Transcription

_Last updated: 2026-02-02_

## Overview
Real-time Streaming Transcription displays partial dictation results while the microphone is still capturing audio. Instead of waiting for recording to stop, users see words appear in the overlay immediately. Confirmed words are rendered with solid styling, while low-confidence pending words appear faded so developers can adjust their speech in the moment. The overlay also surfaces visual confidence hints (typing indicator, pulsing dot) for quick feedback.

Processing order with streaming enabled:
```
AudioEngine (samples) → StreamingTranscriber (chunks) → OverlayView (confirmed/pending text)
                                              ↓
SpeechRecognizer (full buffer) → Post-processing pipeline → TextInjectionService
```

Streaming runs in parallel with the standard offline transcription pass. When the user stops recording, the final Whisper transcription still flows through dictionary → syntax → file tagging → snippets before injection.

## Architecture
| Component | Location | Responsibility |
|-----------|----------|----------------|
| `StreamingState` | `Domain/Models/StreamingState.swift` | Tracks confirmed/pending text, confidence, segment metadata, and session duration. |
| `StreamingTranscriber` | `Infrastructure/Speech/StreamingTranscriber.swift` | Buffers audio samples, slices them into overlapping chunks, calls WhisperKit incrementally, and merges partial transcripts. |
| `AudioStreamDelegateAdapter` | `Infrastructure/Audio/AudioStreamDelegateAdapter.swift` | Bridges `AudioEngine` taps to the streaming transcriber (`appendAudio(_:)`). |
| `OverlayView` + `StreamingTextView` | `Presentation/Overlay/OverlayView.swift`, `Presentation/Overlay/StreamingTextView.swift` | Renders live text (confirmed vs pending) with subtle animations and indicators. |
| `SettingsStore` | `Application/Stores/SettingsStore.swift` | Toggles streaming (`streamingTranscriptionEnabled`) and chunk duration (`streamingChunkDuration`). |
| `AppDependencies` wiring | `Application/AppDependencies.swift` | Creates the streaming transcriber, hooks it into `AudioEngine`, `OverlayWindowController`, and start/stop recording flow. |

### Chunk processing
- Default chunk duration is **1.0s** (`streamingChunkDuration`) with a 0.2s overlap (3200 samples at 16 kHz) to smooth transitions.
- A background task wakes every chunk interval, grabs the latest samples, and calls `WhisperKit.transcribe(audioArray:)` with timestamps disabled for speed.
- The transcriber merges new text with existing confirmed output using lightweight overlap detection + Levenshtein fallback to avoid duplicate word trails.
- Confirmed text is updated as confidence rises or the final pass completes; pending text resets when the main transcription finishes.

### Overlay behaviour
- When recording enters `.listening`, the overlay shows a streaming section if streaming is enabled.
- Confirmed text uses `.primary` color; pending text uses `.secondary.opacity(0.7)` and animates on change.
- If no text is available yet, a `TypingIndicator` displays to reassure users the system is listening.
- Once recording stops and the final transcription arrives, the overlay falls back to the traditional “final preview” block.

## Settings & UI
A new section lives inside the **Overlay** tab (`OverlaySettingsView`):

| Control | Description | AppStorage key | Default |
|---------|-------------|----------------|---------|
| `Real-time Streaming` toggle | Master enable/disable switch. Useful if users prefer the classic experience or have slower machines. | `streamingTranscriptionEnabled` | `true` |
| `Update Interval` slider (0.5–2.0s) | Controls chunk size. Smaller intervals show text faster but may flicker slightly; larger intervals trade responsiveness for accuracy. | `streamingChunkDuration` | `1.0` |

Settings changes take effect on the next recording start. During recording, `AppDependencies.startRecording()` consults the toggle before launching the streaming task.

## Integration points
1. **App startup**: `AppDependencies` instantiates `StreamingTranscriber`, registers it with `OverlayWindowController`, and attaches an `AudioStreamDelegateAdapter` to `AudioEngine.streamDelegate`.
2. **Recording start**:
   - `audioEngine.startRecording()` begins collecting buffers.
   - If streaming is enabled, `startStreamingTranscription()` passes the currently loaded `WhisperKit` instance into the transcriber and kicks off chunk processing.
3. **While listening**: `AudioEngine` forwards every processed buffer to the stream delegate, which pushes samples into the transcriber.
4. **Recording stop**:
   - `StreamingTranscriber.stopStreaming()` finalizes remaining chunks and provides the last streaming snapshot (for diagnostics/logging if desired).
   - The standard `SpeechRecognizer.transcribe` call runs on the full buffer; downstream dictionary/syntax/tagging/snippet steps remain unchanged.

## Extensibility ideas
- **Segment timeline**: expose `segments: [StreamSegment]` in the overlay for per-word highlighting or undo/redo support.
- **Confidence-based styling**: map `StreamingState.confidence` to color/underline variations (e.g., yellow highlight for low confidence).
- **Streaming to IDE adapters**: forward partial text into in-app preview panes for long dictation sessions.
- **Telemetry**: record chunk latency and merging statistics to surface tuning suggestions in Settings (e.g., “Try 0.75s chunks for faster feedback”).

## Troubleshooting
| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Streaming section never appears | Toggle disabled or overlay hidden. | Ensure `Real-time Streaming` and `Show Overlay` are both on in Settings. |
| Text appears but freezes mid-sentence | Chunk duration set very high or WhisperKit still loading. | Reduce `Update Interval` or wait for model load completion before recording. |
| Duplicate or repeated words | Overlap window too small for the dictation pace. | Increase chunk duration slightly; adjust merging heuristics in `mergeTranscription(_:with:)` if necessary. |
| Performance spikes on older Macs | Streaming doubles transcription workload. | Disable the toggle or lengthen update interval to reduce Whisper invocations. |

Keep this document updated as we evolve the streaming UI, add IDE previews, or refine chunk tuning defaults.
