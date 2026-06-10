//
//  AIScope.swift
//  Canvo
//
//  Created by Олег Комаристый on 14.05.2026.
//


import Foundation
enum AIScope: String, CaseIterable, Identifiable {
    case selection
    case visible
    case canvas

    var id: String { rawValue }

    var title: String {
        switch self {
        case .selection:
            String(localized: "Selection")
        case .visible:
            String(localized:"Visible")
        case .canvas:
            String(localized:"Entire Canvas")
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
