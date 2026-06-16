import MeimoireCore
import SwiftUI

struct DocumentToolbar: View {
    @Environment(\.meimoireSkin) private var skin
    let onCommand: (MarkdownEditingCommand) -> Void
    let onTemplate: (DocumentTemplate) -> Void

    var body: some View {
        HStack(spacing: 8) {
            commandGroup([.heading1, .heading2, .heading3, .paragraph])
            Divider().frame(height: 24)
            commandGroup([.bold, .italic, .inlineCode, .link])
            Divider().frame(height: 24)
            commandGroup([.quote, .bulletList, .numberedList, .taskList, .codeBlock, .horizontalRule])
            Divider().frame(height: 24)
            Menu {
                ForEach(DocumentTemplate.allCases) { template in
                    Button {
                        onTemplate(template)
                    } label: {
                        Label(template.title, systemImage: template.symbolName)
                    }
                }
            } label: {
                Label("Modèle", systemImage: "doc.badge.plus")
            }
            .menuStyle(.button)
            .help("Insérer un modèle")
        }
        .padding(7)
        .background(skin.listColor.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(skin.borderColor, lineWidth: 1)
        }
    }

    private func commandGroup(_ commands: [MarkdownEditingCommand]) -> some View {
        HStack(spacing: 3) {
            ForEach(commands) { command in
                Button {
                    onCommand(command)
                } label: {
                    Image(systemName: command.symbolName)
                        .frame(width: 28, height: 28)
                        .foregroundStyle(skin.textColor)
                }
                .buttonStyle(.borderless)
                .background(skin.panelColor.opacity(0.001))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .help(command.title)
            }
        }
    }
}
