import Foundation
import Security

public enum SecretStoreError: LocalizedError, Equatable {
    case emptySecret
    case itemNotFound
    case unexpectedData
    case keychainStatus(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .emptySecret:
            "Le mot de passe ne peut pas être vide."
        case .itemNotFound:
            "Aucun mot de passe correspondant n’a été trouvé."
        case .unexpectedData:
            "Le trousseau a renvoyé des données illisibles."
        case .keychainStatus(let status):
            "L’opération du trousseau a échoué : \(status)."
        }
    }
}

public protocol SecretStoreProtocol {
    func saveSecret(_ secret: String, identifier: String?) throws -> String
    func readSecret(identifier: String) throws -> String
    func updateSecret(_ secret: String, identifier: String) throws
    func deleteSecret(identifier: String) throws
}

public final class SecretStore: SecretStoreProtocol {
    private let service: String
    private let synchronizable: Bool

    public init(service: String = "com.meimoire.vault", synchronizable: Bool = true) {
        self.service = service
        self.synchronizable = synchronizable
    }

    public func saveSecret(_ secret: String, identifier: String? = nil) throws -> String {
        let normalizedSecret = secret.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedSecret.isEmpty else {
            throw SecretStoreError.emptySecret
        }

        let identifier = identifier ?? UUID().uuidString
        let data = Data(secret.utf8)

        var query = baseQuery(identifier: identifier, includeSynchronizableAny: false)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        SecItemDelete(baseQuery(identifier: identifier, includeSynchronizableAny: true) as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            return identifier
        }

        guard synchronizable else {
            throw SecretStoreError.keychainStatus(status)
        }

        var localQuery = baseQuery(identifier: identifier, forceLocal: true, includeSynchronizableAny: false)
        localQuery[kSecValueData as String] = data
        localQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemDelete(baseQuery(identifier: identifier, forceLocal: true, includeSynchronizableAny: false) as CFDictionary)
        let fallbackStatus = SecItemAdd(localQuery as CFDictionary, nil)
        guard fallbackStatus == errSecSuccess else {
            throw SecretStoreError.keychainStatus(fallbackStatus)
        }
        return identifier
    }

    public func readSecret(identifier: String) throws -> String {
        var query = baseQuery(identifier: identifier, includeSynchronizableAny: true)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status != errSecItemNotFound else {
            throw SecretStoreError.itemNotFound
        }
        guard status == errSecSuccess else {
            throw SecretStoreError.keychainStatus(status)
        }
        guard let data = result as? Data, let secret = String(data: data, encoding: .utf8) else {
            throw SecretStoreError.unexpectedData
        }
        return secret
    }

    public func updateSecret(_ secret: String, identifier: String) throws {
        _ = try saveSecret(secret, identifier: identifier)
    }

    public func deleteSecret(identifier: String) throws {
        let query = baseQuery(identifier: identifier, includeSynchronizableAny: true)
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecretStoreError.keychainStatus(status)
        }
    }

    private func baseQuery(
        identifier: String,
        forceLocal: Bool = false,
        includeSynchronizableAny: Bool
    ) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: identifier
        ]

        if includeSynchronizableAny {
            query[kSecAttrSynchronizable as String] = kSecAttrSynchronizableAny
        } else if synchronizable, !forceLocal {
            query[kSecAttrSynchronizable as String] = kCFBooleanTrue
        }

        return query
    }
}
