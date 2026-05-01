//
//  Position3DSchema.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 08.01.2026.
//

import Foundation
import FoundationModels

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@Generable
struct Position3DSchema: Codable, Sendable {
//    @Guide(description: "X position of node")
    var x: Float
    
//    @Guide(description: "Y position of node")
    var y: Float
    
//    @Guide(description: "Z position of node")
    var z: Float
}
