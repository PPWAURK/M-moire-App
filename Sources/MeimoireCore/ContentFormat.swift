import Foundation

public enum ContentFormat: String, Codable, CaseIterable, Identifiable, Sendable {
    case plainText
    case markdown

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .plainText:
            "Texte brut"
        case .markdown:
            "Markdown"
        }
    }
}
