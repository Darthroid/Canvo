//
//  ConnectionView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 18.01.2026.
//

import SwiftUI

struct ConnectionView: Shape {
    let from: CGPoint
    let to: CGPoint

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: from)
        p.addLine(to: to)
        return p
    }
}
