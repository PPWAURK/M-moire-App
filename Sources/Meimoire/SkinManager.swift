import MeimoireCore
import Observation
import SwiftUI

@Observable
final class SkinManager {
    @ObservationIgnored
    @AppStorage("meimoire.selectedSkinID") private var storedSkinID = MeimoireSkin.defaultSkin.id

    var selectedSkinID = MeimoireSkin.defaultSkin.id {
        didSet {
            storedSkinID = selectedSkinID
        }
    }

    init() {
        let persistedSkinID = storedSkinID
        selectedSkinID = MeimoireSkin(rawValue: persistedSkinID)?.id ?? MeimoireSkin.defaultSkin.id
    }

    var selectedSkin: MeimoireSkin {
        MeimoireSkin.skin(for: selectedSkinID)
    }

    func select(_ skin: MeimoireSkin) {
        selectedSkinID = skin.id
    }
}
