//
//  AIGenerationService.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 08.01.2026.
//

import FoundationModels

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
class AIGenerationService {
    static let shared = AIGenerationService()
    
    private let model = SystemLanguageModel.default
    
    public var isAvailable: Bool {
        return model.isAvailable
    }
    
    private init() {}
    
    func generaeteCanvas(prompt: String) async throws -> CanvasSchema {
        let session = LanguageModelSession(model: model)

        let result = try await session.respond(
            to: """
            You are an AI that designs a structured mind map.
            Before you start, please check what is a mind map.
            
            Create a mind map following all the rules. 
            Here are ideas for mind map: \(prompt). 
            A summary of idea is also title for canvas.
            
            You must follow these rules:
             
            GENERAL RULES:
            - mind map should have main idea node.
            - mind map should have other nodes that relates to main idea.
            - All other nodes must connect to main idea node and not connect to each other.

            MAIN IDEA NODE:
            - Create a single node that represents the core concept of the mind map.
            - Place the main idea node exactly at position x:0, y: 0, z:0.

            OTHER NODES:
            - All other nodes must support, expand, or relate to the main idea node.
            - place other nodes in graph tree-like shape, where main node is the root

            CONNECTIONS:
            - Nodes should be directly connected to the main idea node.

            CONTENT RULES:
            - Do not duplicate ideas.
            - Generate 10 nodes that represents core concept of the mind map.
            - Supporting nodes must not overlap in X and Y coordinates and must be spaced by 150 points.
            """,
            generating: CanvasSchema.self
        )

        return result.content
    }

}

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
extension AIGenerationService {

    func generateForChunk(
        prompt: String,
        summary: String,
        chunk: CanvasChunk,
        existingIDs: Set<String>
    ) async throws -> CanvasSchema {

        let session = LanguageModelSession(
            model: model,
            instructions: """
            You are extending a mind map by adding NEW ideas only.
            Before start, please check what is a mind map.

            \(summary)

            Active canvas chunk:
            Nodes:
            \(chunk.nodes.map { "- \($0.id): \($0.name)" }.joined(separator: "\n"))

            Connections:
            \(chunk.connections.map { "- \($0.fromNodeId) -> \($0.toNodeId)" }.joined(separator: "\n"))

            Forbidden node IDs:
            \(existingIDs.joined(separator: ", "))

            Rules:
            - Generate ONLY new nodes and connections
            - Connections with existing and new nodes are allowed if there is a logical relationship
            - Place nodes near related ones
            - The distance between any two nodes on the X-Y plane must be at least 150 points.
            """
        )

        let result = try await session.respond(
            to: prompt,
            generating: CanvasSchema.self
        )

        return result.content
    }
}

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
extension AIGenerationService {

    func generateNodesChunked(
        prompt: String,
        in canvas: Canvas
    ) async throws -> ([NodeSchema], [NodeConnectionSchema]) {

        let summary = canvas.makeSemanticSummary()
        let chunks = canvas.makeChunks()
        let existingIDs = Set(canvas.nodes.map(\.id))

        var newNodes: [NodeSchema] = []
        var newConnections: [NodeConnectionSchema] = []

        for chunk in chunks {
            if let result = try? await generateForChunk(
                prompt: prompt,
                summary: summary,
                chunk: chunk,
                existingIDs: existingIDs
            ) {
                newNodes += result.nodes
                newConnections += result.connections
            }
        }

        return normalize(
            nodes: newNodes,
            connections: newConnections,
            existing: existingIDs
        )
    }
    
    func normalize(
        nodes: [NodeSchema],
        connections: [NodeConnectionSchema],
        existing: Set<String>
    ) -> ([NodeSchema], [NodeConnectionSchema]) {

        let uniqueNodes = Dictionary(grouping: nodes, by: \.name)
            .compactMap { $0.value.first }
            .filter { !existing.contains($0.id) }

        let validNodeIDs = Set(uniqueNodes.map(\.id))

        let validConnections = connections.filter {
            validNodeIDs.contains($0.fromNodeId)
            || validNodeIDs.contains($0.toNodeId)
        }

        return (uniqueNodes, validConnections)
    }

}
