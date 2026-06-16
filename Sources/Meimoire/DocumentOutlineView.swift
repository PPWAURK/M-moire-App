import MeimoireCore
import SwiftUI

struct DocumentOutlineView: View {
    @Environment(\.meimoireSkin) private var skin
    let headings: [DocumentHeading]
    let onSelect: (DocumentHeading) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Plan du document", systemImage: "list.bullet.indent")
                .font(.headline)
                .foregroundStyle(skin.textColor)

            if headings.isEmpty {
                Text("Ajoutez des titres pour créer un plan.")
                    .font(.footnote)
                    .foregroundStyle(skin.secondaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(headings) { heading in
                        Button {
                            onSelect(heading)
                        } label: {
                            HStack(spacing: 8) {
                                Text(heading.title)
                                    .lineLimit(1)
                                    .font(.callout.weight(heading.level == 1 ? .semibold : .regular))
                                    .foregroundStyle(skin.textColor)
                                Spacer()
                                Text("\(heading.lineNumber)")
                                    .font(.caption2)
                                    .foregroundStyle(skin.secondaryTextColor)
                            }
                            .padding(.leading, CGFloat((heading.level - 1) * 12))
                            .padding(.vertical, 5)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
