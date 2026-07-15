//
//  Untitled.swift
//  Canvo
//
//  Created by Олег Комаристый on 18.11.2025.
//

import Foundation

extension SIMD3 where Scalar == Float {
    /// The variable to lock the y-axis value to 0.
    var grounded: SIMD3<Scalar> {
        return .init(x: x, y: 0, z: z)
    }
    
    var position2D: CGPoint {
        CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
}
