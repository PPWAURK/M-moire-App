import MeimoireCore
import SwiftData
import SwiftUI

struct ItemEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.meimoireSkin) private var skin

    let item: VaultItem?
    let defaultType: VaultItemType
    let defaultAccountCategory: AccountCategory?
    let secretStore: SecretStoreProtocol

    @State private var type: VaultItemType
    @State private var title: String
    @State private var username: String
    @State private var urlString: String
    @State private var notes: String
    @State private var tags: String
    @State private var password: String
    @State private var accountCategory: AccountCategory
    @State private var markdownSelection = NSRange(location: 0, length: 0)
    @State private var errorMessage: String?

    init(
        item: VaultItem?,
        defaultType: VaultItemType,
        defaultAccountCategory: AccountCategory? = nil,
        secretStore: SecretStoreProtocol
    ) {
        self.item = item
        self.defaultType = defaultType
        self.defaultAccountCategory = defaultAccountCategory
        self.secretStore = secretStore
        _type = State(initialValue: item?.type ?? defaultType)
        _title = State(initialValue: item?.title ?? "")
        _username = State(initialValue: item?.username ?? "")
        _urlString = State(initialValue: item?.urlString ?? "")
        _notes = State(initialValue: item?.notes ?? "")
        _tags = State(initialValue: item?.tags.joined(separator: ", ") ?? "")
        _password = State(initialValue: "")
        _accountCategory = State(initialValue: item?.accountCategory ?? defaultAccountCategory ?? .other)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    basicSection

                    if type == .account {
                        accountSection
                    }

                    contentSection

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(skin.dangerColor)
                    }
                }
                .padding(22)
            }
            Divider()
            footer
        }
        .background(skin.backgroundColor)
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item == nil ? "Nouvel élément" : "Modifier l’élément")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(skin.textColor)
                Text(type == .inspiration ? "Les inspirations prennent en charge l’édition Markdown" : "Les mots de passe sensibles sont enregistrés uniquement dans le trousseau")
                    .font(.caption)
                    .foregroundStyle(skin.secondaryTextColor)
            }
            Spacer()
            Picker("Type", selection: $type) {
                ForEach([VaultItemType.account, VaultItemType.url]) { type in
                    Label(type.displayName, systemImage: type.systemImage).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 290)
        }
        .padding(22)
        .background(skin.panelColor)
    }

    private var basicSection: some View {
        EditorSection(title: "Informations de base", systemImage: "info.circle") {
            VStack(alignment: .leading, spacing: 12) {
                TextField(type == .account ? "Nom du service" : "Titre", text: $title)
                    .textFieldStyle(.roundedBorder)

                TextField(type == .inspiration ? "URL source (facultative)" : "URL", text: $urlString)
                    .textFieldStyle(.roundedBorder)

                TextField("Étiquettes, séparées par des virgules", text: $tags)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var accountSection: some View {
        EditorSection(title: "Sécurité du compte", systemImage: "person.badge.key") {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Nom d’utilisateur / e-mail", text: $username)
                    .textFieldStyle(.roundedBorder)
                SecureField(item?.secretIdentifier == nil ? "Mot de passe" : "Nouveau mot de passe (laisser vide pour ne pas modifier)", text: $password)
                    .textFieldStyle(.roundedBorder)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Icône de catégorie")
                        .font(.subheadline.weight(.medium))
                    AccountCategoryPicker(selection: $accountCategory)
                }
            }
        }
    }

    private var contentSection: some View {
        EditorSection(title: type == .inspiration ? "Contenu du document" : "Notes", systemImage: type == .inspiration ? "doc.text" : "note.text") {
            VStack(alignment: .leading, spacing: 10) {
                if type == .inspiration {
                    MarkdownToolbar { command in
                        let result = command.apply(to: notes, selectedRange: markdownSelection)
                        notes = result.text
                        markdownSelection = result.selectedRange
                    }
                    MarkdownTextEditor(text: $notes, selectedRange: $markdownSelection, skin: skin)
                        .frame(minHeight: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(skin.borderColor, lineWidth: 1)
                        }
                } else {
                    TextEditor(text: $notes)
                        .frame(minHeight: 160)
                        .padding(8)
                        .foregroundStyle(skin.textColor)
                        .background(skin.markdownBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(skin.borderColor, lineWidth: 1)
                        }
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Button("Annuler") {
                dismiss()
            }
            Spacer()
            Button("Enregistrer") {
                save()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canSave)
        }
        .padding(18)
        .background(skin.panelColor)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        errorMessage = nil

        let normalizedURL = URLValidator.normalizedURLString(urlString)
        if !normalizedURL.isEmpty, !URLValidator.isValidWebURL(normalizedURL) {
            errorMessage = "Veuillez saisir une URL http ou https valide."
            return
        }

        do {
            var secretIdentifier = item?.secretIdentifier
            if type == .account, !password.isEmpty {
                if let existing = secretIdentifier {
                    try secretStore.updateSecret(password, identifier: existing)
                } else {
                    secretIdentifier = try secretStore.saveSecret(password, identifier: nil)
                }
            }

            if let item {
                if item.type == .account, type != .account, let existing = secretIdentifier {
                    try? secretStore.deleteSecret(identifier: existing)
                    secretIdentifier = nil
                }
                item.update(
                    type: type,
                    title: title,
                    username: type == .account ? username : "",
                    urlString: normalizedURL,
                    notes: notes,
                    tags: parsedTags,
                    accountCategory: type == .account ? accountCategory : .other,
                    contentFormat: type == .inspiration ? .markdown : .plainText,
                    secretIdentifier: type == .account ? secretIdentifier : nil
                )
            } else {
                let newItem = VaultItem(
                    type: type,
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    username: type == .account ? username.trimmingCharacters(in: .whitespacesAndNewlines) : "",
                    urlString: normalizedURL,
                    notes: notes,
                    tags: parsedTags,
                    accountCategory: type == .account ? accountCategory : .other,
                    contentFormat: type == .inspiration ? .markdown : .plainText,
                    secretIdentifier: type == .account ? secretIdentifier : nil
                )
                modelContext.insert(newItem)
            }

            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var parsedTags: [String] {
        VaultItem.normalizeTags(tags.split(separator: ",").map(String.init))
    }
}

private struct EditorSection<Content: View>: View {
    @Environment(\.meimoireSkin) private var skin
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(skin.textColor)
            content
        }
        .padding(16)
        .background(skin.panelColor)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(skin.borderColor, lineWidth: 1)
        }
    }
}
