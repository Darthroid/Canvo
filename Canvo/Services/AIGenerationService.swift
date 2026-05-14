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
                        .init(id: UUID().uuidString, fromNodeId: mainIdea.id, toNodeId: $0.id)
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

    private func layoutNodesInSemiCircleBelow(
        nodes: inout [NodeSchema],
        center: Position3DSchema,
        radius: Float = 300,
        minAngle: Float = .pi / 6,   // 30° от правой горизонтали
        maxAngle: Float = 5 * .pi / 6 // 150° от правой горизонтали (т.е. 30° до левой горизонтали)
    ) {
        let indices = nodes.indices
        let count = indices.count
        guard count > 0 else { return }
        
        let angleStep: Float = count > 1 ? (maxAngle - minAngle) / Float(count - 1) : 0
        
        for (i, index) in indices.enumerated() {
            let angle: Float
            if count == 1 {
                // Один узел — строго вниз (90°)
                angle = .pi / 2
            } else {
                angle = minAngle + angleStep * Float(i)
            }
            
            nodes[index].position = Position3DSchema(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle),   // sin > 0 → ниже центра
                z: center.z
            )
        }
    }}


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
}

// MARK: - Helper methods to extend canvas

extension AIGenerationService {
    func extendNodes(nodes: [Node], in canvas: Canvas, userInput: String) -> AsyncThrowingStream<(([NodeSchema], [NodeConnectionSchema]), String), Error>  {
        
        AsyncThrowingStream { continuation in
            Task {
                do {
                    var newConnections = [NodeConnectionSchema]()
                    
                    continuation.yield((([], []), "Reading Canvas"))
                    
                    for node in nodes {
                        let schema = node.toSchema()
                        let session = LanguageModelSession(model: model, instructions: """
                            You are an AI that designs a structured mind map.
                            RULES:
                            - Exactly 2-3 nodes as extension to current input.
                            - Each node should describe unique idea extending current input.
                            - Make all decisions respecting user statement: \(userInput)
                            """
                        )
                        
                        let prompt = """
                            extend nodes in canvas '\(canvas.name)' by suggesting sub-topics for the following node: \(schema.name). it's description: \(schema.detail).
                            """
                        
                        var extendedNodes = try await session.respond(
                            to: prompt,
                            generating: [NodeSchema].self
                        ).content
                        
                        // dirty fix: recreate generated result to be sure that ids are correct
                        extendedNodes = extendedNodes.map {
                            NodeSchema(
                                id: UUID().uuidString,
                                name: $0.name,
                                detail: $0.detail,
                                color: $0.color,
                                position: $0.position
                            )
                        }
                        
                        layoutNodesInSemiCircleBelow(nodes: &extendedNodes, center: schema.position)
                        extendedNodes.forEach {
                            newConnections.append(
                                NodeConnectionSchema(
                                    id: UUID().uuidString,
                                    fromNodeId: node.id,
                                    toNodeId: $0.id
                                )
                            )
                        }
                        continuation.yield(((extendedNodes, newConnections), "Extending '\(node.name)'"))
                    }
                    
                    continuation.finish()
                }  catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func summarize(scope: [Node], userInput: String, in canvas: Canvas) async throws -> ([NodeSchema], [NodeConnectionSchema]) {
        
        return ([], [])
    }
    
    func askQuestions(scope: [Node], userInput: String, in canvas: Canvas) async throws -> LanguageModelSession.ResponseStream<String> {
        return askStereamed(prompt: userInput, nodes: scope, in: canvas)
    }
    
    func askStereamed(prompt: String, nodes: [Node], in canvas: Canvas) -> LanguageModelSession.ResponseStream<String> {
        let instructions = """
            You are an AI expert that operates a structured mind map.
            Your main task is to explain canvas and answer questions about canvas.
            You don't ask questions, only answer them.
            If there is no user question provided, explain key points of provided canvas & nodes.
            Do not include any details provided from nodes list, they are provided for you to understand context
            """
        let session = LanguageModelSession(model: model, instructions: instructions)
        
        let list = nodes.map {
            "- \($0.name): \($0.detail)"
        }.joined(separator: "\n")
        
        let question = """
            Take a look at this list of nodes in canvas '\(canvas.name)':
            \(list)
            ___
            \(prompt.isEmpty ? "" : "Using the context provided above make key points of it explaining user provided question: \(prompt)")
            """
        
        return session.streamResponse(to: question)
    }
}
