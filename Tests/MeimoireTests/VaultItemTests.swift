import Foundation
import MeimoireCore
import SwiftData
import Testing

@Suite("Vault items")
struct VaultItemTests {
    @Test("SwiftData stores metadata for all item types")
    func swiftDataCRUD() throws {
        let container = try ModelContainer(
            for: VaultItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let account = VaultItem(type: .account, title: "GitHub", username: "me@example.com", tags: ["dev", "Dev"], accountCategory: .development)
        let idea = VaultItem(type: .inspiration, title: "Inspiration produit", notes: "Capture rapide", tags: ["idea"])
        let link = VaultItem(type: .url, title: "Apple", urlString: "https://developer.apple.com", tags: ["docs"])

        context.insert(account)
        context.insert(idea)
        context.insert(link)
        try context.save()

        let descriptor = FetchDescriptor<VaultItem>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 3)
        #expect(account.tags == ["dev"])
        #expect(account.accountCategory == .development)
        #expect(idea.contentFormat == .markdown)
        #expect(results.contains { $0.type == .account && $0.username == "me@example.com" })
    }

    @Test("Search filters by type, query, tag, and account category")
    func searchMatchesExpectedFields() {
        let account = VaultItem(type: .account, title: "GitHub", username: "octo", urlString: "github.com", tags: ["work"], accountCategory: .development)
        let idea = VaultItem(type: .inspiration, title: "Inspiration menu", notes: "Idée de nouveauté", tags: ["idea"])

        #expect(SearchState(query: "octo").matches(account))
        #expect(SearchState(query: "Développement").matches(account))
        #expect(SearchState(selectedType: .account).matches(account))
        #expect(!SearchState(selectedType: .url).matches(account))
        #expect(SearchState(selectedAccountCategory: .development).matches(account))
        #expect(!SearchState(selectedAccountCategory: .banking).matches(account))
        #expect(SearchState(tag: "idea").matches(idea))
        #expect(!SearchState(tag: "work").matches(idea))
    }

    @Test("Account category and content format fall back safely for old data")
    func modelFallbacks() {
        let account = VaultItem(type: .account, title: "Legacy")
        account.accountCategoryRawValue = nil
        account.contentFormatRawValue = nil

        #expect(account.accountCategory == .other)
        #expect(account.contentFormat == .plainText)
        #expect(AccountCategory.banking.displayName == "Banque")
        #expect(!AccountCategory.banking.symbolName.isEmpty)
    }

    @Test("Account update preserves category when category is omitted")
    func accountUpdatePreservesCategoryWhenOmitted() {
        let account = VaultItem(type: .account, title: "Bank", username: "old", accountCategory: .banking)

        account.update(
            type: .account,
            title: "Bank Updated",
            username: "new",
            urlString: "https://bank.example.com",
            notes: "updated",
            tags: ["money"],
            secretIdentifier: "secret-id"
        )

        #expect(account.accountCategory == .banking)
        #expect(account.accountCategoryRawValue == AccountCategory.banking.rawValue)
    }

    @Test("Markdown editing commands wrap and insert text")
    func markdownEditingCommands() {
        let heading = MarkdownEditingCommand.heading2.apply(to: "Plan", selectedRange: NSRange(location: 0, length: 4))
        #expect(heading.text == "## Plan")
        #expect(heading.selectedRange == NSRange(location: 3, length: 4))

        let paragraph = MarkdownEditingCommand.paragraph.apply(to: "### Ancien titre", selectedRange: NSRange(location: 0, length: 16))
        #expect(paragraph.text == "Ancien titre")

        let bold = MarkdownEditingCommand.bold.apply(to: "hello", selectedRange: NSRange(location: 0, length: 5))
        #expect(bold.text == "**hello**")
        #expect(bold.selectedRange == NSRange(location: 2, length: 5))

        let inlineCode = MarkdownEditingCommand.inlineCode.apply(to: "", selectedRange: NSRange(location: 0, length: 0))
        #expect(inlineCode.text == "`code`")

        let link = MarkdownEditingCommand.link.apply(to: "", selectedRange: NSRange(location: 0, length: 0))
        #expect(link.text == "[texte du lien](https://example.com)")
        #expect(link.selectedRange == NSRange(location: 1, length: 13))

        let task = MarkdownEditingCommand.taskList.apply(to: "acheter du lait", selectedRange: NSRange(location: 0, length: 14))
        #expect(task.text == "- [ ] acheter du lait")

        let rule = MarkdownEditingCommand.horizontalRule.apply(to: "a", selectedRange: NSRange(location: 1, length: 0))
        #expect(rule.text == "a\n---\n")
    }

