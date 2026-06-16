import Foundation

public enum MarkdownPreviewFormatter {
    public static func preservingSoftLineBreaks(_ markdown: String) -> String {
        var result = ""
        var isInsideFence = false
        let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        for index in lines.indices {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let isLastLine = index == lines.index(before: lines.endIndex)

            if trimmed.hasPrefix("```") {
                isInsideFence.toggle()
                result += line
            } else if isInsideFence || trimmed.isEmpty || line.hasSuffix("  ") {
                result += line
            } else {
                result += line + "  "
            }

            if !isLastLine {
                result += "\n"
            }
        }

        return result
    }
}
