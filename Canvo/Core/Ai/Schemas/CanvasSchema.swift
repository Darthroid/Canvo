//
//  CanvasSchema.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 08.01.2026.
//

import Foundation
import FoundationModels

@available(iOS 26.0, *)
//@Generable
struct CanvasSchema: Codable, Sendable, Identifiable {
//    @Guide(description: "UUID string")
    let id: String
    
//    @Guide(description: "Name of canvas")
    var name: String
    
//    @Guide(description: "Array of nodes")
    var nodes: [NodeSchema]
    
//    @Guide(description: "Array of connections between nodes")
    var connections: [NodeConnectionSchema]
}
