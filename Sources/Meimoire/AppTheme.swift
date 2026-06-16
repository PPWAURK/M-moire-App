import AppKit
import MeimoireCore
import SwiftUI

enum AppTheme {
    static let fallback = MeimoireSkin.defaultSkin
}

extension MeimoireSkin {
    var colorScheme: ColorScheme {
        appearance == .dark ? .dark : .light
    }

    var accentColor: Color { Color(hex: palette.accent) }
    var secondaryAccentColor: Color { Color(hex: palette.secondaryAccent) }
    var backgroundColor: Color { Color(hex: palette.background) }
    var panelColor: Color { Color(hex: palette.panel) }
    var listColor: Color { Color(hex: palette.list) }
    var borderColor: Color { Color(hex: palette.border) }
    var textColor: Color { Color(hex: palette.text) }
    var secondaryTextColor: Color { Color(hex: palette.secondaryText) }
    var dangerColor: Color { Color(hex: palette.danger) }
    var markdownBackgroundColor: Color { Color(hex: palette.markdownBackground) }
    var markdownTextColor: Color { Color(hex: palette.markdownText) }
    var selectionColor: Color { Color(hex: palette.selection) }

    func color(for category: AccountCategory) -> Color {
        Color(hex: categoryColor(for: category))
    }
}

extension EnvironmentValues {
    var meimoireSkin: MeimoireSkin {
        get { self[MeimoireSkinKey.self] }
        set { self[MeimoireSkinKey.self] = newValue }
    }
}

private struct MeimoireSkinKey: EnvironmentKey {
    static let defaultValue: MeimoireSkin = .defaultSkin
}

extension Color {
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)

        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double

        switch sanitized.count {
        case 8:
            red = Double((value >> 24) & 0xFF) / 255
            green = Double((value >> 16) & 0xFF) / 255
            blue = Double((value >> 8) & 0xFF) / 255
            alpha = Double(value & 0xFF) / 255
        case 6:
            red = Double((value >> 16) & 0xFF) / 255
            green = Double((value >> 8) & 0xFF) / 255
            blue = Double(value & 0xFF) / 255
            alpha = 1
        default:
            red = 0
            green = 0
            blue = 0
            alpha = 1
        }

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

extension NSColor {
    convenience init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)

        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let alpha: CGFloat

        switch sanitized.count {
        case 8:
            red = CGFloat((value >> 24) & 0xFF) / 255
            green = CGFloat((value >> 16) & 0xFF) / 255
            blue = CGFloat((value >> 8) & 0xFF) / 255
            alpha = CGFloat(value & 0xFF) / 255
        case 6:
            red = CGFloat((value >> 16) & 0xFF) / 255
            green = CGFloat((value >> 8) & 0xFF) / 255
            blue = CGFloat(value & 0xFF) / 255
            alpha = 1
        default:
            red = 0
            green = 0
            blue = 0
            alpha = 1
        }

        self.init(srgbRed: red, green: green, blue: blue, alpha: alpha)
    }
}

extension VaultItem {
    var displayDomain: String {
        let normalized = URLValidator.normalizedURLString(urlString)
        guard let host = URL(string: normalized)?.host(percentEncoded: false) else {
            return urlString
        }
        return host.replacingOccurrences(of: "www.", with: "")
    }

    var quietSubtitle: String {
        switch type {
        case .account:
            [username, displayDomain].filter { !$0.isEmpty }.joined(separator: " · ")
        case .inspiration:
            notes
                .replacingOccurrences(of: "#", with: "")
                .replacingOccurrences(of: "*", with: "")
                .replacingOccurrences(of: "`", with: "")
        case .url:
            displayDomain
        }
    }
}
