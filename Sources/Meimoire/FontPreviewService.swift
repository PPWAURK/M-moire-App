import CoreGraphics
import CoreText
import Foundation
import MeimoireCore
import SwiftUI

enum FontPreviewService {
    static func registerFont(at url: URL) {
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }

    static func displayName(for url: URL) -> String {
        guard let provider = CGDataProvider(url: url as CFURL),
              let font = CGFont(provider) else {
            return ""
        }
        if let fullName = font.fullName as String? {
            return fullName
        }
        if let postScriptName = font.postScriptName as String? {
            return postScriptName
        }
        return ""
    }

    static func previewFont(for asset: LibraryAsset, fileURL: URL, size: CGFloat) -> Font {
        registerFont(at: fileURL)
        let name = asset.fontDisplayName.isEmpty ? asset.displayTitle : asset.fontDisplayName
        return .custom(name, size: size)
    }
}
