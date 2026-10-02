import SwiftUI

struct HeaderBar: View {
    let title: String
    let subtitle: String
    let onBack: () -> Void

    var body: some View {
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
                Text(subtitle)
                    .font(.inkSans(size: 11, weight: .bold))
                    .foregroundColor(InkTheme.accent)
                    .tracking(1.4)
                Text(title)
                    .font(.inkSerif(size: 22, weight: .bold))
                    .foregroundColor(InkTheme.ink)
            }

            Spacer()

            // Placeholder spacer to balance layout
            Color.clear.frame(width: 90, height: 36)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 18)
        .background(InkTheme.card)
        .overlay(Rectangle().frame(height: 1).foregroundColor(InkTheme.line), alignment: .bottom)
    }
}
