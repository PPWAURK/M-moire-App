import Foundation

public enum MarkdownListContinuation {
    public static func applyNewline(to text: String, selectedRange: NSRange) -> MarkdownEditResult? {
        guard selectedRange.length == 0 else { return nil }

        let nsText = text as NSString
        guard selectedRange.location >= 0, selectedRange.location <= nsText.length else { return nil }

        let lineStart = currentLineStart(in: nsText, cursorLocation: selectedRange.location)
        let lineRange = NSRange(location: lineStart, length: selectedRange.location - lineStart)
        let currentLine = nsText.substring(with: lineRange)

        guard let continuation = continuation(for: currentLine) else { return nil }

        let mutable = NSMutableString(string: text)
        if continuation.shouldExitList {
            mutable.replaceCharacters(in: lineRange, with: "")
            return MarkdownEditResult(
                text: mutable as String,
                selectedRange: NSRange(location: lineStart, length: 0)
            )
        }

        let replacement = "\n\(continuation.nextMarker)"
        mutable.replaceCharacters(in: selectedRange, with: replacement)
        return MarkdownEditResult(
            text: mutable as String,
            selectedRange: NSRange(location: selectedRange.location + replacement.utf16.count, length: 0)
        )
    }

    public static func indentListLine(in text: String, selectedRange: NSRange) -> MarkdownEditResult? {
        transformCurrentListLine(in: text, selectedRange: selectedRange) { line, lineStart in
            guard isListLine(line) else { return nil }
            return LineTransform(
                replacementRange: NSRange(location: lineStart, length: 0),
                replacement: "    "
            )
        }
    }

    public static func outdentListLine(in text: String, selectedRange: NSRange) -> MarkdownEditResult? {
        transformCurrentListLine(in: text, selectedRange: selectedRange) { line, lineStart in
            guard isListLine(line) else { return nil }
            let removableSpaces = min(line.prefix { $0 == " " }.count, 4)
            guard removableSpaces > 0 else { return nil }
            return LineTransform(
                replacementRange: NSRange(location: lineStart, length: removableSpaces),
                replacement: ""
            )
        }
    }

    private static func currentLineStart(in text: NSString, cursorLocation: Int) -> Int {
        guard cursorLocation > 0 else { return 0 }
        let previousNewline = text.range(
            of: "\n",
            options: .backwards,
            range: NSRange(location: 0, length: cursorLocation)
        )
        return previousNewline.location == NSNotFound ? 0 : previousNewline.location + 1
    }

    private static func currentLineEnd(in text: NSString, cursorLocation: Int) -> Int {
        let remainingRange = NSRange(location: cursorLocation, length: text.length - cursorLocation)
        let nextNewline = text.range(of: "\n", range: remainingRange)
        return nextNewline.location == NSNotFound ? text.length : nextNewline.location
    }

    private static func transformCurrentListLine(
        in text: String,
        selectedRange: NSRange,
        transform: (String, Int) -> LineTransform?
    ) -> MarkdownEditResult? {
        let nsText = text as NSString
        guard selectedRange.location >= 0, selectedRange.location <= nsText.length else { return nil }

        let lineStart = currentLineStart(in: nsText, cursorLocation: selectedRange.location)
        let lineEnd = currentLineEnd(in: nsText, cursorLocation: selectedRange.location)
        let line = nsText.substring(with: NSRange(location: lineStart, length: lineEnd - lineStart))
        guard let transform = transform(line, lineStart) else { return nil }

        let mutable = NSMutableString(string: text)
        mutable.replaceCharacters(in: transform.replacementRange, with: transform.replacement)

        let cursorDelta = transform.replacement.utf16.count - transform.replacementRange.length
        return MarkdownEditResult(
            text: mutable as String,
            selectedRange: NSRange(
                location: max(lineStart, selectedRange.location + cursorDelta),
                length: selectedRange.length
            )
        )
    }

    private static func continuation(for line: String) -> Continuation? {
        if let task = taskContinuation(for: line) {
            return task
        }

        if let numbered = numberedContinuation(for: line) {
            return numbered
        }

        return bulletContinuation(for: line)
    }

    private static func isListLine(_ line: String) -> Bool {
        taskContinuation(for: line) != nil ||
            numberedContinuation(for: line) != nil ||
            bulletContinuation(for: line) != nil
    }

    private static func taskContinuation(for line: String) -> Continuation? {
        let pattern = #"^(\s*[-*]\s+\[)([ xX])(\]\s+)(.*)$"#
        guard let match = firstMatch(pattern: pattern, in: line) else { return nil }
        let prefix = group(1, in: line, match: match)
        let suffix = group(3, in: line, match: match)
        let body = group(4, in: line, match: match)
        return Continuation(
            nextMarker: "\(prefix) \(suffix)",
            shouldExitList: body.trimmingCharacters(in: .whitespaces).isEmpty
        )
    }

    private static func numberedContinuation(for line: String) -> Continuation? {
        let pattern = #"^(\s*)(\d+)([.)]\s+)(.*)$"#
        guard let match = firstMatch(pattern: pattern, in: line) else { return nil }
        let indentation = group(1, in: line, match: match)
        let numberText = group(2, in: line, match: match)
        let separator = group(3, in: line, match: match)
        let body = group(4, in: line, match: match)
        guard let number = Int(numberText) else { return nil }
        return Continuation(
            nextMarker: "\(indentation)\(number + 1)\(separator)",
            shouldExitList: body.trimmingCharacters(in: .whitespaces).isEmpty
        )
    }

    private static func bulletContinuation(for line: String) -> Continuation? {
        let pattern = #"^(\s*[-*]\s+)(.*)$"#
        guard let match = firstMatch(pattern: pattern, in: line) else { return nil }
        let marker = group(1, in: line, match: match)
        let body = group(2, in: line, match: match)
        return Continuation(
            nextMarker: marker,
            shouldExitList: body.trimmingCharacters(in: .whitespaces).isEmpty
        )
    }

    private static func firstMatch(pattern: String, in text: String) -> NSTextCheckingResult? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(location: 0, length: (text as NSString).length)
        return regex.firstMatch(in: text, range: range)
    }

    private static func group(_ index: Int, in text: String, match: NSTextCheckingResult) -> String {
        let range = match.range(at: index)
        guard range.location != NSNotFound else { return "" }
        return (text as NSString).substring(with: range)
    }

    private struct Continuation {
        let nextMarker: String
        let shouldExitList: Bool
    }

    private struct LineTransform {
        let replacementRange: NSRange
        let replacement: String
    }
}
