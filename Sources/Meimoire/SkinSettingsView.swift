import MeimoireCore
import SwiftUI

struct SkinSettingsView: View {
    @Environment(SkinManager.self) private var skinManager
    @Environment(\.meimoireSkin) private var skin

    private let columns = [
        GridItem(.adaptive(minimum: 250), spacing: 14)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
                ForEach(MeimoireSkin.allCases) { candidate in
                    SkinPreviewCard(
                        skin: candidate,
                        isSelected: skinManager.selectedSkin == candidate
                    ) {
                        skinManager.select(candidate)
                    }
                }
            }

            Spacer()

            Text("Les thèmes modifient uniquement l’apparence de Meimoire. Ils ne changent pas les comptes, mots de passe, inspirations ni URL.")
                .font(.footnote)
                .foregroundStyle(skin.secondaryTextColor)
        }
        .padding(24)
        .background(skin.backgroundColor)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Apparence")
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(skin.textColor)
            Text("Choisissez un thème Meimoire adapté à votre contexte de travail.")
                .font(.subheadline)
                .foregroundStyle(skin.secondaryTextColor)
        }
    }
}

struct SkinPreviewCard: View {
    let skin: MeimoireSkin
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                preview

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(skin.displayName)
                            .font(.headline)
                            .foregroundStyle(skin.textColor)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(skin.accentColor)
                        }
                    }
                    Text(skin.summary)
                        .font(.caption)
                        .foregroundStyle(skin.secondaryTextColor)
                        .lineLimit(2)
                }
            }
            .padding(14)
            .background(skin.panelColor)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? skin.accentColor : skin.borderColor, lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var preview: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(skin.listColor)
                .frame(width: 54, height: 58)
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 5) {
                        Capsule().fill(skin.accentColor).frame(width: 28, height: 5)
                        Capsule().fill(skin.secondaryTextColor.opacity(0.55)).frame(width: 36, height: 4)
                        Capsule().fill(skin.secondaryAccentColor).frame(width: 22, height: 4)
                    }
                    .padding(8)
                }

            VStack(alignment: .leading, spacing: 6) {
                Capsule().fill(skin.textColor).frame(width: 96, height: 7)
                Capsule().fill(skin.secondaryTextColor.opacity(0.7)).frame(width: 130, height: 5)
                HStack(spacing: 5) {
                    ForEach(AccountCategory.allCases.prefix(4)) { category in
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(skin.color(for: category))
                            .frame(width: 22, height: 18)
                    }
                }
            }
            Spacer()
        }
        .padding(10)
        .frame(height: 86)
        .background(skin.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(skin.borderColor, lineWidth: 1)
        }
    }
}
