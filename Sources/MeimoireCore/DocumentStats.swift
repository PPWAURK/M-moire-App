import Foundation

public struct DocumentStats: Equatable, Sendable {
    public let wordCount: Int
    public let characterCount: Int
    public let readingMinutes: Int

    public init(markdown: String) {
        let trimmed = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
        characterCount = trimmed.count

        let words = trimmed
            .split { character in
                character.isWhitespace || character.isNewline || character.isPunctuation
            }
        wordCount = words.count
        readingMinutes = wordCount == 0 ? 0 : max(1, Int(ceil(Double(wordCount) / 220.0)))
    }
}
