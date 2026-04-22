# Feature 3.1 — Snippets Library

_Last updated: 2026-02-02_

## Overview
The Snippets Library delivers voice-triggered text expansion inside Flow. Users speak a trigger phrase (e.g., "react component"), and Flow replaces that phrase with rich text that may contain placeholders such as `{date}` or `{cursor}`. Snippets participate in the same transcription pipeline as dictionaries, syntax transforms, and file tagging, ensuring downstream editors receive fully expanded text with cursor placement metadata.

Pipeline segment:
```
SpeechRecognizer → DictionaryManager → SyntaxTransformer → FileTagger → SnippetManager → TextInjectionService
```

Highlights
1. **Trigger detection** – matches spoken phrases anywhere in the transcription, respecting app-specific restrictions.
2. **Placeholder resolution** – injects live context (date, time, clipboard, selected text, active app) and tracks cursor placement.
3. **Built-in templates** – ships with 20 productivity snippets spanning email, code, meetings, work tracking, and personal utilities.
4. **Full CRUD experience** – Settings tab exposes creation, edit, duplication, enable/disable, preview, import/export, and clearing.

## Core Components
| Component | Location | Responsibility |
|-----------|----------|----------------|
| `Snippet` | `Domain/Models/Snippet.swift` | Data model with categories, metadata, placeholder catalog, and usage stats. |
| `SnippetStore` | `Application/Stores/SnippetStore.swift` | Actor-based persistence layer (JSON file under `~/Library/Application Support/Flow/snippets.json`). |
| `SnippetManager` | `Application/Managers/SnippetManager.swift` | CRUD, filtering, trigger detection, placeholder resolution, built-in seed data. |
| `PlaceholderResolver` | `Infrastructure/Snippets/PlaceholderResolver.swift` | Replaces placeholders, captures cursor index, reads clipboard/app context. |
| `SnippetsSettingsView` | `Presentation/Snippets/SnippetsSettingsView.swift` | Settings tab container (toggles, search, filters, import/export, list view). |
| `SnippetRowView` | `Presentation/Snippets/SnippetRowView.swift` | Row renderer with enable toggle, preview sheet, duplication, edit shortcuts. |
| `SnippetEditorView` | `Presentation/Snippets/SnippetEditorView.swift` | Add/edit sheet with placeholder chips, validation, delete confirmation. |
| Integration | `Application/AppDependencies.swift`, `FlowApp.swift`, `SettingsStore.swift`, `Presentation/Settings/SettingsView.swift` | Wires manager into pipeline, exposes AppStorage toggle, injects environment objects, adds Settings tab. |

## Settings & Environment
`SettingsStore` introduces `@AppStorage("snippetsEnabled")` (default `true`). When disabled, the pipeline skips snippet detection/expansion.

`AppDependencies` creates a singleton `SnippetManager`, feeds it into SwiftUI environment objects, and inserts `snippetManager.processText(_:bundleId:)` after file tagging inside `stopRecordingAndTranscribe()`. The target app's bundle identifier is passed to enforce per-app restrictions.

FlowApp propagates `snippetManager` to Menu Bar, Onboarding, and Settings scenes so the UI can access live data.

## UI/UX Flow
1. Open **Settings → Snippets** (new tab between Dictionary and File Tagging).
2. Use the header toggles to enable/disable snippets globally.
3. Search snippets via the inline search bar; filter by category (email, code, meeting, personal, work, custom).
4. Create new snippets with the ⊕ button → Snippet Editor (fields: name, trigger, content, category, enable toggle). Insert placeholders via chips.
5. Manage entries from the list:
   - Enable/disable toggle
   - Preview placeholder-resolved content via the eye icon
   - Edit (pencil), duplicate, or delete (swipe or editor sheet)
6. Overflow menu includes **Load Built-in Snippets**, **Import…**, **Export…**, **Clear All…**.
7. Import/export use NSSave/Open panels and JSON payloads compatible across installs.

## Placeholder System
`PlaceholderResolver` understands the following tokens:
| Placeholder | Description |
|-------------|-------------|
| `{date}` | Current date (medium style) |
| `{time}` | Current time (short style) |
| `{datetime}` | Combined date/time |
| `{clipboard}` | Clipboard string (or supplied context) |
| `{app}` | Name of the frontmost app receiving text |
| `{cursor}` | Marks where the caret should land post-injection |
| `{selected}` | Placeholder for selected text (if provided) |

Resolution order: date/time → app → clipboard → selected text → cursor tracking. `{cursor}` is removed from the text and its character index is returned so future injection tooling can reposition the caret.

## Trigger Detection & Expansion
1. `SnippetManager.findSnippetInText(_:bundleId:)` lowercases the transcription, sorts snippets by trigger length, and runs regex word-boundary searches to find the first enabled match that meets app restrictions.
2. On match:
   - Resolve content via `PlaceholderResolver`, passing `NSWorkspace.shared.frontmostApplication?.localizedName`, clipboard contents, and timestamps.
   - Replace the matched substring in the original transcription with resolved text.
   - Increment `useCount` and update `lastUsedAt` for analytics.
3. The resulting string continues through injection, so users see the final expanded snippet in their target app immediately.

## Built-in Snippets
`BuiltInSnippets` (defined at the bottom of `SnippetManager.swift`) seeds 20 snippets grouped across categories:
- Email: signature, thank-you, follow-up.
- Code: React hooks/components, Swift struct/View, TypeScript interface, snippets for `useState`, `useEffect`, etc.
- Meetings/Work: meeting notes, daily standup, bug report, PR template.
- Personal utilities: `{date}`, `{time}`, `{datetime}` quick inserts.

Loading built-ins (via the overflow menu or by calling `loadBuiltInSnippets()`) is idempotent—they only add snippets whose triggers are absent.

## Persistence & Import/Export
- Data lives at `~/Library/Application Support/Flow/snippets.json` managed by `SnippetStore`. The actor caches data in memory to minimize disk access.
- Import supports merge semantics by default; duplicate triggers are ignored unless "Replace" behavior is added later.
- Export writes prettified JSON arrays of `Snippet` objects (same schema as storage) enabling easy sync or sharing.

## Extensibility Ideas
1. **App-specific snippets** – allow selecting bundles directly inside the editor (the model already stores `appRestrictions`).
2. **Overlay picker** – expose snippet suggestions inside the recording overlay for mouse-driven invocation.
3. **Statistics dashboard** – reuse `useCount`/`lastUsedAt` to surface "Top snippets" inside Settings or the future Usage Dashboard.
4. **Collaboration** – support remote snippet packs with trust prompts before installation.

Keep this document updated whenever new placeholders, categories, import formats, or UI affordances ship.
