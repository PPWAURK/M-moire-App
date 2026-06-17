import MeimoireCore
import SwiftData
import SwiftUI
import AppKit

private enum SidebarSelection: Hashable {
    case all
    case type(VaultItemType)
    case accountCategory(AccountCategory)
    case library(LibraryAssetKind)
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.meimoireSkin) private var skin
    @Query(sort: \VaultItem.updatedAt, order: .reverse) private var items: [VaultItem]
    @Query(sort: \LibraryAsset.updatedAt, order: .reverse) private var libraryAssets: [LibraryAsset]
    @Query(sort: \LibraryCategory.sortOrder, order: .forward) private var libraryCategories: [LibraryCategory]
    @State private var selectedSection: SidebarSelection = .all
    @State private var selectedItem: VaultItem?
    @State private var selectedAsset: LibraryAsset?
    @State private var searchText = ""
    @State private var selectedTag: String?
    @State private var isShowingEditor = false
    @State private var editingItem: VaultItem?
    @State private var lockService = AppLockService()
    @State private var expandedAccountCategories: Set<AccountCategory> = [AccountCategory.allCases.first ?? .work]
    @State private var isAccountCategorySidebarExpanded = true
    @State private var copiedUsernameItemID: UUID?
    private let secretStore = SecretStore()

    var body: some View {
        NavigationSplitView {
            sidebar
        } content: {
            itemList
        } detail: {
            detailPane
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    lockService.lock()
                } label: {
                    Label("Verrouiller", systemImage: "lock")
                }
                .help("Verrouiller l’accès aux mots de passe")

                if let currentLibraryKind {
                    Button {
                        NotificationCenter.default.post(name: .meimoireImportAsset, object: currentLibraryKind.rawValue)
                    } label: {
                        Label("Importer", systemImage: "tray.and.arrow.down")
                    }
                    .help("Importer dans la bibliothèque")
                } else {
                    Button {
                        newItem(defaultType: currentType ?? .account)
                    } label: {
                        Label("Nouveau", systemImage: "plus")
                    }
                    .help("Créer un élément")
                }
            }
        }
        .sheet(isPresented: $isShowingEditor) {
            ItemEditorView(
                item: editingItem,
                defaultType: currentType ?? .account,
                defaultAccountCategory: selectedAccountCategory,
                secretStore: secretStore
            )
            .frame(minWidth: 680, minHeight: 700)
        }
        .onReceive(NotificationCenter.default.publisher(for: .meimoireCreateItem)) { _ in
            newItem(defaultType: currentType ?? .account)
        }
    }

    private var currentType: VaultItemType? {
        switch selectedSection {
        case .all:
            nil
        case .type(let type):
            type
        case .accountCategory:
            .account
        case .library:
            nil
        }
    }

    private var currentLibraryKind: LibraryAssetKind? {
        if case .library(let kind) = selectedSection {
            return kind
        }
        return nil
    }

    private var selectedAccountCategory: AccountCategory? {
        if case .accountCategory(let category) = selectedSection {
            return category
        }
        return nil
    }

    private var filteredItems: [VaultItem] {
        let state = SearchState(
            query: searchText,
            selectedType: currentType,
            selectedAccountCategory: selectedAccountCategory,
            tag: selectedTag
        )
        return items.filter { state.matches($0) }
    }

    private var allTags: [String] {
        let tags = items.flatMap(\.tags)
        return Array(Set(tags)).sorted { $0.localizedCompare($1) == .orderedAscending }
    }

    private var sidebar: some View {
        List(selection: $selectedSection) {
            Section {
                Label("Tous les éléments", systemImage: "tray.full")
                    .tag(SidebarSelection.all)
            }

            Section("Types") {
                ForEach(VaultItemType.allCases) { type in
                    Label {
                        SidebarText(title: type.displayName, count: count(for: type))
                    } icon: {
                        Image(systemName: type.systemImage)
                    }
                    .tag(SidebarSelection.type(type))
                }
            }

            Section("Bibliothèque") {
                ForEach(LibraryAssetKind.allCases) { kind in
                    Label {
                        SidebarText(title: kind.displayName, count: count(for: kind))
                    } icon: {
                        Image(systemName: kind.systemImage)
                    }
                    .tag(SidebarSelection.library(kind))
                }
            }

            Section {
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        isAccountCategorySidebarExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text("Catégories de comptes")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(skin.secondaryTextColor)
                            .textCase(.uppercase)
                        Spacer()
                        Text("\(accountCount)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(skin.secondaryTextColor)
                        Image(systemName: isAccountCategorySidebarExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(skin.secondaryTextColor)
                            .frame(width: 12)
                    }
                }
                .buttonStyle(.plain)

                if isAccountCategorySidebarExpanded {
                    ForEach(AccountCategory.allCases) { category in
                        Label {
                            SidebarText(title: category.displayName, count: count(for: category))
                        } icon: {
                            Image(systemName: category.symbolName)
                                .foregroundStyle(skin.color(for: category))
                        }
                        .tag(SidebarSelection.accountCategory(category))
                    }
                }
            }

            if !allTags.isEmpty {
                Section("Étiquettes") {
                    Button {
                        selectedTag = nil
                    } label: {
                        Label("Toutes les étiquettes", systemImage: selectedTag == nil ? "checkmark.circle.fill" : "tag")
                    }
                    .buttonStyle(.plain)

                    ForEach(allTags, id: \.self) { tag in
                        Button {
                            selectedTag = tag
                        } label: {
                            Label(tag, systemImage: selectedTag == tag ? "checkmark.circle.fill" : "tag")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("Meimoire")
        .frame(minWidth: 220)
    }

    private var itemList: some View {
        Group {
            if let currentLibraryKind {
                LibraryView(
                    kind: currentLibraryKind,
                    assets: libraryAssets,
                    categories: libraryCategories,
                    selectedAsset: $selectedAsset
                )
            } else {
                VStack(spacing: 0) {
                    listHeader

                    if shouldShowGroupedAccounts {
                        groupedAccountList
                    } else if filteredItems.isEmpty {
                        ContentUnavailableView(emptyTitle, systemImage: emptyImage, description: Text(emptyDescription))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(filteredItems, selection: $selectedItem) { item in
                            ItemRow(
                                item: item,
                                isSelected: selectedItem?.id == item.id,
                                isUsernameCopied: copiedUsernameItemID == item.id,
                                onCopyUsername: { copyUsername(for: item) }
                            )
                                .tag(item)
                                .contextMenu {
                                    Button("Modifier") {
                                        edit(item)
                                    }
                                    Button("Supprimer", role: .destructive) {
                                        delete(item)
                                    }
                                }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .background(skin.listColor)
                    }
                }
                .background(skin.listColor)
            }
        }
        .navigationTitle(sectionTitle)
        .frame(minWidth: currentLibraryKind == nil ? 360 : 560)
    }

    private var shouldShowGroupedAccounts: Bool {
        currentType == .account && selectedAccountCategory == nil
    }

    private var groupedAccountList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(AccountCategory.allCases) { category in
                    AccountCategorySection(
                        category: category,
                        items: accounts(for: category),
                        isExpanded: expandedAccountCategories.contains(category),
                        selectedItemID: selectedItem?.id,
                        copiedUsernameItemID: copiedUsernameItemID,
                        onToggle: { toggle(category) },
                        onSelect: { selectedItem = $0 },
                        onCopyUsername: { copyUsername(for: $0) },
                        onEdit: { edit($0) },
                        onDelete: { delete($0) }
                    )
                }
            }
            .padding(12)
        }
        .background(skin.listColor)
    }

    private var listHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(sectionTitle)
                        .font(.title2.weight(.semibold))
                    Text("\(filteredItems.count) éléments")
                        .font(.caption)
                        .foregroundStyle(skin.secondaryTextColor)
                }
                Spacer()
                Button {
                    newItem(defaultType: currentType ?? .account)
                } label: {
                    Label("Nouveau", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(skin.secondaryTextColor)
                TextField("Rechercher titre, compte, catégorie, URL, note ou étiquette", text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundStyle(skin.textColor)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(skin.secondaryTextColor)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(skin.panelColor)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(skin.borderColor, lineWidth: 1)
            }

            if let selectedTag {
                HStack(spacing: 6) {
                    Text("#\(selectedTag)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(skin.textColor)
                Button {
                        self.selectedTag = nil
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(skin.accentColor.opacity(0.16))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
        }
        .padding(16)
        .background(skin.backgroundColor)
    }

    @ViewBuilder
    private var detailPane: some View {
        if let currentLibraryKind, let selectedAsset, selectedAsset.kind == currentLibraryKind {
            AssetDetailView(
                asset: selectedAsset,
                categories: libraryCategories,
                onDelete: { deleteAsset(selectedAsset) }
            )
        } else if let currentLibraryKind {
            ContentUnavailableView(
                currentLibraryKind == .font ? "Sélectionnez une police" : "Sélectionnez un élément image",
                systemImage: currentLibraryKind.systemImage,
                description: Text("L’aperçu, les métadonnées et les catégories s’affichent ici.")
            )
        } else if let selectedItem {
            ItemDetailView(
                item: selectedItem,
                secretStore: secretStore,
                lockService: lockService,
                onEdit: { edit(selectedItem) },
                onDelete: { delete(selectedItem) }
            )
        } else {
            ContentUnavailableView("Sélectionnez un élément", systemImage: "sidebar.right", description: Text("Les détails, mots de passe et aperçus d’inspiration s’affichent ici."))
        }
    }

    private var sectionTitle: String {
        switch selectedSection {
        case .all:
            "Tous les éléments"
        case .type(let type):
            type.displayName
        case .accountCategory(let category):
            category.displayName
        case .library(let kind):
            kind.displayName
        }
    }

    private var emptyTitle: String {
        selectedTag == nil && searchText.isEmpty ? "Aucun contenu pour le moment" : "Aucun élément correspondant"
    }

    private var emptyDescription: String {
        selectedTag == nil && searchText.isEmpty ? "Cliquez sur Nouveau pour enregistrer un compte, une inspiration ou une URL." : "Essayez un autre terme, une autre catégorie ou une autre étiquette."
    }

    private var emptyImage: String {
        currentType?.systemImage ?? "tray"
    }

    private func count(for type: VaultItemType) -> Int {
        items.filter { $0.type == type && !$0.isDeleted && !$0.isArchived }.count
    }

    private func count(for kind: LibraryAssetKind) -> Int {
        libraryAssets.filter { $0.kind == kind }.count
    }

    private var accountCount: Int {
        count(for: .account)
    }

    private func count(for category: AccountCategory) -> Int {
        items.filter { $0.type == .account && $0.accountCategory == category && !$0.isDeleted && !$0.isArchived }.count
    }

    private func accounts(for category: AccountCategory) -> [VaultItem] {
        filteredItems.filter { $0.type == .account && $0.accountCategory == category }
    }

    private func toggle(_ category: AccountCategory) {
        if expandedAccountCategories.contains(category) {
            expandedAccountCategories.remove(category)
        } else {
            expandedAccountCategories.insert(category)
        }
    }

    private func copyUsername(for item: VaultItem) {
        guard item.type == .account, !item.username.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.username, forType: .string)
        copiedUsernameItemID = item.id

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.4))
            if copiedUsernameItemID == item.id {
                copiedUsernameItemID = nil
            }
        }
    }

    private func newItem(defaultType: VaultItemType) {
        if defaultType == .inspiration {
            let newItem = VaultItem(type: .inspiration, title: "Nouvelle inspiration", notes: "", tags: [], contentFormat: .markdown)
            modelContext.insert(newItem)
            try? modelContext.save()
            selectedSection = .type(.inspiration)
            selectedItem = newItem
            return
        }
        editingItem = nil
        selectedSection = .type(defaultType)
        isShowingEditor = true
    }

    private func edit(_ item: VaultItem) {
        if item.type == .inspiration {
            selectedItem = item
            return
        }
        editingItem = item
        isShowingEditor = true
    }

    private func delete(_ item: VaultItem) {
        if let secretIdentifier = item.secretIdentifier {
            try? secretStore.deleteSecret(identifier: secretIdentifier)
        }
        modelContext.delete(item)
        if selectedItem?.id == item.id {
            selectedItem = nil
        }
        try? modelContext.save()
    }

    private func deleteAsset(_ asset: LibraryAsset) {
        try? AssetFileStore().deleteFile(for: asset)
        modelContext.delete(asset)
        if selectedAsset?.id == asset.id {
            selectedAsset = nil
        }
        try? modelContext.save()
    }
}

private struct AccountCategorySection: View {
    @Environment(\.meimoireSkin) private var skin
    let category: AccountCategory
    let items: [VaultItem]
    let isExpanded: Bool
    let selectedItemID: UUID?
    let copiedUsernameItemID: UUID?
    let onToggle: () -> Void
    let onSelect: (VaultItem) -> Void
    let onCopyUsername: (VaultItem) -> Void
    let onEdit: (VaultItem) -> Void
    let onDelete: (VaultItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 10) {
                    Image(systemName: category.symbolName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(skin.color(for: category).gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                    Text(category.displayName)
                        .font(.headline)
                        .foregroundStyle(skin.textColor)
                    Spacer()
                    Text("\(items.count)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(skin.secondaryTextColor)
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(skin.secondaryTextColor)
                        .frame(width: 18)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                if items.isEmpty {
                    Text("Aucun compte dans cette catégorie")
                        .font(.caption)
                        .foregroundStyle(skin.secondaryTextColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 12)
                } else {
                    VStack(spacing: 4) {
                        ForEach(items) { item in
                            ItemRow(
                                item: item,
                                isSelected: selectedItemID == item.id,
                                isUsernameCopied: copiedUsernameItemID == item.id,
                                onCopyUsername: { onCopyUsername(item) }
                            )
                            .padding(.horizontal, 10)
                            .background(selectedItemID == item.id ? skin.accentColor.opacity(0.16) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onSelect(item)
                            }
                            .contextMenu {
                                Button("Modifier") {
                                    onEdit(item)
                                }
                                Button("Supprimer", role: .destructive) {
                                    onDelete(item)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.bottom, 8)
                }
            }
        }
        .background(skin.panelColor)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(skin.borderColor, lineWidth: 1)
        }
    }
}

private struct SidebarText: View {
    @Environment(\.meimoireSkin) private var skin
    let title: String
    let count: Int

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
            Text("\(count)")
                .font(.caption2.weight(.medium))
                .foregroundStyle(skin.secondaryTextColor)
        }
    }
}

private struct ItemRow: View {
    @Environment(\.meimoireSkin) private var skin
    let item: VaultItem
    var isSelected = false
    var isUsernameCopied = false
    var onCopyUsername: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            CategoryIconView(item: item, size: 40)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(item.title.isEmpty ? "Sans titre" : item.title)
                        .font(.headline)
                        .lineLimit(1)
                    if item.type == .account {
                        Text(item.accountCategory.displayName)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(skin.color(for: item.accountCategory))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(skin.color(for: item.accountCategory).opacity(0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    }
                }

                Text(item.quietSubtitle.isEmpty ? "Aucun résumé" : item.quietSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(skin.secondaryTextColor)
                    .lineLimit(2)

                if item.type == .account, !item.username.isEmpty {
                    HStack(spacing: 6) {
                        Text(item.username)
                            .font(.caption)
                            .foregroundStyle(skin.secondaryTextColor)
                            .lineLimit(1)
                            .textSelection(.enabled)
                        Button {
                            onCopyUsername?()
                        } label: {
                            Label(isUsernameCopied ? "Copié" : "Copier le nom d’utilisateur", systemImage: isUsernameCopied ? "checkmark" : "doc.on.doc")
                                .labelStyle(.iconOnly)
                                .frame(width: 26, height: 24)
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(isUsernameCopied ? skin.accentColor : skin.secondaryTextColor)
                        .help(isUsernameCopied ? "Copié" : "Copier le nom d’utilisateur")
                    }
                }

                if !item.tags.isEmpty {
                    Text(item.tags.prefix(4).map { "#\($0)" }.joined(separator: " "))
                        .font(.caption)
                        .foregroundStyle(skin.secondaryTextColor.opacity(0.72))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 6) {
                Text(item.updatedAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(skin.secondaryTextColor.opacity(0.72))
                if item.type == .url, !item.urlString.isEmpty {
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(skin.secondaryTextColor)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, isSelected ? 2 : 0)
    }
}
