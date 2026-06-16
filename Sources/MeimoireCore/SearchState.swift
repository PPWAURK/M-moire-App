import Foundation

public struct SearchState: Equatable, Sendable {
    public var query: String
    public var selectedType: VaultItemType?
    public var selectedAccountCategory: AccountCategory?
    public var tag: String?
    public var includeArchived: Bool
    public var includeDeleted: Bool

    public init(
        query: String = "",
        selectedType: VaultItemType? = nil,
        selectedAccountCategory: AccountCategory? = nil,
        tag: String? = nil,
        includeArchived: Bool = false,
        includeDeleted: Bool = false
    ) {
        self.query = query
        self.selectedType = selectedType
        self.selectedAccountCategory = selectedAccountCategory
        self.tag = tag
        self.includeArchived = includeArchived
        self.includeDeleted = includeDeleted
    }

    public func matches(_ item: VaultItem) -> Bool {
        if let selectedType, item.type != selectedType {
            return false
        }

        if let selectedAccountCategory {
            guard item.type == .account, item.accountCategory == selectedAccountCategory else {
                return false
            }
        }

        if !includeArchived, item.isArchived {
            return false
        }

        if !includeDeleted, item.isDeleted {
            return false
        }

        if let tag, !tag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let target = tag.lowercased()
            guard item.tags.contains(where: { $0.lowercased() == target }) else {
                return false
            }
        }

        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedQuery.isEmpty else {
            return true
        }

        return [
            item.title,
            item.username,
            item.urlString,
            item.notes,
            item.accountCategory.displayName,
            item.tags.joined(separator: " ")
        ]
            .joined(separator: " ")
            .lowercased()
            .contains(normalizedQuery)
    }
}
