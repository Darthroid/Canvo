//
//  AIScope.swift
//  Canvo
//
//  Created by Олег Комаристый on 14.05.2026.
//


import Foundation


enum AIScope: String, CaseIterable, Identifiable {
    case selection
    case canvas

    var id: String { rawValue }

    var title: String {
        switch self {
        case .selection:
            String(localized: "Selection")
        case .canvas:
            String(localized: "Entire Canvas")
        }
    }

    var icon: String {
        switch self {
        case .selection:
            "selection.pin.in.out"
        case .canvas:
            "square.grid.3x3"
        }
    }
}
