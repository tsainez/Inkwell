//
//  SettingsView.swift
//  Inkwell
//
//  A single place for the user to change anything configurable: grading
//  strictness, the writing-pad guide grid, hint sensitivity, plus data
//  management and attribution. Preferences are persisted through AppSettings.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var progressList: [CharacterProgress]
    let onBack: () -> Void

    @AppStorage(AppSettings.Key.strictGrading) private var strictGrading: Bool = AppSettings.defaultStrictGrading
    @AppStorage(AppSettings.Key.gridStyle) private var gridStyleRaw: String = AppSettings.defaultGridStyle.rawValue
    @AppStorage(AppSettings.Key.hintThreshold) private var hintThreshold: Int = AppSettings.defaultHintThreshold
    @AppStorage(AppSettings.Key.appearance) private var appearanceRaw: String = AppSettings.defaultAppearance.rawValue

    @State private var showResetConfirm = false

    private var practicedCount: Int { progressList.count }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(v) (\(b))"
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    appearanceSection
                    gradingSection
                    writingPadSection
                    hintsSection
                    dataSection
                    aboutSection
                }
                .frame(maxWidth: 720, alignment: .leading)
                .frame(maxWidth: .infinity)
                .padding(40)
            }
        }
        .background(InkTheme.paper.ignoresSafeArea())
        .alert("Reset all progress?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) { resetProgress() }
        } message: {
            Text("This permanently deletes your saved practice history for \(practicedCount) character\(practicedCount == 1 ? "" : "s"). Decks and characters stay; only your stats are cleared.")
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                    Text("Decks")
                        .font(.inkSans(size: 15, weight: .medium))
                }
                .foregroundColor(InkTheme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(InkTheme.card)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(InkTheme.line, lineWidth: 1))
            }
            .accessibilityLabel("Back to Decks")

            Spacer()

            VStack(spacing: 2) {
                Text("PREFERENCES")
                    .font(.inkSans(size: 11, weight: .bold))
                    .foregroundColor(InkTheme.accent)
                    .tracking(1.4)
                Text("Settings")
                    .font(.inkSerif(size: 22, weight: .bold))
                    .foregroundColor(InkTheme.ink)
            }

            Spacer()

            // Balance the leading button so the title stays centered.
            Color.clear.frame(width: 90, height: 36)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 18)
        .background(InkTheme.card)
        .overlay(Rectangle().frame(height: 1).foregroundColor(InkTheme.line), alignment: .bottom)
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        SettingsCard(
            icon: "circle.lefthalf.filled",
            label: "APPEARANCE",
            title: "Theme",
            description: "Match the device, or pin Inkwell to Light or Dark. The writing pad, decks, and ink all follow your choice."
        ) {
            SegmentedPicker(
                options: AppAppearance.allCases.map { ($0.title, $0.rawValue) },
                selection: $appearanceRaw
            )
        }
    }

    // MARK: - Grading

    private var gradingSection: some View {
        SettingsCard(
            icon: "checkmark.seal.fill",
            label: "GRADING",
            title: "Strictness",
            description: "How closely a stroke must match before it counts. Lenient is more forgiving of size and placement; Strict expects a closer match."
        ) {
            SegmentedPicker(
                options: [("Lenient", false), ("Strict", true)],
                selection: $strictGrading
            )
        }
    }

    // MARK: - Writing pad

    private var writingPadSection: some View {
        SettingsCard(
            icon: "square.grid.3x3",
            label: "WRITING PAD",
            title: "Guide grid",
            description: "The faint reference grid behind the writing pad. Rice (米) adds diagonals, Field (田) shows the center cross, Blank hides it."
        ) {
            VStack(alignment: .leading, spacing: 16) {
                SegmentedPicker(
                    options: GuideGridStyle.allCases.map { ($0.title, $0.rawValue) },
                    selection: $gridStyleRaw
                )

                GuideGridView(style: GuideGridStyle(storedRawValue: gridStyleRaw))
                    .frame(width: 120, height: 120)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    // MARK: - Hints

    private var hintsSection: some View {
        SettingsCard(
            icon: "lightbulb.fill",
            label: "HINTS",
            title: "Hint sensitivity",
            description: "After this many wrong attempts on the same stroke, the next correct stroke is highlighted to help you along."
        ) {
            HStack(spacing: 16) {
                Stepper(value: $hintThreshold, in: AppSettings.hintThresholdRange) {
                    HStack(spacing: 8) {
                        Text("\(hintThreshold)")
                            .font(.inkSerif(size: 28, weight: .bold))
                            .foregroundColor(InkTheme.ink)
                            .frame(minWidth: 28)
                        Text(hintThreshold == 1 ? "wrong attempt" : "wrong attempts")
                            .font(.inkSans(size: 14))
                            .foregroundColor(InkTheme.ink2)
                    }
                }
                .fixedSize()
            }
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        SettingsCard(
            icon: "tray.full.fill",
            label: "DATA",
            title: "Progress",
            description: practicedCount == 0
                ? "You haven't practiced any characters yet. Once you do, you'll be able to clear your saved history here."
                : "You have saved practice history for \(practicedCount) character\(practicedCount == 1 ? "" : "s"). Resetting clears all stats but keeps every deck."
        ) {
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Reset all progress")
                        .font(.inkSans(size: 14, weight: .semibold))
                }
                .foregroundColor(practicedCount == 0 ? InkTheme.ink3 : InkTheme.accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(InkTheme.paper)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(practicedCount == 0 ? InkTheme.line : InkTheme.accent.opacity(0.5), lineWidth: 1)
                )
            }
            .accessibilityLabel("Reset all progress")
            .buttonStyle(.plain)
            .disabled(practicedCount == 0)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        SettingsCard(
            icon: "info.circle.fill",
            label: "ABOUT",
            title: "Inkwell",
            description: "Practice hand-writing Chinese and Japanese characters in the correct stroke order."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Text(appVersion)
                    .font(.inkSans(size: 13, weight: .medium))
                    .foregroundColor(InkTheme.ink2)

                Divider().background(InkTheme.line)

                VStack(alignment: .leading, spacing: 6) {
                    Text("PRIVACY")
                        .font(.inkSans(size: 11, weight: .bold))
                        .foregroundColor(InkTheme.ink3)
                        .tracking(1.0)
                    Text("Everything stays on this iPad. Inkwell has no accounts, collects no data, and never connects to a server.")
                        .font(.inkSans(size: 13))
                        .foregroundColor(InkTheme.ink2)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                    Link(destination: URL(string: "https://tsainez.github.io/Inkwell/privacy/")!) {
                        HStack(spacing: 5) {
                            Text("Read the privacy policy")
                                .font(.inkSans(size: 13, weight: .semibold))
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(InkTheme.accent)
                    }
                }

                Divider().background(InkTheme.line)

                VStack(alignment: .leading, spacing: 6) {
                    Text("STROKE DATA")
                        .font(.inkSans(size: 11, weight: .bold))
                        .foregroundColor(InkTheme.ink3)
                        .tracking(1.0)
                    Text("Stroke outlines and medians are derived from Make Me a Hanzi / hanzi-writer-data, based on the Arphic PL fonts (AR PL UKai / UMing) under the Arphic Public License. Data and code are provided under the LGPL / MIT licenses of the upstream projects. The full Arphic Public License text is bundled with the app (ARPHICPL.txt).")
                        .font(.inkSans(size: 13))
                        .foregroundColor(InkTheme.ink2)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                    Link(destination: URL(string: "https://tsainez.github.io/Inkwell/licenses/")!) {
                        HStack(spacing: 5) {
                            Text("View full licenses & attribution")
                                .font(.inkSans(size: 13, weight: .semibold))
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(InkTheme.accent)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func resetProgress() {
        for prog in progressList {
            modelContext.delete(prog)
        }
        try? modelContext.save()
    }
}

// MARK: - Reusable settings card

private struct SettingsCard<Content: View>: View {
    let icon: String
    let label: String
    let title: String
    let description: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(InkTheme.accent)
                Text(label)
                    .font(.inkSans(size: 12, weight: .bold))
                    .foregroundColor(InkTheme.accent)
                    .tracking(1.2)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.inkSerif(size: 22, weight: .bold))
                    .foregroundColor(InkTheme.ink)
                Text(description)
                    .font(.inkSans(size: 14))
                    .foregroundColor(InkTheme.ink2)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(InkTheme.card)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(InkTheme.line, lineWidth: 1))
        .shadow(color: InkTheme.shadow, radius: 10, x: 0, y: 4)
    }
}

// MARK: - Segmented picker

/// A small pill-style segmented control matching the app's grading toggle.
private struct SegmentedPicker<Value: Equatable>: View {
    let options: [(String, Value)]
    @Binding var selection: Value

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                let (label, value) = option
                Button {
                    selection = value
                } label: {
                    Text(label)
                        .font(.inkSans(size: 14, weight: .semibold))
                        .foregroundColor(selection == value ? InkTheme.onInk : InkTheme.ink2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selection == value ? InkTheme.ink : Color.clear)
                }
                .buttonStyle(.plain)
            }
        }
        .background(InkTheme.line2)
        .cornerRadius(10)
        .frame(maxWidth: 360)
    }
}

#Preview {
    SettingsView(onBack: {})
        .modelContainer(for: [Item.self, CharacterProgress.self], inMemory: true)
}
