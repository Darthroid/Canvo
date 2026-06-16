//
//  LibraryViewStyle.swift
//  Canvo
//
//  Created by Олег Комаристый on 16.06.2026.
//


import Foundation

enum LibraryViewStyle: String, CaseIterable, Identifiable {
    case grid
    case list

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .grid:
            return String(localized: "Grid")
        case .list:
            return String(localized: "List")
        }
    }
}
