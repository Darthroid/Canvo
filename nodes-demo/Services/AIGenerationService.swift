//
//  AIGenerationService.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 08.01.2026.
//

import FoundationModels

@available(iOS 26.0, *)
class AIGenerationService {
    static let shared = AIGenerationService()
    
    private let model = SystemLanguageModel.default
    
    public var isAvailable: Bool {
        return model.isAvailable
    }
    
    private init() {}
    
    func generaeteCanvas(prompt: String) async throws -> CanvasSchema {
        let session = LanguageModelSession(
            model: model,
            instructions: """
            You are an AI that designs a structured 3D idea canvas.

            General rules:
            - All nodes must have unique UUID string identifiers.
            - Node positions are in meters.
            - The canvas is laid out primarily on the X-Y plane (Z should be 0 unless needed).
            - The coordinate origin (0, 0, 0) represents the center of the canvas.

            Main idea node:
            - If possible, create a single main idea node.
            - The main idea node represents the core concept of the canvas.
            - Place the main idea node exactly at position (0, 0, 0).
            - The main idea node should have the most general and descriptive name.
            - The main idea node name should also represent the core concept of canvas.

            Supporting nodes:
            - All other nodes must support, expand, or relate to the main idea.
            - Place supporting nodes around the main idea in a roughly circular or radial layout.
            - Supporting nodes must not overlap in X and Y coordinates.

            Spacing rules:
            - The minimum distance between any two nodes on the X-Y plane must be at least 100 points.
            - Do not place two nodes with the same X and Y coordinates on each other. add 100 points on the X-Y plane to one of nodes so that is would not overlap other node.
            - Use evenly distributed angles when placing nodes around the center.

            Connections:
            - Create logical connections between nodes if needed.
            - Most supporting nodes should be directly connected to the main idea node.
            - Do not create connections to non-existent node IDs.

            Content rules:
            - Node names must be short and meaningful.
            - Node details may briefly explain the idea.
            - Do not duplicate ideas across nodes.
            - Draw at least 10 nodes that represents core concept of the canvas.
            - If possible, canvas should have main idea node.

            Output rules:
            - Return valid JSON strictly matching CanvasSchema.
            - Do not include explanations or comments outside the JSON.
            """
        )

        let result = try await session.respond(
            to: prompt,
            generating: CanvasSchema.self
        )

        return result.content
    }

}
