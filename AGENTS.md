# AGENTS.md

Instructions and guidelines for autonomous coding agents (Gemini, Claude Code, OpenAI Codex, etc.) working on **Inkwell**.

## Project Overview
**Inkwell** is an iPad application built in SwiftUI designed to help users practice hand-writing Chinese characters (Hanzi) in the correct stroke order.

## Tech Stack & Architecture
- **Framework:** SwiftUI (Targeting iPadOS)
- **Drawing Canvas:** PencilKit / Custom Canvas for Apple Pencil & touch input
- **Data Persistence:** SwiftData
- **Data & Stroke Order Engine:** Structured Chinese stroke data (e.g., SVG path definitions, stroke sequence data from datasets like Makemeahanzi or HanziWriter)

## Core Features & Roadmap
1. **Canvas & Pencil Integration:** High-precision canvas supporting Apple Pencil pressure and tilt sensitivity.
2. **Stroke Recognition & Verification:** Real-time feedback verifying stroke direction, order, and form against standard character models.
3. **Character Library & Lessons:** Structured progression for practicing common characters, radicals, and vocabulary sets.
4. **Interactive Practice Modes:** Guided tracing, ghost outlines, memory mode, and speed/accuracy drills.

## Guidelines for AI Agents
- Maintain modular, clean SwiftUI code with clear separation of concerns (Views, Models, Stroke Logic Engine).
- Ensure stroke verification algorithms perform smoothly at high frame rates on iPad hardware.
- Keep tests updated in `InkwellTests` and `InkwellUITests`.
- Avoid modifying Xcode project structures directly unless required; verify `project.pbxproj` changes carefully.
- **Git Branch Naming:** Always prefix branch names with the agent's name followed by a slash (e.g., `claude/`, `gemini/` or `antigravity/`, `jules/`) so that Git clients and Xcode can group them neatly into folders under Source Control.

