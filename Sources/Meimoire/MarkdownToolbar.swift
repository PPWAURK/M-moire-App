import MeimoireCore
import SwiftUI

struct MarkdownToolbar: View {
    @Environment(\.meimoireSkin) private var skin
    let onCommand: (MarkdownEditingCommand) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(MarkdownEditingCommand.allCases) { command in
                Button {
                    onCommand(command)
                } label: {
                    Image(systemName: command.symbolName)
                        .frame(width: 28, height: 28)
                        .foregroundStyle(skin.textColor)
                }
                .buttonStyle(.borderless)
                .help(command.title)
            }
        }
        .padding(6)
        .background(skin.listColor.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(skin.borderColor, lineWidth: 1)
        }
    }
}
