import Foundation
import SwiftData

@Model
public final class LibraryCategory {
    @Attribute(.unique) public var id: UUID
    public var assetKindRawValue: String
    public var name: String
    public var sortOrder: Int
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        kind: LibraryAssetKind,
        name: String,
        sortOrder: Int = 0,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.assetKindRawValue = kind.rawValue
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var kind: LibraryAssetKind {
        get { LibraryAssetKind(rawValue: assetKindRawValue) ?? .image }
        set {
            assetKindRawValue = newValue.rawValue
            touch()
        }
    }

    public func update(name: String, sortOrder: Int? = nil) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.name = trimmed.isEmpty ? "Non classé" : trimmed
        if let sortOrder {
            self.sortOrder = sortOrder
        }
        touch()
    }

    public func touch() {
        updatedAt = .now
    }
}
