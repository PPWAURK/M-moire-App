import MeimoireCore
import SwiftData
import SwiftUI

@main
struct MeimoireApp: App {
    @NSApplicationDelegateAdaptor(WindowBehaviorDelegate.self) private var windowBehaviorDelegate
    @State private var skinManager = SkinManager()
    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: VaultItem.self, LibraryAsset.self, LibraryCategory.self)
        } catch {
            fatalError("Impossible de créer la base de données locale : \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 980, minHeight: 640)
                .environment(skinManager)
                .environment(\.meimoireSkin, skinManager.selectedSkin)
                .preferredColorScheme(skinManager.selectedSkin.colorScheme)
                .tint(skinManager.selectedSkin.accentColor)
        }
        .modelContainer(container)
        .defaultSize(width: 1280, height: 820)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Nouvel élément") {
                    NotificationCenter.default.post(name: .meimoireCreateItem, object: nil)
                }
                .keyboardShortcut("n")
            }
        }

        Settings {
            SkinSettingsView()
                .environment(skinManager)
                .environment(\.meimoireSkin, skinManager.selectedSkin)
                .preferredColorScheme(skinManager.selectedSkin.colorScheme)
                .tint(skinManager.selectedSkin.accentColor)
                .frame(width: 680, height: 520)
        }
    }
}

extension Notification.Name {
    static let meimoireCreateItem = Notification.Name("meimoireCreateItem")
    static let meimoireImportAsset = Notification.Name("meimoireImportAsset")
}
