import AppKit

@MainActor
final class WindowBehaviorDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        configureAllWindows()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeVisible(_:)),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeVisible(_:)),
            name: NSWindow.didBecomeMainNotification,
            object: nil
        )
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        configureAllWindows()
        return true
    }

    @objc private func windowDidBecomeVisible(_ notification: Notification) {
        Self.configure(notification.object as? NSWindow)
    }

    private func configureAllWindows() {
        NSApplication.shared.windows.forEach(Self.configure)
        Task { @MainActor in
            NSApplication.shared.windows.forEach(Self.configure)
        }
    }

    private static func configure(_ window: NSWindow?) {
        guard let window, !(window is NSPanel) else { return }

        window.styleMask.insert([.titled, .closable, .miniaturizable, .resizable])
        window.minSize = NSSize(width: 980, height: 640)
        window.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        var behavior = window.collectionBehavior
        behavior.remove(.fullScreenNone)
        behavior.remove(.fullScreenAuxiliary)
        behavior.insert(.managed)
        behavior.insert(.fullScreenPrimary)
        window.collectionBehavior = behavior

        if let zoomButton = window.standardWindowButton(.zoomButton) {
            zoomButton.isHidden = false
            zoomButton.isEnabled = true
        }
    }
}
