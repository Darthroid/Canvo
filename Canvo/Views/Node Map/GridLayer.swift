//
//  GridLayer.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 18.01.2026.
//

import SwiftUI

struct GridLayer: View {
    private let spacing: CGFloat = 60
    private let dotSize: CGFloat = 2
    
    @Environment(\.canvasTheme) private var theme

    var body: some View {
        GeometryReader { geo in
            Path { p in
                for x in stride(from: -geo.size.width,
                                to: geo.size.width * 2,
                                by: spacing) {
                    for y in stride(from: -geo.size.height,
                                    to: geo.size.height * 2,
                                    by: spacing) {
                        p.addEllipse(
                            in: CGRect(x: x, y: y, width: dotSize, height: dotSize)
                        )
                    }
                }
            }
            .fill(theme.grid)
        }
        .allowsHitTesting(false)
    }
}
