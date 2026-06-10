//
//  AIMode.swift
//  Canvo
//
//  Created by Олег Комаристый on 14.05.2026.
//


import Foundation
enum AIMode: String, CaseIterable, Identifiable {
    case extend
    case summarize
    case explain

    var id: String { rawValue }

    var title: String {
        switch self {
        case .extend: String(localized: "Expand")
        case .summarize: String(localized: "Summarize")
        case .explain: String(localized: "Explain")
        }
    }

    var subtitle: String {
        switch self {
        case .extend:
            String(localized: "Generate related ideas")
        case .summarize:
            String(localized: "Compress selected content")
        case .explain:
            String(localized: "Explains concepts and key points")
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
            String(localized: "Generate Nodes")
        case .summarize:
            String(localized: "Create Summary")
        case .explain:
            String(localized: "Explain Canvas")
        }
    }

    var loadingTitle: String {
        switch self {
        case .extend:
            String(localized: "Generating Nodes")
        case .summarize:
            String(localized: "Creating Summary")
        case .explain:
            String(localized: "Generating Explanation")
        }
    }

    var promptTitle: String {
        switch self {
        case .extend:
            String(localized: "What should AI add?")
        case .summarize:
            String(localized: "What should AI focus on?")
        case .explain:
            String(localized: "What do you want explained?")
        }
    }

    var placeholder: String {
        switch self {
        case .extend:
            String(localized: "Add onboarding flow and monetization ideas...")
        case .summarize:
            String(localized: "Summarize into concise product requirements...")
        case .explain:
            String(localized: "Explain how these systems interact...")
        }
    }
}
