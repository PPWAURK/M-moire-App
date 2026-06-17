import Foundation
import MeimoireCore
import SwiftData
import Testing

@Suite("Library assets")
struct LibraryTests {
    @Test("Asset file store imports and deletes copied files")
    func assetFileStoreImportDelete() throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let source = root.appendingPathComponent("source-font.ttf")
        try Data("font".utf8).write(to: source)

        let store = AssetFileStore(rootDirectory: root.appendingPathComponent("AppSupport"))
        let id = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let stored = try store.importFile(at: source, as: .font, id: id)

        #expect(stored.storedFilename == "11111111-1111-1111-1111-111111111111.ttf")
        #expect(stored.relativePath == "Library/Fonts/11111111-1111-1111-1111-111111111111.ttf")
        #expect(stored.format == "TTF")
        #expect(stored.fileSize == 4)
        #expect(FileManager.default.fileExists(atPath: stored.localURL.path))

        let asset = LibraryAsset(
            id: id,
            kind: .font,
            title: "Source Font",
            originalFilename: "source-font.ttf",
            storedFilename: stored.storedFilename,
            relativePath: stored.relativePath
        )
        try store.deleteFile(for: asset)
        #expect(!FileManager.default.fileExists(atPath: stored.localURL.path))
    }

    @Test("Asset file store validates supported extensions")
    func assetFileStoreValidation() throws {
        let store = AssetFileStore(rootDirectory: temporaryDirectory())

        #expect(store.isSupported(URL(fileURLWithPath: "brand.otf"), as: .font))
        #expect(store.isSupported(URL(fileURLWithPath: "photo.webp"), as: .image))
        #expect(!store.isSupported(URL(fileURLWithPath: "notes.txt"), as: .font))

        do {
            _ = try store.importFile(at: URL(fileURLWithPath: "/tmp/notes.txt"), as: .image)
            Issue.record("Unsupported extension should throw")
        } catch AssetFileStoreError.unsupportedFileType("txt") {
            return
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Library models store categories, tags, and searchable metadata")
    func libraryModels() throws {
        let container = try ModelContainer(
            for: LibraryAsset.self, LibraryCategory.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let category = LibraryCategory(kind: .image, name: "Moodboard", sortOrder: 1)
        let asset = LibraryAsset(
            kind: .image,
            title: "Coral button",
            originalFilename: "button.png",
            storedFilename: "asset.png",
            relativePath: "Library/Images/asset.png",
            categoryID: category.id,
            tags: ["UI", "ui", "coral"],
            notes: "Bouton pour inspiration",
            fileSize: 1200,
            format: "png",
            pixelWidth: 320,
            pixelHeight: 180
        )

        context.insert(category)
        context.insert(asset)
        try context.save()

        let assets = try context.fetch(FetchDescriptor<LibraryAsset>())
        #expect(assets.count == 1)
        #expect(asset.tags == ["UI", "coral"])
        #expect(asset.format == "PNG")
        #expect(asset.dimensionText == "320 x 180")
        #expect(asset.matches(query: "mood", categoryName: category.name))
        #expect(asset.matches(query: "coral", categoryName: category.name))
        #expect(!asset.matches(query: "bank", categoryName: category.name))

        asset.update(title: "Updated", categoryID: nil, tags: ["Brand"], notes: "New note")
        #expect(asset.categoryID == nil)
        #expect(asset.tags == ["Brand"])
        #expect(asset.matches(query: "new note", categoryName: "Non classé"))
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("MeimoireTests-\(UUID().uuidString)", isDirectory: true)
    }
}
