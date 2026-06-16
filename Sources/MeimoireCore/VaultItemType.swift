import Foundation

public enum VaultItemType: String, Codable, CaseIterable, Identifiable, Sendable {
    case account
    case inspiration
    case url

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .account:
            "Comptes"
        case .inspiration:
            "Inspirations"
        case .url:
            "URL"
        }
    }

    public var systemImage: String {
        switch self {
        case .account:
            "person.badge.key"
        case .inspiration:
            "sparkles"
        case .url:
            "link"
        }
    }
}
