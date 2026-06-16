import MeimoireCore
import SwiftUI

struct DocumentStatsView: View {
    @Environment(\.meimoireSkin) private var skin
    let stats: DocumentStats
    let saveStateTitle: String
    let saveStateSystemImage: String
    let isError: Bool

    var body: some View {
        HStack(spacing: 10) {
            stat("\(stats.wordCount)", "mots")
            stat("\(stats.characterCount)", "car.")
            stat(stats.readingMinutes == 0 ? "0" : "\(stats.readingMinutes)", "min")
            Spacer()
            Label(saveStateTitle, systemImage: saveStateSystemImage)
                .font(.caption.weight(.medium))
                .foregroundStyle(isError ? skin.dangerColor : skin.secondaryTextColor)
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        HStack(spacing: 3) {
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(skin.textColor)
            Text(label)
                .font(.caption)
                .foregroundStyle(skin.secondaryTextColor)
        }
    }
}
