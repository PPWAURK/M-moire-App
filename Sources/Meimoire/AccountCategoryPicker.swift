import MeimoireCore
import SwiftUI

struct AccountCategoryPicker: View {
    @Environment(\.meimoireSkin) private var skin
    @Binding var selection: AccountCategory

    private let columns = [
        GridItem(.adaptive(minimum: 88, maximum: 112), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(AccountCategory.allCases) { category in
                Button {
                    selection = category
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: category.symbolName)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(skin.color(for: category).gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        Text(category.displayName)
                            .font(.caption.weight(selection == category ? .semibold : .regular))
                            .foregroundStyle(selection == category ? skin.textColor : skin.secondaryTextColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(selection == category ? skin.accentColor.opacity(0.18) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(selection == category ? skin.accentColor.opacity(0.7) : skin.borderColor, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
