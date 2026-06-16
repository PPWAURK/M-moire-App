import Foundation

public struct DocumentHeading: Equatable, Identifiable, Sendable {
    public var id: String { "\(lineNumber)-\(location)-\(title)" }
    public let level: Int
    public let title: String
    public let lineNumber: Int
    public let location: Int

    public init(level: Int, title: String, lineNumber: Int, location: Int) {
        self.level = level
        self.title = title
        self.lineNumber = lineNumber
        self.location = location
    }
}

public enum DocumentOutline {
    public static func headings(in markdown: String) -> [DocumentHeading] {
        var headings: [DocumentHeading] = []
        var currentLocation = 0
        let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false)

        for (index, lineSubstring) in lines.enumerated() {
            let line = String(lineSubstring)
            if let heading = heading(from: line, lineNumber: index + 1, location: currentLocation) {
                headings.append(heading)
            }
            currentLocation += line.utf16.count + 1
        }

        return headings
    }

    private static func heading(from line: String, lineNumber: Int, location: Int) -> DocumentHeading? {
        guard line.hasPrefix("#") else { return nil }

        let hashCount = line.prefix { $0 == "#" }.count
        guard (1...3).contains(hashCount) else { return nil }

        let marker = String(repeating: "#", count: hashCount) + " "
        guard line.hasPrefix(marker) else { return nil }

        let title = String(line.dropFirst(marker.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }

        return DocumentHeading(level: hashCount, title: title, lineNumber: lineNumber, location: location)
    }
}
