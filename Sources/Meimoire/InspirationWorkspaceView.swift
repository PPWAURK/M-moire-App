import MeimoireCore
import SwiftData
import SwiftUI

struct InspirationWorkspaceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.meimoireSkin) private var skin

    let item: VaultItem
    let onDelete: () -> Void

    @State private var title = ""
    @State private var sourceURL = ""
    @State private var tags = ""
    @State private var draft = ""
    @State private var selectedRange = NSRange(location: 0, length: 0)
    @State private var searchQuery = ""
    @State private var activeSearchIndex = 0
    @State private var focusTrigger = 0
    @State private var scrollTargetLocation: Int?
    @State private var compactMode: CompactDocumentMode = .write
    @State private var saveState: DocumentSaveState = .saved
    @State private var autosaveTask: Task<Void, Never>?

    private var headings: [DocumentHeading] {
        DocumentOutline.headings(in: draft)
    }

    private var stats: DocumentStats {
        DocumentStats(markdown: draft)
    }

    private var searchRanges: [NSRange] {
        ranges(matching: searchQuery, in: draft)
    }

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.width < 980

            VStack(alignment: .leading, spacing: 16) {
                header

                if isCompact {
                    compactSwitcher
                    compactBody
                } else {
                    wideBody
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background(skin.backgroundColor)
        .navigationTitle(title.isEmpty ? "Sans titre" : title)
        .onAppear {
            syncDraft()
            focusTrigger += 1
        }
        .onDisappear {
            autosaveTask?.cancel()
            saveIfNeeded()
        }
        .onChange(of: item.id) { _, _ in
            syncDraft()
            focusTrigger += 1
        }
        .onChange(of: draft) { _, _ in
            markDirtyAndScheduleAutosave()
            activeSearchIndex = 0
        }
        .onChange(of: title) { _, _ in markDirtyAndScheduleAutosave() }
        .onChange(of: sourceURL) { _, _ in markDirtyAndScheduleAutosave() }
        .onChange(of: tags) { _, _ in markDirtyAndScheduleAutosave() }
        .onChange(of: searchQuery) { _, _ in activeSearchIndex = 0 }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            CategoryIconView(item: item, size: 64)

            VStack(alignment: .leading, spacing: 8) {
                TextField("Titre du document", text: $title)
                    .textFieldStyle(.plain)
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(skin.textColor)

                HStack(spacing: 10) {
                    Label("Document d’inspiration", systemImage: "doc.text")
                    Text("Markdown")
                }
                .font(.headline)
                .foregroundStyle(skin.secondaryTextColor)
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    resetDraft()
                } label: {
                    Label("Rétablir", systemImage: "arrow.uturn.backward")
                }
                .disabled(!hasChanges)

                Button {
                    saveIfNeeded(force: true)
                } label: {
                    Label("Enregistrer", systemImage: "checkmark.circle")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!hasChanges && !saveState.isError)

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Supprimer", systemImage: "trash")
                }
            }
        }
    }

    private var compactSwitcher: some View {
        Picker("Affichage", selection: $compactMode) {
            ForEach(CompactDocumentMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 220)
    }

    @ViewBuilder
    private var compactBody: some View {
        switch compactMode {
        case .write:
            editorColumn
        case .preview:
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    previewPanel
                    inspectorPanel
                }
            }
        }
    }

    private var wideBody: some View {
        HStack(alignment: .top, spacing: 16) {
            editorColumn
                .frame(minWidth: 440)

            VStack(spacing: 16) {
                previewPanel
                    .frame(minHeight: 300)
                inspectorPanel
            }
            .frame(width: 330)
        }
    }

    private var editorColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                DocumentToolbar { command in
                    apply(command)
                } onTemplate: { template in
                    insert(template)
                }

                Spacer()

                searchControl
            }

            MarkdownTextEditor(
                text: $draft,
                selectedRange: $selectedRange,
                skin: skin,
                focusTrigger: focusTrigger,
                highlightedRanges: searchRanges,
                scrollTargetLocation: scrollTargetLocation
            )
            .frame(minHeight: 460)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(skin.borderColor, lineWidth: 1)
            }

            DocumentStatsView(
                stats: stats,
                saveStateTitle: saveState.title,
                saveStateSystemImage: saveState.systemImage,
                isError: saveState.isError
            )
        }
        .padding(16)
        .background(skin.panelColor)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(skin.borderColor, lineWidth: 1)
        }
    }

    private var searchControl: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(skin.secondaryTextColor)

            TextField("Rechercher", text: $searchQuery)
                .textFieldStyle(.plain)
                .frame(width: 150)

            if !searchQuery.isEmpty {
                Text(searchRanges.isEmpty ? "0" : "\(activeSearchIndex + 1)/\(searchRanges.count)")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(skin.secondaryTextColor)
                    .frame(minWidth: 34)

                Button {
                    moveSearchResult(by: -1)
                } label: {
                    Image(systemName: "chevron.up")
                }
                .buttonStyle(.borderless)
                .disabled(searchRanges.isEmpty)

                Button {
                    moveSearchResult(by: 1)
                } label: {
                    Image(systemName: "chevron.down")
                }
                .buttonStyle(.borderless)
                .disabled(searchRanges.isEmpty)

                Button {
                    searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(skin.listColor)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(skin.borderColor, lineWidth: 1)
        }
    }

    private var previewPanel: some View {
        WorkspacePanel(title: "Aperçu", systemImage: "doc.richtext") {
            MarkdownPreviewView(markdown: draft)
                .frame(minHeight: 250)
        }
    }

    private var inspectorPanel: some View {
        WorkspacePanel(title: "Inspecteur", systemImage: "sidebar.right") {
            VStack(alignment: .leading, spacing: 18) {
                DocumentOutlineView(headings: headings) { heading in
                    scrollTargetLocation = heading.location
                    selectedRange = NSRange(location: heading.location, length: 0)
                    focusTrigger += 1
                }

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    InspectorField(label: "URL source") {
                        TextField("https://example.com", text: $sourceURL)
                            .textFieldStyle(.roundedBorder)
                    }

                    InspectorField(label: "Étiquettes") {
                        TextField("idée, produit", text: $tags)
                            .textFieldStyle(.roundedBorder)
                    }

                    InspectorLine(label: "Format", value: item.contentFormat.displayName)
                    InspectorLine(label: "Créé", value: item.createdAt.formatted(date: .abbreviated, time: .shortened))
                    InspectorLine(label: "Mis à jour", value: item.updatedAt.formatted(date: .abbreviated, time: .shortened))
                }
            }
        }
    }

    private var hasChanges: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines) != item.title ||
            sourceURL.trimmingCharacters(in: .whitespacesAndNewlines) != item.urlString ||
            draft != item.notes ||
            parsedTags != item.tags
    }

    private var parsedTags: [String] {
        VaultItem.normalizeTags(tags.split(separator: ",").map(String.init))
    }

    private func syncDraft() {
        autosaveTask?.cancel()
        title = item.title
        sourceURL = item.urlString
        tags = item.tags.joined(separator: ", ")
        draft = item.notes
        selectedRange = NSRange(location: 0, length: 0)
        searchQuery = ""
        activeSearchIndex = 0
        saveState = .saved
    }

    private func resetDraft() {
        syncDraft()
        saveState = .saved
        focusTrigger += 1
    }

    private func apply(_ command: MarkdownEditingCommand) {
        let result = command.apply(to: draft, selectedRange: selectedRange)
        draft = result.text
        selectedRange = result.selectedRange
        focusTrigger += 1
    }

    private func insert(_ template: DocumentTemplate) {
        if template == .blank {
            draft = ""
            selectedRange = NSRange(location: 0, length: 0)
        } else if draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            draft = template.markdown
            selectedRange = NSRange(location: draft.utf16.count, length: 0)
        } else {
            let insertion = "\n\n\(template.markdown)"
            let result = MarkdownEditResult(text: draft, selectedRange: selectedRange)
            if let range = draft.range(from: result.selectedRange) {
                var updated = draft
                updated.replaceSubrange(range, with: insertion)
                draft = updated
                selectedRange = NSRange(location: result.selectedRange.location + insertion.utf16.count, length: 0)
            } else {
                draft += insertion
                selectedRange = NSRange(location: draft.utf16.count, length: 0)
            }
        }
        focusTrigger += 1
    }

    private func markDirtyAndScheduleAutosave() {
        guard hasChanges else {
            saveState = .saved
            return
        }
        saveState = .dirty
        autosaveTask?.cancel()
        autosaveTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(900))
            saveIfNeeded()
        }
    }

    private func saveIfNeeded(force: Bool = false) {
        guard force || hasChanges else { return }

        let normalizedURL = URLValidator.normalizedURLString(sourceURL)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalizedURL.isEmpty, !URLValidator.isValidWebURL(normalizedURL) {
            saveState = .error("URL source invalide.")
            return
        }

        saveState = .saving
        item.update(
            type: .inspiration,
            title: trimmedTitle.isEmpty ? "Sans titre" : trimmedTitle,
            username: "",
            urlString: normalizedURL,
            notes: draft,
            tags: parsedTags,
            accountCategory: nil,
            contentFormat: .markdown,
            secretIdentifier: nil
        )

        do {
            try modelContext.save()
            sourceURL = normalizedURL
            saveState = .saved
        } catch {
            saveState = .error(error.localizedDescription)
        }
    }

    private func moveSearchResult(by offset: Int) {
        guard !searchRanges.isEmpty else { return }
        let next = (activeSearchIndex + offset + searchRanges.count) % searchRanges.count
        activeSearchIndex = next
        let range = searchRanges[next]
        selectedRange = range
        scrollTargetLocation = range.location
        focusTrigger += 1
    }

    private func ranges(matching query: String, in text: String) -> [NSRange] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return [] }

        let nsText = text as NSString
        var ranges: [NSRange] = []
        var searchRange = NSRange(location: 0, length: nsText.length)

        while searchRange.length > 0 {
            let found = nsText.range(
                of: needle,
                options: [.caseInsensitive, .diacriticInsensitive],
                range: searchRange
            )
            guard found.location != NSNotFound else { break }
            ranges.append(found)
            let nextLocation = found.location + max(found.length, 1)
            searchRange = NSRange(location: nextLocation, length: nsText.length - nextLocation)
        }

        return ranges
    }
}

