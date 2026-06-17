//
//  CanvasTheme.swift
//  Canvo
//
//  Created by Олег Комаристый on 16.06.2026.
//

import SwiftUI
import Foundation

struct CanvasTheme: Equatable {
    let background: Color
    let nodeBackground: Color
    let nodeBorder: Color
    let connector: Color
    let selection: Color
    let grid: Color
}

extension CanvasTheme {
    static let systemLight = CanvasTheme(
        background: Color(uiColor: .systemBackground),
        nodeBackground: .white,
        nodeBorder: Color(uiColor: .opaqueSeparator),
        connector: Color(uiColor: .tertiaryLabel),
        selection: .accentColor,
        grid: Color.gray.opacity(0.25)
    )

    static let systemDark = CanvasTheme(
        background: Color(uiColor: .systemBackground),
        nodeBackground: Color(uiColor: .darkGray),
        nodeBorder: Color(uiColor: .opaqueSeparator),
        connector: Color(uiColor: .tertiaryLabel),
        selection: .accentColor,
        grid: Color.white.opacity(0.3)
    )

    static let paper = CanvasTheme(
        background: Color(hex: "#FBF7EF")!,
        nodeBackground: Color(hex: "#F6EFE4")!,
        nodeBorder: Color(hex: "#CDBA9F")!,
        connector: Color(hex: "#BFAE98")!,
        selection: Color(hex: "#B8742A")!,
        grid: Color(hex: "#CBBBA3")!.opacity(0.55)
    )

    static let ocean = CanvasTheme(
        background: Color(hex: "#EDF6FA")!,
        nodeBackground: .white,
        nodeBorder: Color(hex: "#B8D5E3")!,
        connector: Color(hex: "#7DB8D8")!,
        selection: Color(hex: "#0077B6")!,
        grid: Color(hex: "#8CC5E3")!.opacity(0.45)
    )

    static let nord = CanvasTheme(
        background: Color(hex: "#2E3440")!,
        nodeBackground: Color(hex: "#3B4252")!,
        nodeBorder: Color(hex: "#4C566A")!,
        connector: Color(hex: "#81A1C1")!,
        selection: Color(hex: "#88C0D0")!,
        grid: Color(hex: "#5E81AC")!.opacity(0.4)
    )

    static let retrowave = CanvasTheme(
        background: Color(hex: "#1C1833")!,
        nodeBackground: Color(hex: "#2A2348")!,
        nodeBorder: Color(hex: "#C86BFF")!,
        connector: Color(hex: "#7D8CFF")!,
        selection: Color(hex: "#4DEAFF")!,
        grid: Color(hex: "#B05CFF")!.opacity(0.3)
    )

    static let midnight = CanvasTheme(
        background: Color(hex: "#081018")!,
        nodeBackground: Color(hex: "#111B26")!,
        nodeBorder: Color(hex: "#223040")!,
        connector: Color(hex: "#2D4054")!,
        selection: Color(hex: "#4DA3FF")!,
        grid: Color(hex: "#35506A")!.opacity(0.6)
    )

    static let blueprint = CanvasTheme(
        background: Color(hex: "#0B3C5D")!,
        nodeBackground: Color(hex: "#114D76")!,
        nodeBorder: Color(hex: "#3E78A3")!,
        connector: Color(hex: "#82CFFF")!,
        selection: Color(hex: "#00BFFF")!,
        grid: Color(hex: "#6DB7E8")!.opacity(0.45)
    )

    static let forest = CanvasTheme(
        background: Color(hex: "#EAF4E6")!,
        nodeBackground: .white,
        nodeBorder: Color(hex: "#AFC8AA")!,
        connector: Color(hex: "#7FAF82")!,
        selection: Color(hex: "#2F6B3F")!,
        grid: Color(hex: "#6E9E75")!.opacity(0.55)
    )
}
