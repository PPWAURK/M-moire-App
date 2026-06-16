import MeimoireCore
import Testing

@Suite("Secret store")
struct SecretStoreTests {
    @Test("In-memory secret store saves, reads, updates, and deletes")
    func inMemorySecretStoreLifecycle() throws {
        let store = InMemorySecretStore()

        let identifier = try store.saveSecret("first-password", identifier: nil)
        #expect(try store.readSecret(identifier: identifier) == "first-password")

        try store.updateSecret("second-password", identifier: identifier)
        #expect(try store.readSecret(identifier: identifier) == "second-password")

        try store.deleteSecret(identifier: identifier)
        #expect(throws: SecretStoreError.itemNotFound) {
            try store.readSecret(identifier: identifier)
        }
    }

    @Test("In-memory secret store rejects empty values")
    func inMemorySecretStoreRejectsEmptySecret() {
        let store = InMemorySecretStore()
        #expect(throws: SecretStoreError.emptySecret) {
            try store.saveSecret("   ", identifier: nil)
        }
    }
}