    @Test("Document outline extracts headings")
    func documentOutline() {
        let markdown = """
        # Titre
        Intro
        ## Partie A
        #### Ignoré
        ### Détail
        """

        let headings = DocumentOutline.headings(in: markdown)
        #expect(headings.map(\.level) == [1, 2, 3])
        #expect(headings.map(\.title) == ["Titre", "Partie A", "Détail"])
        #expect(headings.map(\.lineNumber) == [1, 3, 5])
        #expect(headings[1].location > headings[0].location)
    }

    @Test("Document stats count words and reading time")
    func documentStats() {
        let empty = DocumentStats(markdown: "  \n")
        #expect(empty.wordCount == 0)
        #expect(empty.characterCount == 0)
        #expect(empty.readingMinutes == 0)

        let stats = DocumentStats(markdown: "Bonjour monde, ceci est un test.")
        #expect(stats.wordCount == 6)
        #expect(stats.characterCount == 32)
        #expect(stats.readingMinutes == 1)
    }

    @Test("Markdown preview formatter preserves typed line breaks")
    func markdownPreviewFormatter() {
        let formatted = MarkdownPreviewFormatter.preservingSoftLineBreaks("ligne 1\nligne 2\n\nligne 4")
        #expect(formatted == "ligne 1  \nligne 2  \n\nligne 4  ")

        let code = MarkdownPreviewFormatter.preservingSoftLineBreaks("```\na\nb\n```\nfin")
        #expect(code == "```\na\nb\n```\nfin  ")
    }

    @Test("Markdown list continuation handles return key")
    func markdownListContinuation() {
        let bullet = MarkdownListContinuation.applyNewline(
            to: "- Compte",
            selectedRange: NSRange(location: 8, length: 0)
        )
        #expect(bullet?.text == "- Compte\n- ")
        #expect(bullet?.selectedRange == NSRange(location: 11, length: 0))

        let numbered = MarkdownListContinuation.applyNewline(
            to: "1. Compte",
            selectedRange: NSRange(location: 9, length: 0)
        )
        #expect(numbered?.text == "1. Compte\n2. ")

        let task = MarkdownListContinuation.applyNewline(
            to: "- [ ] Acheter",
            selectedRange: NSRange(location: 13, length: 0)
        )
        #expect(task?.text == "- [ ] Acheter\n- [ ] ")

        let exit = MarkdownListContinuation.applyNewline(
            to: "- Compte\n- ",
            selectedRange: NSRange(location: 11, length: 0)
        )
        #expect(exit?.text == "- Compte\n")
        #expect(exit?.selectedRange == NSRange(location: 9, length: 0))

        let indented = MarkdownListContinuation.indentListLine(
            in: "- Parent",
            selectedRange: NSRange(location: 8, length: 0)
        )
        #expect(indented?.text == "    - Parent")
        #expect(indented?.selectedRange == NSRange(location: 12, length: 0))

        let nested = MarkdownListContinuation.applyNewline(
            to: "    - Child",
            selectedRange: NSRange(location: 11, length: 0)
        )
        #expect(nested?.text == "    - Child\n    - ")

        let outdented = MarkdownListContinuation.outdentListLine(
            in: "    - Child",
            selectedRange: NSRange(location: 11, length: 0)
        )
        #expect(outdented?.text == "- Child")
        #expect(outdented?.selectedRange == NSRange(location: 7, length: 0))
    }

    @Test("URL validator normalizes bare domains")
    func urlValidator() {
        #expect(URLValidator.normalizedURLString("example.com") == "https://example.com")
        #expect(URLValidator.isValidWebURL("https://example.com/path"))
        #expect(URLValidator.isValidWebURL("example.com"))
        #expect(!URLValidator.isValidWebURL("notaurl"))
        #expect(!URLValidator.isValidWebURL("ftp://example.com"))
    }
}
