//
//  GridLayer.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 18.01.2026.
//

import SwiftUI

struct GridLayer: View {
    let offset: CGSize
    let scale: CGFloat

    private let spacing: CGFloat = 60
    private let dotSize: CGFloat = 2

    @Environment(\.canvasTheme) private var theme

    var body: some View {
        GeometryReader { geo in
            Path { path in

                let step = spacing * scale

                // важно: учитываем anchor .topLeading
                let offsetX = offset.width.truncatingRemainder(dividingBy: step)
                let offsetY = offset.height.truncatingRemainder(dividingBy: step)

                let width = geo.size.width
                let height = geo.size.height

                var x = -step + offsetX
                while x < width + step {
                    var y = -step + offsetY
                    while y < height + step {
                        path.addEllipse(in: CGRect(
                            x: x,
                            y: y,
                            width: dotSize,
                            height: dotSize
                        ))
                        y += step
                    }
                    x += step
                }
            }
            .fill(theme.grid)
        }
        .allowsHitTesting(false)
    }
}
