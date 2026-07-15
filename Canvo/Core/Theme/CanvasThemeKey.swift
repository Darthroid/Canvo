//
//  CanvasThemeKey.swift
//  Canvo
//
//  Created by Олег Комаристый on 16.06.2026.
//


import SwiftUI

private struct CanvasThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme.light.canvasTheme
}

extension EnvironmentValues {
    var canvasTheme: CanvasTheme {
        get { self[CanvasThemeKey.self] }
        set { self[CanvasThemeKey.self] = newValue }
    }
}