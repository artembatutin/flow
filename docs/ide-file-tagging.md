# Feature 2.2 — IDE Integration: File Tagging

_Last updated: 2026-02-02_

## Overview
The IDE File Tagging feature listens for spoken file mentions (e.g., “at app delegate swift”) while dictating in supported IDEs (Cursor, Windsurf, VS Code, Xcode, JetBrains) and converts them into structured tags such as `@AppDelegate.swift`. Tagged files are surfaced to AI copilots and command palettes so follow-up prompts automatically inherit the right context.

Processing order:
```
SpeechRecognizer → Personal Dictionary → SyntaxTransformer → FileTagger → TextInjectionService
```

Key capabilities:
1. **Workspace discovery** — scans open IDE workspaces via accessibility APIs and file system traversal.
2. **Fuzzy/phonetic matching** — maps noisy spoken variants (“app delegate”, “app delegate swift”) back to canonical filenames.
3. **Inline tagging** — replaces trigger phrases ("at", "@", "file", "tag", "mention") with `@Filename.ext` before text injection.
4. **Live updates** — watches the workspace folder for file additions/removals to keep suggestions fresh.

## Core Components
| Component | Location | Responsibility |
|-----------|----------|----------------|
| `WorkspaceScanner` | `Infrastructure/IDE/WorkspaceScanner.swift` | Scans IDE windows, resolves workspace root, enumerates files, and maintains a cached list (`workspaceFiles`). |
| `WorkspaceFile` | Same file | Represents a file with path, extension, relative path, and generated spoken variants. |
| `FileMatchEngine` | `Infrastructure/IDE/FileMatchEngine.swift` | Provides fuzzy scoring, phonetic variants, and bulk suggestion APIs. |
| `FileTagger` | `Infrastructure/IDE/FileTagger.swift` | Detects trigger phrases via regex, calls the matcher, and performs inline replacements. |
| Settings tab | `Presentation/Settings/SettingsView.swift` (`FileTaggingSettingsView`) | User-facing controls for enabling tagging, scanning, and testing. |
| Wiring | `Application/AppDependencies.swift` | Instantiates `WorkspaceScanner`/`FileTagger`, kicks off scans when recording starts, and inserts tagging into the transcription pipeline. |

## Workspace scanning workflow
1. **Recording start** (`AppDependencies.startRecording()`):
   - Capture frontmost app via `textInjector.getFrontmostApp()`.
   - If the adapter is `IDE` and `autoScanWorkspace` is enabled, call `workspaceScanner.scanFromFrontmostIDE()` in a Task.
2. **Accessibility-derived context**:
   - Inspect window titles/document attributes to infer current file paths.
   - Attempt to deduce workspace root from IDE-specific window title patterns.
3. **File system sweep** (`scanDirectory(_:)`):
   - Enumerate from the detected root, skipping ignored directories (`node_modules`, `.git`, `DerivedData`, etc.) and filtering to developer-relevant extensions (Swift, JS/TS, web, Python, Go, Rust, Kotlin, configs, Markdown, etc.).
4. **Spoken variants**:
   - `WorkspaceFile` precomputes variants by splitting camelCase, snake_case, kebab-case, and appending extensions (“app delegate”, “app delegate swift”, “appdelegate”).
5. **Live watching**:
   - `startWatching()` installs a `DispatchSourceFileSystemObject` that re-runs scans on write/delete/rename events; `stopWatching()` tears it down when needed.

## Matching and tagging
1. **Pattern detection**: `FileTagger` compiles regexes for phrases like `"at <name>"`, `"@ <name>"`, `"file <name>"`, etc. Matches capture the candidate spoken filename while ignoring trailing punctuation.
2. **Normalization**: Captured text is lowercased, stripped of stop words (“the”, “please”, etc.), and truncated to a reasonable length before matching.
3. **Fuzzy scoring** (`FileMatchEngine.fuzzyScore`):
   - Quick wins for exact/prefix/substring matches.
   - Word-by-word scoring to handle rearranged terms.
   - Levenshtein distance fallback for noisy recognition.
   - Minimum threshold (`0.5` by default) avoids spurious tags. Developers can tune this via `fileTaggingMinScore` if desired.
4. **Replacement**: When a result exceeds the threshold, the entire trigger phrase is replaced with `@<actual-file-name-with-extension>`. Multiple occurrences are processed right-to-left to preserve string indices.
5. **Suggestions**: `getSuggestions(for:)` exposes the same matching logic for future UI integrations (e.g., autocompletion hints inside the overlay).

## Settings & UI
`SettingsStore` exposes three AppStorage keys:
| Key | Default | Description |
|-----|---------|-------------|
| `fileTaggingEnabled` | `true` | Master toggle; disables both scanning and replacement when off. |
| `autoScanWorkspace` | `true` | Automatically gather file metadata whenever recording starts in an IDE. |
| `fileTaggingMinScore` | `0.5` | Global threshold used by `FileMatchEngine`; lower values make the matcher more permissive. |

`FileTaggingSettingsView` (new Settings tab):
- Toggles for enable/disable and auto-scan.
- Displays workspace statistics (root folder, file count, last scan timestamp).
- Provides **Scan Now** and **Clear Cache** actions.
- Includes a test harness where users can type phrases (“at main view model”) and see the transformed output.
- Shows a preview list of the first 10 discovered files for sanity checking.

## Runtime integration
1. `AppDependencies` constructs `workspaceScanner` + `fileTagger`, syncs the `fileTagger.isEnabled` flag with `SettingsStore`, and injects them into SwiftUI environment objects so the Settings tab can access live data.
2. After transcription:
   - Personal dictionary applies (`dictionaryEnabled`).
   - Syntax transformer runs if `syntaxTransformEnabled`.
   - File tagging executes next when `fileTaggingEnabled`.
3. When auto-injecting, the resulting string already contains the canonical `@Filename.ext` markers, so IDE copilots can immediately resolve references.

## Extensibility
- **IDE-specific heuristics**: Add bundle-aware parsing to `extractWorkspacePathFromTitle` for JetBrains Rider, IntelliJ toolboxes, etc.
- **Custom trigger phrases**: Offer user-editable patterns or localized equivalents.
- **Per-project overrides**: Cache multiple workspace roots and switch based on the current frontmost app/document path.
- **Telemetry hooks**: Record match confidence to surface diagnostics in the Settings tab (e.g., “3 tags skipped due to low confidence”).

Keep this document updated whenever new IDE adapters, matching heuristics, or UI affordances are added.
