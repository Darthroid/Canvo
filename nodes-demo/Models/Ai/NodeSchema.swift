//
//  NodeSchema.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 08.01.2026.
//

import Foundation
import FoundationModels

@available(iOS 26.0, *)
@Generable
struct NodeSchema: Codable, Sendable, Identifiable {
    @Guide(description: "An unique identifier (UUID string) of node")
    let id: String
    
    @Guide(description: "A name of node")
    var name: String
    
    @Guide(description: "A description of node")
    var detail: String
    
    @Guide(description: "A position of node in 3D space (canvas)")
    var position: Position3DSchema
    
    /// HEX color (e.g. "#FFAA00")
    @Guide(description: "A color of node (hex string)")
    var color: String?
}
