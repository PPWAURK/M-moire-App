import Foundation

public struct StoredAssetFile: Equatable, Sendable {
    public let storedFilename: String
    public let relativePath: String
    public let fileSize: Int64
    public let format: String
    public let localURL: URL
}

public enum AssetFileStoreError: LocalizedError, Equatable {
    case unsupportedFileType(String)
    case missingExtension

    public var errorDescription: String? {
        switch self {
        case .unsupportedFileType(let ext):
            "Type de fichier non pris en charge : \(ext)"
        case .missingExtension:
            "Le fichier n’a pas d’extension reconnue."
        }
    }
}

public struct AssetFileStore: Sendable {
    public let rootDirectory: URL

    public init(rootDirectory: URL? = nil) {
        if let rootDirectory {
            self.rootDirectory = rootDirectory
        } else {
            let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? FileManager.default.homeDirectoryForCurrentUser
            self.rootDirectory = support.appendingPathComponent("Meimoire", isDirectory: true)
        }
    }

    public func isSupported(_ url: URL, as kind: LibraryAssetKind) -> Bool {
        guard let ext = normalizedExtension(for: url) else { return false }
        return kind.allowedExtensions.contains(ext)
    }

    public func importFile(at sourceURL: URL, as kind: LibraryAssetKind, id: UUID = UUID()) throws -> StoredAssetFile {
        guard let ext = normalizedExtension(for: sourceURL) else {
            throw AssetFileStoreError.missingExtension
        }
        guard kind.allowedExtensions.contains(ext) else {
            throw AssetFileStoreError.unsupportedFileType(ext)
        }

        let directory = directoryURL(for: kind)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let storedFilename = Self.storedFilename(for: sourceURL.lastPathComponent, id: id)
        let destination = directory.appendingPathComponent(storedFilename, isDirectory: false)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destination)

        return StoredAssetFile(
            storedFilename: storedFilename,
            relativePath: relativePath(for: kind, storedFilename: storedFilename),
            fileSize: fileSize(at: destination),
            format: ext.uppercased(),
            localURL: destination
        )
    }

    public func fileURL(for asset: LibraryAsset) -> URL {
        rootDirectory.appendingPathComponent(asset.relativePath, isDirectory: false)
    }

    public func deleteFile(for asset: LibraryAsset) throws {
        let url = fileURL(for: asset)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    public func directoryURL(for kind: LibraryAssetKind) -> URL {
        rootDirectory
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent(kind.storageDirectoryName, isDirectory: true)
    }

    public static func storedFilename(for originalFilename: String, id: UUID) -> String {
        let ext = URL(fileURLWithPath: originalFilename).pathExtension.lowercased()
        return ext.isEmpty ? id.uuidString : "\(id.uuidString).\(ext)"
    }

    public static func title(from filename: String) -> String {
        let stem = URL(fileURLWithPath: filename).deletingPathExtension().lastPathComponent
        return stem.isEmpty ? filename : stem
    }

    private func normalizedExtension(for url: URL) -> String? {
        let ext = url.pathExtension.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return ext.isEmpty ? nil : ext
    }

    private func relativePath(for kind: LibraryAssetKind, storedFilename: String) -> String {
        "Library/\(kind.storageDirectoryName)/\(storedFilename)"
    }

    private func fileSize(at url: URL) -> Int64 {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(values?.fileSize ?? 0)
    }
}
