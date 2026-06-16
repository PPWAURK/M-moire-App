import MeimoireCore
import SwiftUI

struct CategoryIconView: View {
    @Environment(\.meimoireSkin) private var skin
    let item: VaultItem
    var size: CGFloat = 38

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: size * 0.43, weight: .semibold))
            .foregroundStyle(foreground)
            .frame(width: size, height: size)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: min(8, size * 0.22), style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: min(8, size * 0.22), style: .continuous)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            }
    }

    private var symbolName: String {
        item.type == .account ? item.accountCategory.symbolName : item.type.systemImage
    }

    private var foreground: some ShapeStyle {
        item.type == .account ? .white : Color.white
    }

    private var background: some ShapeStyle {
        switch item.type {
        case .account:
            skin.color(for: item.accountCategory).gradient
        case .inspiration:
            skin.secondaryAccentColor.gradient
        case .url:
            skin.accentColor.gradient
        }
    }
}
