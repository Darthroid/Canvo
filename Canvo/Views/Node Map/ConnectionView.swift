//
//  ConnectionView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 18.01.2026.
//

import SwiftUI

struct ConnectionView: Shape {
    let fromCenter: CGPoint
    let fromSize: CGSize

    let toCenter: CGPoint
    let toSize: CGSize

    var arrowLength: CGFloat = 14
    var arrowAngle: CGFloat = .pi / 8

    func path(in rect: CGRect) -> Path {
        let start = connectionPoint(
            center: fromCenter,
            size: fromSize,
            toward: toCenter
        )

        let end = connectionPoint(
            center: toCenter,
            size: toSize,
            toward: fromCenter
        )

        let angle = atan2(end.y - start.y, end.x - start.x)

        let arrowBaseCenter = CGPoint(
            x: end.x - arrowLength * cos(angle),
            y: end.y - arrowLength * sin(angle)
        )

        let arrowWidth = arrowLength * tan(arrowAngle)

        let left = CGPoint(
            x: arrowBaseCenter.x + arrowWidth * sin(angle),
            y: arrowBaseCenter.y - arrowWidth * cos(angle)
        )

        let right = CGPoint(
            x: arrowBaseCenter.x - arrowWidth * sin(angle),
            y: arrowBaseCenter.y + arrowWidth * cos(angle)
        )

        var path = Path()

        // line before arrow
        path.move(to: start)
        path.addLine(to: arrowBaseCenter)

        // arrow
        path.move(to: end)
        path.addLine(to: left)
        path.addLine(to: right)
        path.closeSubpath()

        return path
    }

    private func connectionPoint(
        center: CGPoint,
        size: CGSize,
        toward target: CGPoint
    ) -> CGPoint {
        let dx = target.x - center.x
        let dy = target.y - center.y

        guard dx != 0 || dy != 0 else {
            return center
        }

        let halfWidth = max(size.width / 2, 1)
        let halfHeight = max(size.height / 2, 1)

        let scaleX = halfWidth / abs(dx)
        let scaleY = halfHeight / abs(dy)

        let scale = min(scaleX, scaleY)

        return CGPoint(
            x: center.x + dx * scale,
            y: center.y + dy * scale
        )
    }
}
