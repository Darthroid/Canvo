//
//  ThemeStore.swift
//  Canvo
//
//  Created by Олег Комаристый on 16.06.2026.
//


import SwiftUI
import Combine

final class ThemeStore: ObservableObject {

    @AppStorage("appTheme")
    private var storedTheme = AppTheme.light.rawValue

    @Published var theme: AppTheme = .light {
        didSet {
            storedTheme = theme.rawValue
        }
    }

    init() {
        theme = AppTheme(rawValue: storedTheme) ?? .light
    }
}
