# Inkstone 🖌️

**Inkstone** (this repository keeps its original name, `Inkwell`) is an iPad application built with SwiftUI designed to teach and practice hand-writing Chinese characters with authentic stroke order recognition and interactive feedback.

> **Why two names?** App Review rejected the original name "Inkwell" under
> Guideline 5.2.5 — it's on Apple's trademark list (the old Mac OS X
> handwriting-recognition feature). The user-facing app is **Inkstone**; the
> repo, Xcode project, targets, and bundle ID keep the internal name
> `Inkwell` so URLs and project history stay stable.

## Features (Planned & In Progress)
- ✍️ **Apple Pencil & Touch Canvas:** Ultra-responsive drawing canvas using PencilKit.
- 📐 **Stroke Order Verification:** Real-time feedback on stroke direction, sequence, and precision.
- 📚 **Character Library:** Comprehensive Hanzi dataset for beginner to advanced practice.
- 🎯 **Interactive Modes:** Guided tracing, ghost outlines, self-test memory drills.

## AI Agent Collaboration
This repository is configured with guidelines for autonomous coding agents (Gemini, Claude Code, OpenAI Codex). See [`AGENTS.md`](AGENTS.md) for architectural instructions and project guidelines.

## Development Setup
- **Platform:** iPadOS 17+
- **IDE:** Xcode 15+
- **Language:** Swift 5.9+ / SwiftUI

```bash
# Build project via command line
xcodebuild -project Inkwell.xcodeproj -scheme Inkwell -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch) (6th generation)' build
```
