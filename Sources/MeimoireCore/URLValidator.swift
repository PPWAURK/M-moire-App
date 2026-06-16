import Foundation

public enum URLValidator {
    public static func normalizedURLString(_ rawValue: String) -> String {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        if trimmed.contains("://") {
            return trimmed
        }
        return "https://\(trimmed)"
    }

    public static func isValidWebURL(_ rawValue: String) -> Bool {
        let normalized = normalizedURLString(rawValue)
        guard let components = URLComponents(string: normalized),
              let scheme = components.scheme?.lowercased(),
              let host = components.host,
              !host.isEmpty else {
            return false
        }
        let isWebScheme = scheme == "https" || scheme == "http"
        let hasDomainShape = host.contains(".") || host == "localhost"
        return isWebScheme && hasDomainShape
    }
}
