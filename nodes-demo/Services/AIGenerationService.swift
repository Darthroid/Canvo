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
    
    func generateNodes(prompt: String, in canvas: Canvas) async throws -> ([NodeSchema], [NodeConnectionSchema]) {
        let canvasSchema = canvas.toSchema()
        let session = LanguageModelSession(
            model: model,
            instructions: """
                You are an AI assistant that extends an existing 3D idea canvas by proposing
                additional nodes and connections.

                You are given:
                - A user prompt describing what ideas they want to add or explore.
                - An existing canvas that already contains nodes and connections.

                Your task:
                - Propose NEW nodes and NEW connections that complement the existing canvas.
                - Do NOT recreate, modify, or remove existing nodes or connections.
                
                Existing canvas:
                \(canvasSchema.promptRepresentation)

                --------------------------------
                General rules:
                - All newly created nodes MUST have unique UUID string identifiers.
                - Never reuse or regenerate IDs of existing nodes.
                - Node positions are in meters.
                - The canvas is laid out primarily on the X-Y plane.
                - Z should be 0 unless there is a clear reason to separate nodes in depth.

                --------------------------------
                Working with existing nodes:
                - You may create connections FROM or TO existing nodes using their IDs.
                - Do NOT modify existing node properties (name, position, details, color).
                - Do NOT assume missing nodes — only reference node IDs that exist or that you create.

                --------------------------------
                Placement rules:
                - New nodes must NOT overlap with existing nodes or with each other.
                - The minimum distance between any two nodes on the X-Y plane must be at least 100 points.
                - If a proposed position would overlap an existing node, adjust it by at least 100 points on the X-Y plane.
                - Prefer placing new nodes near related existing nodes.
                - If the canvas has a central or main idea node (usually near 0,0,0), arrange new nodes around it or around their most relevant existing node.

                --------------------------------
                Semantic rules:
                - New nodes should expand, refine, or add perspectives to the existing ideas.
                - Avoid duplicating concepts already present in the canvas.
                - Node names must be short, clear, and meaningful.
                - Node details may briefly explain the idea or how it relates to existing nodes.

                --------------------------------
                Connections:
                - Create new connections only when there is a clear logical relationship.
                - Connections may link:
                  - new node → new node
                  - new node → existing node
                  - existing node → new node
                - Do NOT create connections between two existing nodes.
                - Do NOT create duplicate connections.
                - Do NOT create connections to non-existent node IDs.

                --------------------------------
                Quantity guidelines:
                - Create only as many nodes as necessary to meaningfully address the user's prompt.
                - Prefer quality and relevance over quantity.

                --------------------------------
                Output rules:
                - Return ONLY valid JSON.
                - The output must strictly match the expected schema:
                  - An array of NodeSchema objects
                  - An array of NodeConnectionSchema objects
                - Do NOT include explanations, comments, or extra text outside the JSON.
                - DO NOT include nodes and connections provided by prompt/instructions that already existing in canvas
                """

        )

        let result = try await session.respond(
            to: prompt,
            generating: CanvasSchema.self
        )

        return (result.content.nodes, result.content.connections)

    }

}
