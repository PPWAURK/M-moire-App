import Foundation
import SwiftData

@Model
public final class VaultItem {
    @Attribute(.unique) public var id: UUID
    public var itemTypeRawValue: String
    public var title: String
    public var username: String
    public var urlString: String
    public var notes: String
    public var tagText: String
    public var accountCategoryRawValue: String?
    public var contentFormatRawValue: String?
    public var secretIdentifier: String?
    public var createdAt: Date
    public var updatedAt: Date
    public var archivedAt: Date?
    public var deletedAt: Date?

    public init(
        id: UUID = UUID(),
        type: VaultItemType,
        title: String,
        username: String = "",
        urlString: String = "",
        notes: String = "",
        tags: [String] = [],
        accountCategory: AccountCategory = .other,
        contentFormat: ContentFormat? = nil,
        secretIdentifier: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        archivedAt: Date? = nil,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.itemTypeRawValue = type.rawValue
        self.title = title
        self.username = username
        self.urlString = urlString
        self.notes = notes
        self.tagText = VaultItem.normalizeTags(tags).joined(separator: ",")
        self.accountCategoryRawValue = type == .account ? accountCategory.rawValue : nil
        self.contentFormatRawValue = (contentFormat ?? (type == .inspiration ? .markdown : .plainText)).rawValue
        self.secretIdentifier = secretIdentifier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
        self.deletedAt = deletedAt
    }

    public var type: VaultItemType {
        get { VaultItemType(rawValue: itemTypeRawValue) ?? .inspiration }
        set {
            itemTypeRawValue = newValue.rawValue
            touch()
        }
    }

    public var tags: [String] {
        get {
            VaultItem.normalizeTags(tagText.split(separator: ",").map(String.init))
        }
        set {
            tagText = VaultItem.normalizeTags(newValue).joined(separator: ",")
            touch()
        }
    }

    public var accountCategory: AccountCategory {
        get { AccountCategory(rawValue: accountCategoryRawValue ?? "") ?? .other }
        set {
            accountCategoryRawValue = newValue.rawValue
            touch()
        }
    }

    public var contentFormat: ContentFormat {
        get { ContentFormat(rawValue: contentFormatRawValue ?? "") ?? .plainText }
        set {
            contentFormatRawValue = newValue.rawValue
            touch()
        }
    }

    public var url: URL? {
        URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    public var isArchived: Bool { archivedAt != nil }
    public var isDeleted: Bool { deletedAt != nil }

    public func update(
        type: VaultItemType,
        title: String,
        username: String,
        urlString: String,
        notes: String,
        tags: [String],
        accountCategory: AccountCategory? = nil,
        contentFormat: ContentFormat? = nil,
        secretIdentifier: String?
    ) {
        let resolvedCategory = accountCategory ?? self.accountCategory
        let resolvedFormat = contentFormat ?? self.contentFormat
        self.itemTypeRawValue = type.rawValue
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.username = username.trimmingCharacters(in: .whitespacesAndNewlines)
        self.urlString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        self.notes = notes
        self.tagText = VaultItem.normalizeTags(tags).joined(separator: ",")
        self.accountCategoryRawValue = type == .account ? resolvedCategory.rawValue : nil
        self.contentFormatRawValue = resolvedFormat.rawValue
        self.secretIdentifier = secretIdentifier
        touch()
    }

    public func archive() {
        archivedAt = .now
        touch()
    }

    public func softDelete() {
        deletedAt = .now
        touch()
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
