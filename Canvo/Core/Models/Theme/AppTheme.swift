//
//  AppTheme.swift
//  Canvo
//
//  Created by Олег Комаристый on 16.06.2026.
//


import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case light
    case dark
    case paper
    case graphite
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
        case .graphite:
            return String(localized: "Graphite")
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
        case .light, .paper, .graphite, .forest:
            return .light

        case .dark, .midnight, .blueprint:
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

        case .graphite:
            return .graphite

        case .midnight:
            return .midnight

        case .blueprint:
            return .blueprint

        case .forest:
            return .forest
        }
    }
}
