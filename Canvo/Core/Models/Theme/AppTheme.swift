//
//  AppTheme.swift
//  Canvo
//
//  Created by Олег Комаристый on 16.06.2026.
//


import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable, Hashable {
    case light
    case dark
    case paper
    case ocean
    case nord
    case retrowave
    case midnight
    case blueprint
    case forest

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light:
            return String(localized: "Light")
        case .dark:
            return String(localized: "Dark")
        case .paper:
            return String(localized: "Paper")
        case .ocean:
            return String(localized: "Ocean")
        case .nord:
            return String(localized: "Nord")
        case .retrowave:
            return String(localized: "Retrowave")
        case .midnight:
            return String(localized: "Midnight")
        case .blueprint:
            return String(localized: "Blueprint")
        case .forest:
            return String(localized: "Forest")
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .light, .paper, .ocean, .forest:
            return .light

        case .dark, .nord, .retrowave, .midnight, .blueprint:
            return .dark
        }
    }

    var canvasTheme: CanvasTheme {
        switch self {
        case .light:
            return .systemLight

        case .dark:
            return .systemDark

        case .paper:
            return .paper

        case .ocean:
            return .ocean

        case .nord:
            return .nord

        case .retrowave:
            return .retrowave

        case .midnight:
            return .midnight

        case .blueprint:
            return .blueprint

        case .forest:
            return .forest
        }
    }
}
