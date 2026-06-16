import Foundation

public enum DocumentTemplate: String, CaseIterable, Identifiable, Sendable {
    case blank
    case idea
    case meeting
    case tasks

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .blank:
            "Document vierge"
        case .idea:
            "Idée"
        case .meeting:
            "Réunion"
        case .tasks:
            "Liste de tâches"
        }
    }

    public var symbolName: String {
        switch self {
        case .blank:
            "doc"
        case .idea:
            "sparkles"
        case .meeting:
            "person.2"
        case .tasks:
            "checklist"
        }
    }

    public var markdown: String {
        switch self {
        case .blank:
            ""
        case .idea:
            """
            # Nouvelle idée

            ## Contexte

            ## Observation

            ## Prochaine action

            - [ ] 
            """
        case .meeting:
            """
            # Notes de réunion

            ## Participants

            ## Points clés

            - 

            ## Décisions

            - 

            ## Actions

            - [ ] 
            """
        case .tasks:
            """
            # Liste de tâches

            - [ ] Première tâche
            - [ ] 
            """
        }
    }
}
