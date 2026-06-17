import Foundation
import SwiftData

@Model
public final class LibraryAsset {
    @Attribute(.unique) public var id: UUID
    public var assetKindRawValue: String
    public var title: String
    public var originalFilename: String
    public var storedFilename: String
    public var relativePath: String
    public var categoryID: UUID?
    public var tagText: String
    public var notes: String
    public var fileSize: Int64
    public var format: String
    public var pixelWidth: Int?
    public var pixelHeight: Int?
    public var fontDisplayName: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        kind: LibraryAssetKind,
        title: String,
        originalFilename: String,
        storedFilename: String,
        relativePath: String,
        categoryID: UUID? = nil,
        tags: [String] = [],
        notes: String = "",
        fileSize: Int64 = 0,
        format: String = "",
        pixelWidth: Int? = nil,
        pixelHeight: Int? = nil,
        fontDisplayName: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.assetKindRawValue = kind.rawValue
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.originalFilename = originalFilename
        self.storedFilename = storedFilename
        self.relativePath = relativePath
        self.categoryID = categoryID
        self.tagText = LibraryAsset.normalizeTags(tags).joined(separator: ",")
        self.notes = notes
        self.fileSize = fileSize
        self.format = format.uppercased()
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.fontDisplayName = fontDisplayName
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

    public var tags: [String] {
        get { LibraryAsset.normalizeTags(tagText.split(separator: ",").map(String.init)) }
        set {
            tagText = LibraryAsset.normalizeTags(newValue).joined(separator: ",")
            touch()
        }
    }

    public var displayTitle: String {
        title.isEmpty ? originalFilename : title
    }

    public var dimensionText: String {
        guard let pixelWidth, let pixelHeight else { return "" }
        return "\(pixelWidth) x \(pixelHeight)"
    }

    public func update(title: String, categoryID: UUID?, tags: [String], notes: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.title = trimmed.isEmpty ? originalFilename : trimmed
        self.categoryID = categoryID
        self.tags = tags
        self.notes = notes
        touch()
    }

    public func matches(query: String, categoryName: String) -> Bool {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return true }
        return [
            title,
            originalFilename,
            storedFilename,
            format,
            fontDisplayName,
            notes,
            categoryName,
            tags.joined(separator: " ")
        ]
            .joined(separator: " ")
            .lowercased()
            .contains(normalized)
    }

    public func touch() {
        updatedAt = .now
    }

    public static func normalizeTags(_ tags: [String]) -> [String] {
        var seen = Set<String>()
        return tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { tag in
                let key = tag.lowercased()
                guard !seen.contains(key) else { return false }
                seen.insert(key)
                return true
            }
    }
}
