//
//  AIEditCanvasView+Scope.swift
//  Canvo
//
//  Created by Олег Комаристый on 14.05.2026.
//


// MARK: - Mode

enum AIMode: String, CaseIterable, Identifiable {
    case extend
    case summarize
    case explain

    var id: String { rawValue }

    var title: String {
        switch self {
        case .extend: "Expand"
        case .summarize: "Summarize"
        case .explain: "Explain"
        }
    }

    var subtitle: String {
        switch self {
        case .extend:
            "Generate related ideas"
        case .summarize:
            "Compress selected content"
        case .explain:
            "Explain concepts and links"
        }
    }

    var icon: String {
        switch self {
        case .extend:
            "sparkles"
        case .summarize:
            "text.redaction"
        case .explain:
            "text.bubble"
        }
    }

    var actionTitle: String {
        switch self {
        case .extend:
            "Generate Nodes"
        case .summarize:
            "Create Summary"
        case .explain:
            "Explain Canvas"
        }
    }

    var loadingTitle: String {
        switch self {
        case .extend:
            "Generating Nodes"
        case .summarize:
            "Creating Summary"
        case .explain:
            "Generating Explanation"
        }
    }

    var promptTitle: String {
        switch self {
        case .extend:
            "What should AI add?"
        case .summarize:
            "What should AI focus on?"
        case .explain:
            "What do you want explained?"
        }
    }

    var placeholder: String {
        switch self {
        case .extend:
            "Add onboarding flow and monetization ideas..."
        case .summarize:
            "Summarize into concise product requirements..."
        case .explain:
            "Explain how these systems interact..."
        }
    }
}

// MARK: - Scope

enum AIScope: String, CaseIterable, Identifiable {
    case selection
    case visible
    case canvas

    var id: String { rawValue }

    var title: String {
        switch self {
        case .selection:
            "Selection"
        case .visible:
            "Visible"
        case .canvas:
            "Entire Canvas"
        }
    }

    var icon: String {
        switch self {
        case .selection:
            "selection.pin.in.out"
        case .visible:
            "eye"
        case .canvas:
            "square.grid.3x3"
        }
    }
}
