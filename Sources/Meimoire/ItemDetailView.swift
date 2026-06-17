import AppKit
import MeimoireCore
import SwiftUI

struct ItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.meimoireSkin) private var skin
    let item: VaultItem
    let secretStore: SecretStoreProtocol
    let lockService: AppLockService
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var revealedPassword: String?
    @State private var statusMessage: String?

    @ViewBuilder
    var body: some View {
        if item.type == .inspiration {
            InspirationWorkspaceView(item: item, onDelete: onDelete)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    if item.type == .account {
                        passwordSection
                    }

                    metadataSection
                    contentSection
                }
                .padding(28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(skin.backgroundColor)
            .navigationTitle(item.title)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            CategoryIconView(item: item, size: 64)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Text(item.title.isEmpty ? "Sans titre" : item.title)
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(skin.textColor)
                        .lineLimit(2)
                    if item.type == .account {
                        categoryBadge
                    }
                }

                Text(headerSubtitle)
                    .font(.headline)
                    .foregroundStyle(skin.secondaryTextColor)

                if !item.tags.isEmpty {
                    FlowTags(tags: item.tags)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    onEdit()
                } label: {
                    Label("Modifier", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Supprimer", systemImage: "trash")
                }
            }
        }
    }

    private var categoryBadge: some View {
        Label(item.accountCategory.displayName, systemImage: item.accountCategory.symbolName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(skin.color(for: item.accountCategory))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(skin.color(for: item.accountCategory).opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private var passwordSection: some View {
        DetailPanel(title: "Sécurité du compte", systemImage: "lock.shield") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Text(revealedPassword == nil ? "••••••••••••" : revealedPassword ?? "")
                        .font(.system(.title3, design: .monospaced))
                        .textSelection(.disabled)
                    Spacer()
                    Button {
                        Task { await revealPassword() }
                    } label: {
                        Label(revealedPassword == nil ? "Afficher" : "Masquer", systemImage: revealedPassword == nil ? "eye" : "eye.slash")
                    }
                    Button {
                        Task { await copyPassword() }
                    } label: {
                        Label("Copier", systemImage: "doc.on.doc")
                    }
                }
                .padding(14)
                .background(skin.listColor)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(statusMessage ?? "Une authentification locale est requise avant d’afficher ou copier le mot de passe.")
                    .font(.footnote)
                    .foregroundStyle(skin.secondaryTextColor)
            }
        }
    }

    private var metadataSection: some View {
        DetailPanel(title: "Détails", systemImage: "list.bullet.rectangle") {
            VStack(alignment: .leading, spacing: 14) {
                if !item.username.isEmpty {
                    DetailLine(label: "Nom d’utilisateur", value: item.username)
                }

                if !item.urlString.isEmpty {
                    HStack(alignment: .top) {
                        DetailLine(label: "URL", value: item.urlString)
                        Spacer()
                        Button {
                            openURL()
                        } label: {
                            Label("Ouvrir", systemImage: "safari")
                        }
                    }
                }

                DetailLine(label: "Créé", value: item.createdAt.formatted(date: .abbreviated, time: .shortened))
                DetailLine(label: "Mis à jour", value: item.updatedAt.formatted(date: .abbreviated, time: .shortened))
            }
        }
    }

    private var contentSection: some View {
        DetailPanel(title: item.type == .inspiration ? "Contenu de l’inspiration" : "Notes", systemImage: item.type == .inspiration ? "doc.text" : "note.text") {
            VStack(alignment: .leading, spacing: 12) {
                Text(item.notes.isEmpty ? "Aucune note." : item.notes)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(14)
                    .foregroundStyle(skin.textColor)
                    .background(skin.listColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private var headerSubtitle: String {
        switch item.type {
        case .account:
            [item.username, item.displayDomain].filter { !$0.isEmpty }.joined(separator: " · ")
        case .inspiration:
            "Document Markdown d’inspiration"
        case .url:
            item.displayDomain.isEmpty ? "URL" : item.displayDomain
        }
    }

    @MainActor
    private func revealPassword() async {
        if revealedPassword != nil {
            revealedPassword = nil
            return
        }
        guard await ensureUnlocked(), let identifier = item.secretIdentifier else {
            statusMessage = "Aucun mot de passe enregistré."
            return
        }
        do {
            revealedPassword = try secretStore.readSecret(identifier: identifier)
            statusMessage = "Déverrouillé."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    @MainActor
    private func copyPassword() async {
        guard await ensureUnlocked(), let identifier = item.secretIdentifier else {
            statusMessage = "Aucun mot de passe enregistré."
            return
        }
        do {
            let password = try secretStore.readSecret(identifier: identifier)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(password, forType: .string)
            statusMessage = "Mot de passe copié dans le presse-papiers."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    @MainActor
    private func ensureUnlocked() async -> Bool {
        guard lockService.needsUnlock else { return true }
        return await lockService.unlock()
    }

    private func openURL() {
        let normalized = URLValidator.normalizedURLString(item.urlString)
        guard let url = URL(string: normalized) else { return }
        NSWorkspace.shared.open(url)
    }
}

struct DetailPanel<Content: View>: View {
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
        .padding(18)
        .background(skin.panelColor)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(skin.borderColor, lineWidth: 1)
        }
    }
}

struct DetailLine: View {
    @Environment(\.meimoireSkin) private var skin
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(skin.secondaryTextColor)
            Text(value)
                .foregroundStyle(skin.textColor)
                .textSelection(.enabled)
        }
    }
}

struct FlowTags: View {
    @Environment(\.meimoireSkin) private var skin
    let tags: [String]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text("#\(tag)")
                    .font(.caption)
                    .foregroundStyle(skin.textColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(skin.listColor)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
        }
    }
}
