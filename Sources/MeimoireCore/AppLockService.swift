import Foundation
import LocalAuthentication
import Observation

@Observable
public final class AppLockService {
    public private(set) var isUnlocked = false
    public private(set) var lastUnlockedAt: Date?
    public private(set) var lastErrorMessage: String?

    private let timeout: TimeInterval

    public init(timeout: TimeInterval = 300) {
        self.timeout = timeout
    }

    public var needsUnlock: Bool {
        guard isUnlocked, let lastUnlockedAt else { return true }
        return Date().timeIntervalSince(lastUnlockedAt) > timeout
    }

    @MainActor
    public func unlock(reason: String = "Déverrouillez Meimoire pour afficher ou copier les mots de passe.") async -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            lastErrorMessage = error?.localizedDescription ?? "Cette Mac ne prend pas en charge l’authentification locale."
            isUnlocked = false
            return false
        }

        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            isUnlocked = success
            lastUnlockedAt = success ? .now : nil
            lastErrorMessage = nil
            return success
        } catch {
            isUnlocked = false
            lastErrorMessage = error.localizedDescription
            return false
        }
    }

    @MainActor
    public func lock() {
        isUnlocked = false
        lastUnlockedAt = nil
    }
}
