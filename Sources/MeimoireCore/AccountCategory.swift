import Foundation

public enum AccountCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case work
    case social
    case email
    case banking
    case shopping
    case development
    case cloud
    case subscription
    case gaming
    case other

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .work:
            "Travail"
        case .social:
            "Social"
        case .email:
            "E-mail"
        case .banking:
            "Banque"
        case .shopping:
            "Achats"
        case .development:
            "Développement"
        case .cloud:
            "Cloud"
        case .subscription:
            "Abonnements"
        case .gaming:
            "Jeux"
        case .other:
            "Autres"
        }
    }

    public var symbolName: String {
        switch self {
        case .work:
            "briefcase.fill"
        case .social:
            "person.2.fill"
        case .email:
            "envelope.fill"
        case .banking:
            "building.columns.fill"
        case .shopping:
            "cart.fill"
        case .development:
            "chevron.left.forwardslash.chevron.right"
        case .cloud:
            "icloud.fill"
        case .subscription:
            "repeat.circle.fill"
        case .gaming:
            "gamecontroller.fill"
        case .other:
            "square.grid.2x2.fill"
        }
    }
}
