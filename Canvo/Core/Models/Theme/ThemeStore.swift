//
//  ThemeStore.swift
//  Canvo
//
//  Created by Олег Комаристый on 16.06.2026.
//


import SwiftUI
import Combine

@MainActor
final class ThemeStore: ObservableObject {

    @AppStorage("appTheme")
    private var storedTheme = AppTheme.light.rawValue

    @Published var theme: AppTheme = .light {
        didSet {
            storedTheme = theme.rawValue
            applyAppearance()
        }
    }

    init() {
        theme = AppTheme(rawValue: storedTheme) ?? .light
        applyAppearance()
    }

    private func applyAppearance() {
        let color = UIColor(theme.canvasTheme.selection)

        UIButton.appearance().tintColor = color
        UIView.appearance().tintColor = color
        UISwitch.appearance().onTintColor = color
        UILabel.appearance().tintColor = color
        UISegmentedControl.appearance().selectedSegmentTintColor = color
        UINavigationBar.appearance().tintColor = color
        UIToolbar.appearance().tintColor = color
    }
}
