//
//  NodeSchema.swift
//  Canvo
//
//  Created by Олег Комаристый on 08.01.2026.
//

import Foundation
import FoundationModels

@available(iOS 26.0, *)
@Generable
struct NodeSchema: Codable, Sendable, Identifiable {
//    @Guide(description: "An unique identifier (UUID string) of node")
    var id: String = UUID().uuidString
    
    @Guide(description: "A short and meaningful name of node")
    var name: String
    
    @Guide(description: "A brief 2-3 sentence description of the node. includes short definition and key points")
    var detail: String
    
    /// HEX color (e.g. "#FFAA00")
    @Guide(description: "A color of node (hex string)")
    var color: String?
    
//    @Guide(description: "A position of node in 3D space")
    var position: Position3DSchema
}
