//
//  CGSize.swift
//  Canvo
//
//  Created by Олег Комаристый on 18.01.2026.
//

import Foundation

public extension CGSize {
    static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
}
