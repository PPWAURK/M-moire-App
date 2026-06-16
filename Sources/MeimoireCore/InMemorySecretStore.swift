import Foundation

public final class InMemorySecretStore: SecretStoreProtocol {
    private var secrets: [String: String] = [:]

    public init() {}

    public func saveSecret(_ secret: String, identifier: String? = nil) throws -> String {
        let normalizedSecret = secret.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedSecret.isEmpty else {
            throw SecretStoreError.emptySecret
        }
        let identifier = identifier ?? UUID().uuidString
        secrets[identifier] = secret
        return identifier
    }

    public func readSecret(identifier: String) throws -> String {
        guard let secret = secrets[identifier] else {
            throw SecretStoreError.itemNotFound
        }
        return secret
    }

    public func updateSecret(_ secret: String, identifier: String) throws {
        guard secrets[identifier] != nil else {
            throw SecretStoreError.itemNotFound
        }
        let normalizedSecret = secret.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedSecret.isEmpty else {
            throw SecretStoreError.emptySecret
        }
        secrets[identifier] = secret
    }

    public func deleteSecret(identifier: String) throws {
        secrets.removeValue(forKey: identifier)
    }
}
