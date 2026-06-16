import SwiftUI

struct MarkdownPreviewView: View {
    @Environment(\.meimoireSkin) private var skin
    let markdown: String

    private var blocks: [MarkdownPreviewBlock] {
        MarkdownPreviewBlock.parse(markdown)
    }

    var body: some View {
        ScrollView {
            if markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ContentUnavailableView("Aucun contenu", systemImage: "text.alignleft", description: Text("En mode édition, notez vos inspirations, paragraphes, tâches ou liens."))
                    .frame(maxWidth: .infinity, minHeight: 220)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(blocks) { block in
                        blockView(block)
                    }
                }
                .frame(maxWidth: 760, alignment: .leading)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownPreviewBlock) -> some View {
        switch block {
        case .empty:
            Spacer()
                .frame(height: 8)
        case .heading(let level, let text, _):
            Text(inline(text))
                .font(headingFont(level))
                .foregroundStyle(skin.textColor)
                .textSelection(.enabled)
                .padding(.top, level == 1 ? 8 : 4)
        case .paragraph(let text, _):
            Text(inline(text))
                .font(.body)
                .foregroundStyle(skin.textColor)
                .lineSpacing(4)
                .textSelection(.enabled)
        case .bullet(let text, let indent, _):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("•")
                    .foregroundStyle(skin.secondaryTextColor)
                Text(inline(text))
                    .foregroundStyle(skin.textColor)
                    .textSelection(.enabled)
            }
            .font(.body)
            .padding(.leading, CGFloat(indent * 18))
        case .numbered(let number, let text, let indent, _):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(number).")
                    .foregroundStyle(skin.secondaryTextColor)
                    .frame(minWidth: 20, alignment: .trailing)
                Text(inline(text))
                    .foregroundStyle(skin.textColor)
                    .textSelection(.enabled)
            }
            .font(.body)
            .padding(.leading, CGFloat(indent * 18))
        case .task(let isDone, let text, let indent, _):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: isDone ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isDone ? skin.accentColor : skin.secondaryTextColor)
                Text(inline(text))
                    .foregroundStyle(skin.textColor)
                    .strikethrough(isDone)
                    .textSelection(.enabled)
            }
            .font(.body)
            .padding(.leading, CGFloat(indent * 18))
        case .quote(let text, let indent, _):
            HStack(alignment: .top, spacing: 10) {
                Rectangle()
                    .fill(skin.accentColor.opacity(0.55))
                    .frame(width: 2)
                Text(inline(text))
                    .font(.body.italic())
                    .foregroundStyle(skin.secondaryTextColor)
                    .textSelection(.enabled)
            }
            .padding(.vertical, 2)
            .padding(.leading, CGFloat(indent * 18))
        case .rule:
            Divider()
                .overlay(skin.borderColor)
                .padding(.vertical, 6)
        case .code(let text, _):
            Text(text)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(skin.markdownTextColor)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(skin.markdownBackgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(skin.borderColor, lineWidth: 1)
                }
        }
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1:
            .title2.weight(.semibold)
        case 2:
            .title3.weight(.semibold)
        default:
            .headline
        }
    }

    private func inline(_ markdown: String) -> AttributedString {
        (try? AttributedString(markdown: markdown)) ?? AttributedString(markdown)
    }
}

private enum MarkdownPreviewBlock: Identifiable {
    case empty(Int)
    case heading(level: Int, text: String, id: Int)
    case paragraph(text: String, id: Int)
    case bullet(text: String, indent: Int, id: Int)
    case numbered(number: Int, text: String, indent: Int, id: Int)
    case task(isDone: Bool, text: String, indent: Int, id: Int)
    case quote(text: String, indent: Int, id: Int)
    case rule(Int)
    case code(text: String, id: Int)

    var id: Int {
        switch self {
        case .empty(let id), .heading(_, _, let id), .paragraph(_, let id), .bullet(_, _, let id),
             .numbered(_, _, _, let id), .task(_, _, _, let id), .quote(_, _, let id), .rule(let id),
             .code(_, let id):
            id
        }
    }

    static func parse(_ markdown: String) -> [MarkdownPreviewBlock] {
        let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var blocks: [MarkdownPreviewBlock] = []
        var index = 0

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("```") {
                let start = index
                index += 1
                var codeLines: [String] = []
                while index < lines.count {
                    let current = lines[index]
                    if current.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                        break
                    }
                    codeLines.append(current)
                    index += 1
                }
                blocks.append(.code(text: codeLines.joined(separator: "\n"), id: start))
                if index < lines.count {
                    index += 1
                }
                continue
            }

            blocks.append(parseLine(line, id: index))
            index += 1
        }

        return blocks
    }

    private static func parseLine(_ line: String, id: Int) -> MarkdownPreviewBlock {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let indent = indentLevel(for: line)
        guard !trimmed.isEmpty else { return .empty(id) }

        if trimmed == "---" || trimmed == "***" {
            return .rule(id)
        }

        if let heading = heading(from: trimmed, id: id) {
            return heading
        }

        if let task = task(from: trimmed, indent: indent, id: id) {
            return task
        }

        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            return .bullet(text: String(trimmed.dropFirst(2)), indent: indent, id: id)
        }

        if let numbered = numbered(from: trimmed, indent: indent, id: id) {
            return numbered
        }

        if trimmed.hasPrefix("> ") {
            return .quote(text: String(trimmed.dropFirst(2)), indent: indent, id: id)
        }

        return .paragraph(text: trimmed, id: id)
    }

    private static func heading(from line: String, id: Int) -> MarkdownPreviewBlock? {
        guard line.hasPrefix("#") else { return nil }
        let level = line.prefix { $0 == "#" }.count
        guard (1...3).contains(level) else { return nil }
        let marker = String(repeating: "#", count: level) + " "
        guard line.hasPrefix(marker) else { return nil }
        let text = String(line.dropFirst(marker.count)).trimmingCharacters(in: .whitespaces)
        return .heading(level: level, text: text, id: id)
    }

    private static func task(from line: String, indent: Int, id: Int) -> MarkdownPreviewBlock? {
        if line.hasPrefix("- [ ] ") {
            return .task(isDone: false, text: String(line.dropFirst(6)), indent: indent, id: id)
        }
        if line.lowercased().hasPrefix("- [x] ") {
            return .task(isDone: true, text: String(line.dropFirst(6)), indent: indent, id: id)
        }
        return nil
    }

    private static func numbered(from line: String, indent: Int, id: Int) -> MarkdownPreviewBlock? {
        guard let dotIndex = line.firstIndex(of: ".") else { return nil }
        let numberText = line[..<dotIndex]
        guard let number = Int(numberText) else { return nil }
        let afterDot = line[line.index(after: dotIndex)...]
        guard afterDot.hasPrefix(" ") else { return nil }
        return .numbered(number: number, text: String(afterDot.dropFirst()), indent: indent, id: id)
    }

    private static func indentLevel(for line: String) -> Int {
        line.prefix { $0 == " " }.count / 4
    }
}