private enum CompactDocumentMode: String, CaseIterable, Identifiable {
    case write
    case preview

    var id: String { rawValue }

    var title: String {
        switch self {
        case .write:
            "Écrire"
        case .preview:
            "Aperçu"
        }
    }
}

private enum DocumentSaveState: Equatable {
    case saved
    case dirty
    case saving
    case error(String)

    var title: String {
        switch self {
        case .saved:
            "Enregistré"
        case .dirty:
            "Non enregistré"
        case .saving:
            "Enregistrement..."
        case .error(let message):
            message
        }
    }

    var systemImage: String {
        switch self {
        case .saved:
            "checkmark.circle"
        case .dirty:
            "circle.dotted"
        case .saving:
            "arrow.triangle.2.circlepath"
        case .error:
            "exclamationmark.triangle"
        }
    }

    var isError: Bool {
        if case .error = self { return true }
        return false
    }
}

private struct WorkspacePanel<Content: View>: View {
    @Environment(\.meimoireSkin) private var skin
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(skin.textColor)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(skin.panelColor)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(skin.borderColor, lineWidth: 1)
        }
    }
}

private struct InspectorField<Content: View>: View {
    @Environment(\.meimoireSkin) private var skin
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(skin.secondaryTextColor)
            content
        }
    }
}

private struct InspectorLine: View {
    @Environment(\.meimoireSkin) private var skin
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(skin.secondaryTextColor)
            Text(value)
                .font(.callout)
                .foregroundStyle(skin.textColor)
                .textSelection(.enabled)
        }
    }
}

private extension String {
    func range(from nsRange: NSRange) -> Range<String.Index>? {
        guard let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
              let to16 = utf16.index(from16, offsetBy: nsRange.length, limitedBy: utf16.endIndex),
              let from = String.Index(from16, within: self),
              let to = String.Index(to16, within: self) else {
            return nil
        }
        return from..<to
    }
}
