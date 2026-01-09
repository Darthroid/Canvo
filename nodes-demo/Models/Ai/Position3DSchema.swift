//
//  Position3DSchema.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 08.01.2026.
//

import Foundation
import FoundationModels

@available(iOS 26.0, *)
@Generable
struct Position3DSchema: Codable, Sendable {
    var x: Float
    var y: Float
    var z: Float
}
