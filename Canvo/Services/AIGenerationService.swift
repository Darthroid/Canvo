//
//  AIGenerationService.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 08.01.2026.
//

import FoundationModels
import Foundation

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
class AIGenerationService {
    static let shared = AIGenerationService()
    
    private let model = SystemLanguageModel.default
    
    public var isAvailable: Bool {
        return model.isAvailable
    }
    
    private init() {}

    
    func generateCanvasStream(prompt: String) -> AsyncThrowingStream<(CanvasSchema, String), Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    
                    // Create canvas
                    var canvas = try await generaeteEmptyCanvas(prompt: prompt)
                    continuation.yield((canvas, "Creating main idea"))
                    
                    // Create main node
                    let mainIdea = try await generateMainNode(prompt: prompt, canvasTitle: canvas.name)
                    canvas.nodes = [mainIdea]
                    continuation.yield((canvas, "Extending main idea"))
                    
                    // Create child nodes
                    let childNodes = try await generateChildNodes(prompt: prompt, canvasTitle: canvas.name, mainNode: mainIdea)
                    canvas.nodes.append(contentsOf: childNodes)
                    
                    // Connect child nodes to main idea node
                    canvas.connections = childNodes.map {
                        .init(id: UUID().uuidString, fromNodeId: $0.id, toNodeId: mainIdea.id)
                    }
                    
                    // Position nodes aroind main idea node
                    self.layoutNodesInCircle(nodes: &canvas.nodes, centerNodeId: mainIdea.id)
                    
                    continuation.yield((canvas, "Finalizing"))
                    
                    continuation.finish()

                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}


// MARK: - Helper methods to generate canvas
extension AIGenerationService {
    private func generaeteEmptyCanvas(prompt: String) async throws -> CanvasSchema {
        let session = LanguageModelSession(model: model, instructions: """
            You are an AI that designs a structured mind map.
            Title of canvas = summary of main idea.
            Title should be short and descriptive.
            """
        )
        
        let prompt = "Generate a canvas name based on the idea: \(prompt)"

        let name =  try await session.respond(
            to: prompt,
            generating: String.self,
            options: .init(sampling: .greedy, temperature: 1)
        ).content
        
        let canvas = CanvasSchema(id: UUID().uuidString, name: name, nodes: [], connections: [])
        
        return canvas
    }
    
    private func generateMainNode(prompt: String, canvasTitle: String) async throws -> NodeSchema {
        let session = LanguageModelSession(model: model, instructions: """
            You are an AI that designs a structured mind map.
            NODE RULES:
            - Exactly 1 node should be main idea.
            - Main Idea node name should be short and descriptive.
            """
        )
        
        let prompt = "Create a main idea node for canvas '\(canvasTitle)' based on the ideas user described: \(prompt)"
        
        return try await session.respond(
            to: prompt,
            generating: NodeSchema.self,
            options: .init(sampling: .greedy, temperature: 1)
        ).content
    }
    
    private func generateChildNodes(prompt: String, canvasTitle: String, mainNode: NodeSchema) async throws -> [NodeSchema] {
        let session = LanguageModelSession(model: model, instructions: """
            You are an AI that designs a structured mind map.
            NODE RULES:
            - Exactly 10 nodes.
            - Each node should describe unique idea extending main idea.
            """
        )
        
        let prompt = """
            Create nodes for canvas '\(canvasTitle)' based on the ideas user described: \(prompt). 
            The main idea node is: \(mainNode.name). 
            Detail of main node: \(mainNode.detail).
            """
        
        return try await session.respond(
            to: prompt,
            generating: [NodeSchema].self
        ).content
    }
    
    private func layoutNodesInCircle(
        nodes: inout [NodeSchema],
        centerNodeId: String,
        radius: Float = 300
    ) {
        guard let centerIndex = nodes.firstIndex(where: { $0.id == centerNodeId }) else {
            return
        }
        
        // center
        nodes[centerIndex].position = Position3DSchema(x: 0, y: 0, z: 0)
        
        // Все остальные
        var otherIndices: [Int] = []
        for i in nodes.indices {
            if i != centerIndex {
                otherIndices.append(i)
            }
        }
        
        let count = otherIndices.count
        guard count > 0 else { return }
        
        for (i, index) in otherIndices.enumerated() {
            let angle = (2 * Float.pi * Float(i)) / Float(count)
            
            let x = radius * cos(angle)
            let y = radius * sin(angle)
            
            nodes[index].position = Position3DSchema(
                x: x,
                y: y,
                z: 0
            )
        }
    }
}
