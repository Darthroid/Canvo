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

    static let graphite = CanvasTheme(
        background: Color(hex: "#F2F3F5")!,
        nodeBackground: .white,
        nodeBorder: Color(hex: "#D5D9E0")!,
        connector: Color(hex: "#B8BEC8")!,
        selection: Color(hex: "#5B6472")!,
        grid: Color(hex: "#B8BEC8")!.opacity(0.6)
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
        background: Color(hex: "#0E2A47")!,
        nodeBackground: Color(hex: "#163A60")!,
        nodeBorder: Color(hex: "#3D6A94")!,
        connector: Color(hex: "#5F8CB6")!,
        selection: Color(hex: "#9ED0FF")!,
        grid: Color(hex: "#7FA9D1")!.opacity(0.6)
    )

    static let forest = CanvasTheme(
        background: Color(hex: "#EAF4E6")!,
        nodeBackground: Color(hex: "#FFFFFF")!,
        nodeBorder: Color(hex: "#AFC8AA")!,
        connector: Color(hex: "#7FAF82")!,
        selection: Color(hex: "#2F6B3F")!,
        grid: Color(hex: "#6E9E75")!.opacity(0.55)
    )
}
