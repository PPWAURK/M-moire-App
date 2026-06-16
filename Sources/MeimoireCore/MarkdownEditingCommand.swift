import Foundation

public struct MarkdownEditResult: Equatable, Sendable {
    public var text: String
    public var selectedRange: NSRange

    public init(text: String, selectedRange: NSRange) {
        self.text = text
        self.selectedRange = selectedRange
    }
}

public enum MarkdownEditingCommand: String, CaseIterable, Identifiable, Sendable {
    case heading1
    case heading2
    case heading3
    case paragraph
    case bold
    case italic
    case inlineCode
    case quote
    case bulletList
    case numberedList
    case taskList
    case codeBlock
    case link
    case horizontalRule

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .heading1:
            "Titre 1"
        case .heading2:
            "Titre 2"
        case .heading3:
            "Titre 3"
        case .paragraph:
            "Texte"
        case .bold:
            "Gras"
        case .italic:
            "Italique"
        case .inlineCode:
            "Code inline"
        case .quote:
            "Citation"
        case .bulletList:
            "Liste à puces"
        case .numberedList:
            "Liste numérotée"
        case .taskList:
            "Tâche"
        case .codeBlock:
            "Bloc de code"
        case .link:
            "Lien"
        case .horizontalRule:
            "Séparateur"
        }
    }

    public var symbolName: String {
        switch self {
        case .heading1:
            "textformat.size.larger"
        case .heading2:
            "textformat.size"
        case .heading3:
            "textformat"
        case .paragraph:
            "paragraphsign"
        case .bold:
            "bold"
        case .italic:
            "italic"
        case .inlineCode:
            "chevron.left.forwardslash.chevron.right"
        case .quote:
            "quote.opening"
        case .bulletList:
            "list.bullet"
        case .numberedList:
            "list.number"
        case .taskList:
            "checklist"
        case .codeBlock:
            "curlybraces"
        case .link:
            "link"
        case .horizontalRule:
            "minus"
        }
    }

    public func apply(to text: String, selectedRange: NSRange) -> MarkdownEditResult {
        let range = text.range(from: selectedRange) ?? text.endIndex..<text.endIndex
        let selectedText = String(text[range])

        switch self {
        case .heading1:
            return heading(text, range: range, selectedText: selectedText, level: 1)
        case .heading2:
            return heading(text, range: range, selectedText: selectedText, level: 2)
        case .heading3:
            return heading(text, range: range, selectedText: selectedText, level: 3)
        case .paragraph:
            return paragraph(text, range: range, selectedText: selectedText)
        case .bold:
            return wrap(text, range: range, selectedText: selectedText, prefix: "**", suffix: "**", placeholder: "texte en gras")
        case .italic:
            return wrap(text, range: range, selectedText: selectedText, prefix: "_", suffix: "_", placeholder: "texte en italique")
        case .inlineCode:
            return wrap(text, range: range, selectedText: selectedText, prefix: "`", suffix: "`", placeholder: "code")
        case .quote:
            return prefixLines(text, range: range, selectedText: selectedText, prefix: "> ", placeholder: "citation")
        case .bulletList:
            return prefixLines(text, range: range, selectedText: selectedText, prefix: "- ", placeholder: "élément de liste")
        case .numberedList:
            return numberedLines(text, range: range, selectedText: selectedText)
        case .taskList:
            return prefixLines(text, range: range, selectedText: selectedText, prefix: "- [ ] ", placeholder: "tâche")
        case .codeBlock:
            let body = selectedText.isEmpty ? "code" : selectedText
            let replacement = "```\n\(body)\n```"
            return replace(text, range: range, replacement: replacement, selectedOffset: 4, selectedLength: body.utf16.count)
        case .link:
            let label = selectedText.isEmpty ? "texte du lien" : selectedText
            let replacement = "[\(label)](https://example.com)"
            return replace(text, range: range, replacement: replacement, selectedOffset: 1, selectedLength: label.utf16.count)
        case .horizontalRule:
            return insertBlock(text, range: range, replacement: "\n---\n", selectedOffset: 5, selectedLength: 0)
        }
    }

    private func heading(_ text: String, range: Range<String.Index>, selectedText: String, level: Int) -> MarkdownEditResult {
        let marks = String(repeating: "#", count: level)
        return prefixLines(
            text,
            range: range,
            selectedText: selectedText,
            prefix: "\(marks) ",
            placeholder: "Titre"
        )
    }

    private func paragraph(_ text: String, range: Range<String.Index>, selectedText: String) -> MarkdownEditResult {
        let body = selectedText.isEmpty ? "Texte" : selectedText
        let replacement = body
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { line in
                String(line)
                    .replacingOccurrences(
                        of: #"^\s{0,3}#{1,6}\s+"#,
                        with: "",
                        options: .regularExpression
                    )
                    .replacingOccurrences(
                        of: #"^\s{0,3}>\s?"#,
                        with: "",
                        options: .regularExpression
                    )
            }
            .joined(separator: "\n")
        return replace(text, range: range, replacement: replacement, selectedOffset: 0, selectedLength: replacement.utf16.count)
    }

    private func wrap(
        _ text: String,
        range: Range<String.Index>,
        selectedText: String,
        prefix: String,
        suffix: String,
        placeholder: String
    ) -> MarkdownEditResult {
        let body = selectedText.isEmpty ? placeholder : selectedText
        let replacement = "\(prefix)\(body)\(suffix)"
        return replace(
            text,
            range: range,
            replacement: replacement,
            selectedOffset: prefix.utf16.count,
            selectedLength: body.utf16.count
        )
    }

    private func prefixLines(
        _ text: String,
        range: Range<String.Index>,
        selectedText: String,
        prefix: String,
        placeholder: String
    ) -> MarkdownEditResult {
        let body = selectedText.isEmpty ? placeholder : selectedText
        let replacement = body
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { "\(prefix)\($0)" }
            .joined(separator: "\n")
        return replace(text, range: range, replacement: replacement, selectedOffset: prefix.utf16.count, selectedLength: body.utf16.count)
    }

    private func numberedLines(_ text: String, range: Range<String.Index>, selectedText: String) -> MarkdownEditResult {
        let body = selectedText.isEmpty ? "élément de liste" : selectedText
        let lines = body.split(separator: "\n", omittingEmptySubsequences: false)
        let replacement = lines.enumerated().map { index, line in
            "\(index + 1). \(line)"
        }.joined(separator: "\n")
        return replace(text, range: range, replacement: replacement, selectedOffset: 3, selectedLength: body.utf16.count)
    }

    private func replace(
        _ text: String,
        range: Range<String.Index>,
        replacement: String,
        selectedOffset: Int,
        selectedLength: Int
    ) -> MarkdownEditResult {
        var updatedText = text
        let lowerBound = range.lowerBound
        let startOffset = text.utf16.distance(from: text.utf16.startIndex, to: lowerBound.samePosition(in: text.utf16) ?? text.utf16.endIndex)
        updatedText.replaceSubrange(range, with: replacement)
        return MarkdownEditResult(
            text: updatedText,
            selectedRange: NSRange(location: startOffset + selectedOffset, length: selectedLength)
        )
    }

    private func insertBlock(
        _ text: String,
        range: Range<String.Index>,
        replacement: String,
        selectedOffset: Int,
        selectedLength: Int
    ) -> MarkdownEditResult {
        replace(text, range: range, replacement: replacement, selectedOffset: selectedOffset, selectedLength: selectedLength)
    }
}

private extension String {
    func range(from nsRange: NSRange) -> Range<String.Index>? {
        guard let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
              let to16 = utf16.index(from16, offsetBy: nsRange.length, limitedBy: utf16.endIndex),
              let from = String.Index(from16, within: self),
              let to = String.Index(to16, within: self) else {
            return nil
        }
        return from..<to
    }
}
