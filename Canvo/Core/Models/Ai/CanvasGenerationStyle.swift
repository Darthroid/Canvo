//
//  CanvasGenerationStyle.swift
//  Canvo
//
//  Created by Олег Комаристый on 24.06.2026.
//


import Foundation
public enum CanvasGenerationStyle: String, CaseIterable, Identifiable {
    case radial
    case tree

    public var id: String { rawValue }

    var title: String {
        switch self {
        case .radial:
            return String(localized: "Radial")
        case .tree:
            return String(localized: "Tree")
        }
    }

    public var subtitle: String {
        switch self {
        case .radial:
            return String(localized: "One idea in the center with connected topics around it")
        case .tree:
            return String(localized: "Hierarchical structure with branches and subtopics")
        }
    }
}
