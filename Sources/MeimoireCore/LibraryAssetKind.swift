import Foundation

public enum LibraryAssetKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case font
    case image

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .font:
            "Polices"
        case .image:
            "Éléments image"
        }
    }

    public var singularName: String {
        switch self {
        case .font:
            "Police"
        case .image:
            "Image"
        }
    }

    public var systemImage: String {
        switch self {
        case .font:
            "textformat"
        case .image:
            "photo.on.rectangle"
        }
    }

    public var storageDirectoryName: String {
        switch self {
        case .font:
            "Fonts"
        case .image:
            "Images"
        }
    }

    public var allowedExtensions: Set<String> {
        switch self {
        case .font:
            ["ttf", "otf", "ttc"]
        case .image:
            ["png", "jpg", "jpeg", "heic", "webp", "pdf", "svg"]
        }
    }
}
