//
//  CanvasSchema.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 08.01.2026.
//

import Foundation
import FoundationModels

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@Generable
struct CanvasSchema: Codable, Sendable, Identifiable {
    @Guide(description: "A unique identifier (UUID string) of canvas")
    let id: String
    
    @Guide(description: "A name of canvas")
    var name: String
    
    @Guide(description: "A boolean value indicated whether the canvas is pinned (leave it false)")
    var isPinned: Bool
    
    @Guide(description: "An array of nodes in canvas. should have main idea node")
    var nodes: [NodeSchema]
    
    @Guide(description: "An array of connections between nodes in canvas")
    var connections: [NodeConnectionSchema]
}
