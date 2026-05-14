//
//  AIMode.swift
//  Canvo
//
//  Created by Олег Комаристый on 14.05.2026.
//


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
            "Explains concepts and key points"
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
