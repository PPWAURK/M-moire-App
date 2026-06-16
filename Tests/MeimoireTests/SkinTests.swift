import MeimoireCore
import Testing

@Suite("Skins")
struct SkinTests {
    @Test("Built-in skins are complete and unique")
    func skinsAreCompleteAndUnique() {
        #expect(MeimoireSkin.allCases.count == 4)
        #expect(Set(MeimoireSkin.allCases.map(\.id)).count == MeimoireSkin.allCases.count)

        for skin in MeimoireSkin.allCases {
            #expect(!skin.displayName.isEmpty)
            #expect(!skin.summary.isEmpty)
            #expect(!skin.palette.accent.isEmpty)
            #expect(!skin.palette.background.isEmpty)
            #expect(!skin.palette.panel.isEmpty)
            #expect(!skin.palette.text.isEmpty)
            #expect(!skin.palette.markdownBackground.isEmpty)
            #expect(skin.palette.categoryColors.count == AccountCategory.allCases.count)
        }
    }

    @Test("Unknown skin ID falls back to default skin")
    func unknownSkinFallsBack() {
        #expect(MeimoireSkin.skin(for: "missing") == .ink)
        #expect(MeimoireSkin.skin(for: MeimoireSkin.paper.id) == .paper)
    }

    @Test("Every skin resolves all account category colors")
    func categoryColorsResolve() {
        for skin in MeimoireSkin.allCases {
            for category in AccountCategory.allCases {
                #expect(skin.categoryColor(for: category).hasPrefix("#"))
            }
        }
    }
}
