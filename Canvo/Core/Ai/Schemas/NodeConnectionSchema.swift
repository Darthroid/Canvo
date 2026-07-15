//
//  NodeConnectionSchema.swift
//  Canvo
//
//  Created by Олег Комаристый on 08.01.2026.
//

import Foundation
import FoundationModels


@available(iOS 26.0, *)
@Generable
struct NodeConnectionSchema: Codable, Sendable, Identifiable {
    @Guide(description: "UUID string")
    let id: String
    
    @Guide(description: "UUID string of starting node")
    let fromNodeId: String
    
    @Guide(description: "UUID string of ending node")
    let toNodeId: String
}
