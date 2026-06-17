import AppKit
import MeimoireCore
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.meimoireSkin) private var skin

    let kind: LibraryAssetKind
    let assets: [LibraryAsset]
    let categories: [LibraryCategory]
    @Binding var selectedAsset: LibraryAsset?

    @State private var searchText = ""
    @State private var selectedFilter: LibraryCategoryFilter = .all
    @State private var isImporting = false
    @State private var categoryEditor: CategoryEditor?
    @State private var errorMessage: String?

    private let fileStore = AssetFileStore()

    private var kindCategories: [LibraryCategory] {
        categories
            .filter { $0.kind == kind }
            .sorted {
                if $0.sortOrder == $1.sortOrder {
                    return $0.name.localizedCompare($1.name) == .orderedAscending
                }
                return $0.sortOrder < $1.sortOrder
            }
    }

    private var kindAssets: [LibraryAsset] {
        assets.filter { $0.kind == kind }
    }

    private var filteredAssets: [LibraryAsset] {
        kindAssets.filter { asset in
            switch selectedFilter {
            case .all:
                break
            case .uncategorized:
                guard asset.categoryID == nil else { return false }
            case .category(let id):
                guard asset.categoryID == id else { return false }
            }
            return asset.matches(query: searchText, categoryName: categoryName(for: asset))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            HStack(spacing: 0) {
                categorySidebar
                    .frame(width: 190)

                Divider()

                assetGrid
            }
        }
        .background(skin.listColor)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: allowedContentTypes,
            allowsMultipleSelection: true,
            onCompletion: handleImport
        )
        .sheet(item: $categoryEditor) { editor in
            CategoryEditorSheet(editor: editor) { name in
                saveCategory(editor, name: name)
            }
            .environment(\.meimoireSkin, skin)
        }
        .onReceive(NotificationCenter.default.publisher(for: .meimoireImportAsset)) { notification in
            guard let rawValue = notification.object as? String,
                  LibraryAssetKind(rawValue: rawValue) == kind else { return }
            isImporting = true
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.displayName)
                        .font(.title2.weight(.semibold))
                    Text("\(filteredAssets.count) éléments")
                        .font(.caption)
                        .foregroundStyle(skin.secondaryTextColor)
                }

                Spacer()

                Button {
                    isImporting = true
                } label: {
                    Label(kind == .font ? "Importer des polices" : "Importer des images", systemImage: "tray.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(skin.secondaryTextColor)
                TextField("Rechercher titre, fichier, format, catégorie, note ou étiquette", text: $searchText)
                    .textFieldStyle(.plain)
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

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(skin.dangerColor)
            }
        }
        .padding(16)
        .background(skin.backgroundColor)
    }

    private var categorySidebar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Catégories")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(skin.secondaryTextColor)
                    .textCase(.uppercase)
                Spacer()
                Button {
                    categoryEditor = CategoryEditor(kind: kind, category: nil, title: "Nouvelle catégorie")
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help("Créer une catégorie")
            }

            categoryButton(.all, title: "Toutes", count: kindAssets.count, systemImage: "tray.full")
            categoryButton(.uncategorized, title: "Non classé", count: count(categoryID: nil), systemImage: "questionmark.folder")

            ForEach(kindCategories) { category in
                categoryButton(.category(category.id), title: category.name, count: count(categoryID: category.id), systemImage: "folder")
                    .contextMenu {
                        Button("Renommer") {
                            categoryEditor = CategoryEditor(kind: kind, category: category, title: "Renommer la catégorie")
                        }
                        Button("Supprimer", role: .destructive) {
                            deleteCategory(category)
                        }
                    }
            }

            Spacer()
        }
        .padding(12)
        .background(skin.listColor)
    }

    private func categoryButton(_ filter: LibraryCategoryFilter, title: String, count: Int, systemImage: String) -> some View {
        Button {
            selectedFilter = filter
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .frame(width: 18)
                Text(title)
                    .lineLimit(1)
                Spacer()
                Text("\(count)")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(skin.secondaryTextColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .foregroundStyle(selectedFilter == filter ? skin.textColor : skin.secondaryTextColor)
            .background(selectedFilter == filter ? skin.accentColor.opacity(0.16) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var assetGrid: some View {
        ScrollView {
            if filteredAssets.isEmpty {
                ContentUnavailableView(
                    kind == .font ? "Aucune police" : "Aucun élément image",
                    systemImage: kind.systemImage,
                    description: Text("Importez des fichiers pour construire votre bibliothèque privée.")
                )
                .frame(maxWidth: .infinity, minHeight: 420)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 12)], spacing: 12) {
                    ForEach(filteredAssets) { asset in
                        AssetGridCard(
                            asset: asset,
                            fileURL: fileStore.fileURL(for: asset),
                            categoryName: categoryName(for: asset),
                            isSelected: selectedAsset?.id == asset.id
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedAsset = asset
                        }
                        .contextMenu {
                            Button("Supprimer", role: .destructive) {
                                deleteAsset(asset)
                            }
                        }
                    }
                }
                .padding(14)
            }
        }
        .background(skin.listColor)
    }

    private var allowedContentTypes: [UTType] {
        kind.allowedExtensions.compactMap { UTType(filenameExtension: $0) } + [.data]
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        errorMessage = nil
        do {
            let urls = try result.get()
            for url in urls {
                try importAsset(from: url)
            }
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func importAsset(from url: URL) throws {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let id = UUID()
        let stored = try fileStore.importFile(at: url, as: kind, id: id)
        let metadata = metadata(for: kind, fileURL: stored.localURL)
        let asset = LibraryAsset(
            id: id,
            kind: kind,
            title: AssetFileStore.title(from: url.lastPathComponent),
            originalFilename: url.lastPathComponent,
            storedFilename: stored.storedFilename,
            relativePath: stored.relativePath,
            categoryID: importCategoryID,
            tags: [],
            notes: "",
            fileSize: stored.fileSize,
            format: stored.format,
            pixelWidth: metadata.width,
            pixelHeight: metadata.height,
            fontDisplayName: metadata.fontName
        )
        modelContext.insert(asset)
        selectedAsset = asset
    }

    private var importCategoryID: UUID? {
        if case .category(let id) = selectedFilter {
            return id
        }
        return nil
    }

    private func metadata(for kind: LibraryAssetKind, fileURL: URL) -> AssetMetadata {
        switch kind {
        case .font:
            let displayName = FontPreviewService.displayName(for: fileURL)
            return AssetMetadata(width: nil, height: nil, fontName: displayName)
        case .image:
            guard let image = NSImage(contentsOf: fileURL) else {
                return AssetMetadata(width: nil, height: nil, fontName: "")
            }
            return AssetMetadata(width: Int(image.size.width.rounded()), height: Int(image.size.height.rounded()), fontName: "")
        }
    }

    private func saveCategory(_ editor: CategoryEditor, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let category = editor.category {
            category.update(name: trimmed)
        } else {
            let nextOrder = (kindCategories.map(\.sortOrder).max() ?? 0) + 1
            modelContext.insert(LibraryCategory(kind: editor.kind, name: trimmed, sortOrder: nextOrder))
        }
        try? modelContext.save()
    }

    private func deleteCategory(_ category: LibraryCategory) {
        kindAssets
            .filter { $0.categoryID == category.id }
            .forEach { $0.categoryID = nil }
        if selectedFilter == .category(category.id) {
            selectedFilter = .all
        }
        modelContext.delete(category)
        try? modelContext.save()
    }

    private func deleteAsset(_ asset: LibraryAsset) {
        try? fileStore.deleteFile(for: asset)
        modelContext.delete(asset)
        if selectedAsset?.id == asset.id {
            selectedAsset = nil
        }
        try? modelContext.save()
    }

    private func count(categoryID: UUID?) -> Int {
        kindAssets.filter { $0.categoryID == categoryID }.count
    }

    private func categoryName(for asset: LibraryAsset) -> String {
        guard let categoryID = asset.categoryID,
              let category = kindCategories.first(where: { $0.id == categoryID }) else {
            return "Non classé"
        }
        return category.name
    }
}

private struct AssetMetadata {
    let width: Int?
    let height: Int?
    let fontName: String
}

private enum LibraryCategoryFilter: Hashable {
    case all
    case uncategorized
    case category(UUID)
}

private struct CategoryEditor: Identifiable {
    let id = UUID()
    let kind: LibraryAssetKind
    let category: LibraryCategory?
    let title: String
}

private struct CategoryEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.meimoireSkin) private var skin
    let editor: CategoryEditor
    let onSave: (String) -> Void
    @State private var name: String

    init(editor: CategoryEditor, onSave: @escaping (String) -> Void) {
        self.editor = editor
        self.onSave = onSave
        _name = State(initialValue: editor.category?.name ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(editor.title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(skin.textColor)
            TextField("Nom de la catégorie", text: $name)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Annuler") {
                    dismiss()
                }
                Spacer()
                Button("Enregistrer") {
                    onSave(name)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 360)
        .background(skin.backgroundColor)
    }
}
