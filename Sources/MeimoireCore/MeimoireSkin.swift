import Foundation

public enum SkinAppearance: String, Codable, Sendable {
    case light
    case dark
}

public struct SkinPalette: Codable, Equatable, Sendable {
    public var accent: String
    public var secondaryAccent: String
    public var background: String
    public var panel: String
    public var list: String
    public var border: String
    public var text: String
    public var secondaryText: String
    public var danger: String
    public var markdownBackground: String
    public var markdownText: String
    public var selection: String
    public var categoryColors: [AccountCategory: String]

    public init(
        accent: String,
        secondaryAccent: String,
        background: String,
        panel: String,
        list: String,
        border: String,
        text: String,
        secondaryText: String,
        danger: String,
        markdownBackground: String,
        markdownText: String,
        selection: String,
        categoryColors: [AccountCategory: String]
    ) {
        self.accent = accent
        self.secondaryAccent = secondaryAccent
        self.background = background
        self.panel = panel
        self.list = list
        self.border = border
        self.text = text
        self.secondaryText = secondaryText
        self.danger = danger
        self.markdownBackground = markdownBackground
        self.markdownText = markdownText
        self.selection = selection
        self.categoryColors = categoryColors
    }
}

public enum MeimoireSkin: String, Codable, CaseIterable, Identifiable, Sendable {
    case ink
    case paper
    case mintVault
    case coralNotes

    public static let defaultSkin: MeimoireSkin = .ink

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .ink:
            "Meimoire Ink"
        case .paper:
            "Meimoire Paper"
        case .mintVault:
            "Mint Vault"
        case .coralNotes:
            "Coral Notes"
        }
    }

    public var summary: String {
        switch self {
        case .ink:
            "Bleu encre, accents menthe et corail, idéal pour conserver des données privées."
        case .paper:
            "Fond papier doux et texte bleu profond, idéal pour organiser vos notes en journée."
        case .mintVault:
            "Palette vert-bleu apaisée, pensée pour la sécurité et la gestion des comptes."
        case .coralNotes:
            "Accents corail chaleureux, adaptés aux inspirations et aux longs documents."
        }
    }

    public var appearance: SkinAppearance {
        switch self {
        case .ink, .mintVault:
            .dark
        case .paper, .coralNotes:
            .light
        }
    }

    public var palette: SkinPalette {
        switch self {
        case .ink:
            SkinPalette(
                accent: "#6BDCC2",
                secondaryAccent: "#F56B4F",
                background: "#101727",
                panel: "#172235",
                list: "#121B2C",
                border: "#334158",
                text: "#EEF6F4",
                secondaryText: "#9FB0C5",
                danger: "#FF6B6B",
                markdownBackground: "#0E1624",
                markdownText: "#EEF6F4",
                selection: "#2F665F",
                categoryColors: Self.categoryColors(
                    work: "#4C7FD6",
                    social: "#B965A3",
                    email: "#5FA7DE",
                    banking: "#48A887",
                    shopping: "#E58B55",
                    development: "#7E8EA8",
                    cloud: "#55B7CA",
                    subscription: "#9382D2",
                    gaming: "#D66E63",
                    other: "#8993A5"
                )
            )
        case .paper:
            SkinPalette(
                accent: "#3DB89F",
                secondaryAccent: "#E7654E",
                background: "#F6F2EA",
                panel: "#FFFDF8",
                list: "#EEE8DC",
                border: "#D8CCBA",
                text: "#132033",
                secondaryText: "#68717F",
                danger: "#C84545",
                markdownBackground: "#FFFDF8",
                markdownText: "#132033",
                selection: "#CFE8DF",
                categoryColors: Self.categoryColors(
                    work: "#416EB8",
                    social: "#A85288",
                    email: "#3F83BA",
                    banking: "#31866E",
                    shopping: "#C96C3C",
                    development: "#5F6878",
                    cloud: "#409BAE",
                    subscription: "#7664B5",
                    gaming: "#BA574E",
                    other: "#717783"
                )
            )
        case .mintVault:
            SkinPalette(
                accent: "#8CE7D6",
                secondaryAccent: "#A7C7B7",
                background: "#10201F",
                panel: "#17302D",
                list: "#132725",
                border: "#31524D",
                text: "#ECFAF6",
                secondaryText: "#A9C7C0",
                danger: "#F0786F",
                markdownBackground: "#0F1C1B",
                markdownText: "#ECFAF6",
                selection: "#3C746B",
                categoryColors: Self.categoryColors(
                    work: "#5C91C8",
                    social: "#B7789A",
                    email: "#70AFCF",
                    banking: "#62C2A1",
                    shopping: "#D99A66",
                    development: "#7C938F",
                    cloud: "#69C5D4",
                    subscription: "#95A3D1",
                    gaming: "#CC7B72",
                    other: "#879993"
                )
            )
        case .coralNotes:
            SkinPalette(
                accent: "#E9674F",
                secondaryAccent: "#4FB7A6",
                background: "#FBF0EA",
                panel: "#FFF9F4",
                list: "#F3E4DB",
                border: "#E4C8BB",
                text: "#2A1C1A",
                secondaryText: "#786A65",
                danger: "#BE3F42",
                markdownBackground: "#FFF9F4",
                markdownText: "#2A1C1A",
                selection: "#F5D3C8",
                categoryColors: Self.categoryColors(
                    work: "#586FAF",
                    social: "#B55F7E",
                    email: "#4C88B1",
                    banking: "#4D9578",
                    shopping: "#D8794C",
                    development: "#6B6470",
                    cloud: "#5EA9B4",
                    subscription: "#8770B7",
                    gaming: "#C96358",
                    other: "#807774"
                )
            )
        }
    }

    public static func skin(for id: String) -> MeimoireSkin {
        MeimoireSkin(rawValue: id) ?? defaultSkin
    }

    public func categoryColor(for category: AccountCategory) -> String {
        palette.categoryColors[category] ?? palette.categoryColors[.other] ?? palette.accent
    }

    private static func categoryColors(
        work: String,
        social: String,
        email: String,
        banking: String,
        shopping: String,
        development: String,
        cloud: String,
        subscription: String,
        gaming: String,
        other: String
    ) -> [AccountCategory: String] {
        [
            .work: work,
            .social: social,
            .email: email,
            .banking: banking,
            .shopping: shopping,
            .development: development,
            .cloud: cloud,
            .subscription: subscription,
            .gaming: gaming,
            .other: other
        ]
    }
}
