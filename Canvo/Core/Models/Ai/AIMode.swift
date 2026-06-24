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
        case .extend:
            String(localized: "Generate")
        case .summarize:
            String(localized: "Merge")
        case .explain:
            String(localized: "Analyze")
        }
    }

    var subtitle: String {
        switch self {
        case .extend:
            String(localized: "Add related ideas")
        case .summarize:
            String(localized: "Combine into one concept")
        case .explain:
            String(localized: "Break down structure")
        }
    }

    var icon: String {
        switch self {
        case .extend:
            "sparkles"
        case .summarize:
            "square.stack.3d.down.right"
        case .explain:
            "text.bubble"
        }
    }

    var actionTitle: String {
        switch self {
        case .extend:
            String(localized: "Generate Nodes")
        case .summarize:
            String(localized: "Merge Nodes")
        case .explain:
            String(localized: "Analyze Canvas")
        }
    }

    var loadingTitle: String {
        switch self {
        case .extend:
            String(localized: "Generating nodes")
        case .summarize:
            String(localized: "Merging nodes")
        case .explain:
            String(localized: "Analyzing structure")
        }
    }

    var promptTitle: String {
        switch self {
        case .extend:
            String(localized: "What should be generated?")
        case .summarize:
            String(localized: "What should be merged?")
        case .explain:
            String(localized: "What should be analyzed?")
        }
    }

    var placeholder: String {
        switch self {
        case .extend:
            String(localized: "Add onboarding flow, monetization ideas, edge cases...")
        case .summarize:
            String(localized: "Combine into product requirements or core concept...")
        case .explain:
            String(localized: "Explain relationships between systems, flows, or components...")
        }
    }
}
