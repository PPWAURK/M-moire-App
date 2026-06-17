import AppKit
import MeimoireCore
import SwiftUI

struct AssetDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.meimoireSkin) private var skin

    let asset: LibraryAsset
    let categories: [LibraryCategory]
    let onDelete: () -> Void

    @State private var title = ""
    @State private var categoryID: UUID?
    @State private var tags = ""
    @State private var notes = ""
    @State private var saveMessage: String?

    private let fileStore = AssetFileStore()

    private var kindCategories: [LibraryCategory] {
        categories
            .filter { $0.kind == asset.kind }
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                previewPanel
                editPanel
                metadataPanel
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(skin.backgroundColor)
        .navigationTitle(asset.displayTitle)
        .onAppear(perform: sync)
        .onChange(of: asset.id) { _, _ in sync() }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: asset.kind.systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(skin.accentColor.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(asset.displayTitle)
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(skin.textColor)
                    .lineLimit(2)
                Text(asset.kind.singularName)
                    .font(.headline)
                    .foregroundStyle(skin.secondaryTextColor)
                if !asset.tags.isEmpty {
                    FlowTags(tags: asset.tags)
                }
            }

            Spacer()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Supprimer", systemImage: "trash")
            }
        }
    }

    private var previewPanel: some View {
        DetailPanel(title: "Aperçu", systemImage: asset.kind.systemImage) {
            Group {
                if asset.kind == .font {
                    fontPreview
                } else {
                    imagePreview
                }
            }
            .frame(maxWidth: .infinity, minHeight: 220)
            .background(skin.markdownBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private var fontPreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Aa Bb Cc")
                .font(FontPreviewService.previewFont(for: asset, fileURL: fileStore.fileURL(for: asset), size: 44))
                .foregroundStyle(skin.textColor)
            Text("Portez ce vieux whisky au juge blond qui fume.")
                .font(FontPreviewService.previewFont(for: asset, fileURL: fileStore.fileURL(for: asset), size: 22))
                .foregroundStyle(skin.textColor)
            Text(asset.fontDisplayName.isEmpty ? asset.originalFilename : asset.fontDisplayName)
                .font(.caption)
                .foregroundStyle(skin.secondaryTextColor)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var imagePreview: some View {
        Group {
            if let image = NSImage(contentsOf: fileStore.fileURL(for: asset)) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(16)
            } else {
                ContentUnavailableView("Aperçu indisponible", systemImage: "photo", description: Text("Le fichier peut toujours être conservé dans la bibliothèque."))
            }
        }
    }

    private var editPanel: some View {
        DetailPanel(title: "Informations", systemImage: "pencil") {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Titre", text: $title)
                    .textFieldStyle(.roundedBorder)

                Picker("Catégorie", selection: $categoryID) {
                    Text("Non classé").tag(UUID?.none)
                    ForEach(kindCategories) { category in
                        Text(category.name).tag(Optional(category.id))
                    }
                }
                .pickerStyle(.menu)

                TextField("Étiquettes, séparées par des virgules", text: $tags)
                    .textFieldStyle(.roundedBorder)

                TextEditor(text: $notes)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(skin.markdownBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(skin.borderColor, lineWidth: 1)
                    }

                HStack {
                    if let saveMessage {
                        Text(saveMessage)
                            .font(.caption)
                            .foregroundStyle(skin.secondaryTextColor)
                    }
                    Spacer()
                    Button("Enregistrer") {
                        save()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private var metadataPanel: some View {
        DetailPanel(title: "Métadonnées", systemImage: "info.circle") {
            VStack(alignment: .leading, spacing: 12) {
                DetailLine(label: "Fichier original", value: asset.originalFilename)
                DetailLine(label: "Format", value: asset.format)
                DetailLine(label: "Taille", value: ByteCountFormatter.string(fromByteCount: asset.fileSize, countStyle: .file))
                if !asset.dimensionText.isEmpty {
                    DetailLine(label: "Dimensions", value: asset.dimensionText)
                }
                DetailLine(label: "Importé", value: asset.createdAt.formatted(date: .abbreviated, time: .shortened))
                DetailLine(label: "Mis à jour", value: asset.updatedAt.formatted(date: .abbreviated, time: .shortened))
            }
        }
    }

    private func sync() {
        title = asset.displayTitle
        categoryID = asset.categoryID
        tags = asset.tags.joined(separator: ", ")
        notes = asset.notes
        saveMessage = nil
    }

    private func save() {
        asset.update(
            title: title,
            categoryID: categoryID,
            tags: tags.split(separator: ",").map(String.init),
            notes: notes
        )
        do {
            try modelContext.save()
            saveMessage = "Enregistré."
        } catch {
            saveMessage = error.localizedDescription
        }
    }
}
