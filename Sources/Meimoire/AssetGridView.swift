import AppKit
import MeimoireCore
import SwiftUI

struct AssetGridCard: View {
    @Environment(\.meimoireSkin) private var skin
    let asset: LibraryAsset
    let fileURL: URL
    let categoryName: String
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            preview
                .frame(height: 112)
                .frame(maxWidth: .infinity)
                .background(skin.markdownBackgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(asset.displayTitle)
                    .font(.headline)
                    .foregroundStyle(skin.textColor)
                    .lineLimit(1)
                Text([asset.format, categoryName].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(skin.secondaryTextColor)
                    .lineLimit(1)
                if !asset.tags.isEmpty {
                    Text(asset.tags.prefix(3).map { "#\($0)" }.joined(separator: " "))
                        .font(.caption2)
                        .foregroundStyle(skin.secondaryTextColor.opacity(0.75))
                        .lineLimit(1)
                }
            }
        }
        .padding(10)
        .background(isSelected ? skin.accentColor.opacity(0.16) : skin.panelColor)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? skin.accentColor : skin.borderColor, lineWidth: 1)
        }
    }

    @ViewBuilder
    private var preview: some View {
        switch asset.kind {
        case .font:
            FontPreviewCard(asset: asset, fileURL: fileURL)
        case .image:
            ImageAssetCard(asset: asset, fileURL: fileURL)
        }
    }
}

struct FontPreviewCard: View {
    @Environment(\.meimoireSkin) private var skin
    let asset: LibraryAsset
    let fileURL: URL

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Aa")
                .font(FontPreviewService.previewFont(for: asset, fileURL: fileURL, size: 36))
                .foregroundStyle(skin.textColor)
            Text(asset.fontDisplayName.isEmpty ? asset.originalFilename : asset.fontDisplayName)
                .font(.caption)
                .foregroundStyle(skin.secondaryTextColor)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(12)
    }
}

struct ImageAssetCard: View {
    @Environment(\.meimoireSkin) private var skin
    let asset: LibraryAsset
    let fileURL: URL

    var body: some View {
        Group {
            if let image = NSImage(contentsOf: fileURL) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: asset.format == "SVG" ? "curlybraces.square" : "doc.richtext")
                        .font(.title2)
                    Text(asset.format)
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(skin.secondaryTextColor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
