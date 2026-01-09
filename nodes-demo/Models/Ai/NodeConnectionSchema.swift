//
//  NodeConnectionSchema.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 08.01.2026.
//

import Foundation
import FoundationModels

@available(iOS 26.0, *)
@Generable
struct NodeConnectionSchema: Codable, Sendable, Identifiable {
    @Guide(description: "A unique identifier (UUID string) of connection")
    let id: String
    
    @Guide(description: "An identifier of starting node (connection source)")
    let fromNodeId: String
    
    @Guide(description: "An identifier of ending node (connection destination)")
    let toNodeId: String
}
