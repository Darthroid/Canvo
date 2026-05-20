//
//  AIGenerationService.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 08.01.2026.
//

import FoundationModels
import Foundation

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@Observable
class AIGenerationService: Sendable {
    static let shared = AIGenerationService()
    
    private let model = SystemLanguageModel.default
    
    /// Current active generation task
    private var currentTask: Task<Void, Never>?
    
    public var isAvailable: Bool {
        return model.isAvailable
    }
    
    public var runningStage: String?
    private(set) public var error: String?
    
    public var isRunning: Bool {
        return currentTask?.isCancelled == false
    }
    
    private init() {}
    
    /// Cancel currently running AI task
    func cancelCurrentTask() {
        currentTask?.cancel()
        currentTask = nil
        runningStage = nil
        
        clearErrors()
    }
    
    func clearErrors() {
        error = nil
    }
    
    func generateCanvasStream(prompt: String) -> AsyncThrowingStream<CanvasSchema, Error> {
        AsyncThrowingStream { continuation in
            
            // Cancel previous generation if still active
            self.cancelCurrentTask()
            
            self.currentTask = Task {
                do {
                    try Task.checkCancellation()
                    runningStage = "Creating canvas"
                    
                    let session = LanguageModelSession(
                        model: model,
                        instructions: "You are an AI that designs a structured mind map."
                    )
                    
                    // Create canvas
                    var canvas = try await generaeteEmptyCanvas(session: session, prompt: prompt)
                    continuation.yield(canvas)
                    
                    runningStage = "Creating main idea"
                    
                    try Task.checkCancellation()
                    
                    // Create main node
                    var mainIdea = try await generateMainNode(
                        session: session,
                        prompt: prompt,
                        canvasTitle: canvas.name
                    )
                    
                    // dirty fix just in case
                    // sometimes ai halucinates and inserts name of node in id field
                    mainIdea.id = UUID().uuidString
                    
                    canvas.nodes = [mainIdea]
                    continuation.yield(canvas)
                    
                    runningStage = "Extending main idea"
                    
                    try Task.checkCancellation()
                    
                    // Create child nodes
                    let childNodes = try await generateChildNodes(
                        session: session,
                        prompt: prompt,
                        canvasTitle: canvas.name,
                        mainNode: mainIdea
                    )
                    
                    try Task.checkCancellation()
                    
                    canvas.nodes.append(contentsOf: childNodes)
                    
                    // Connect child nodes to main idea node
                    canvas.connections = childNodes.map {
                        .init(
                            id: UUID().uuidString,
                            fromNodeId: mainIdea.id,
                            toNodeId: $0.id
                        )
                    }
                    
                    // Position nodes around main idea node
                    self.layoutNodesInCircle(
                        nodes: &canvas.nodes,
                        centerNodeId: mainIdea.id
                    )
                    
                    runningStage = "Finalizing"
                    
                    continuation.yield(canvas)
                    
                    continuation.finish()
                    self.currentTask = nil
                    
                } catch {
                    if !(error is CancellationError) {
                        self.error = error.localizedDescription
                    }
                    self.currentTask = nil
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
        
        // All other nodes
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
        minAngle: Float = .pi / 6,
        maxAngle: Float = 5 * .pi / 6
    ) {
        let indices = nodes.indices
        let count = indices.count
        guard count > 0 else { return }
        
        let angleStep: Float = count > 1
        ? (maxAngle - minAngle) / Float(count - 1)
        : 0
        
        for (i, index) in indices.enumerated() {
            let angle: Float
            
            if count == 1 {
                angle = .pi / 2
            } else {
                angle = minAngle + angleStep * Float(i)
            }
            
            nodes[index].position = Position3DSchema(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle),
                z: center.z
            )
        }
    }
}


// MARK: - Helper methods to generate canvas

extension AIGenerationService {
    
    private func generaeteEmptyCanvas(session: LanguageModelSession, prompt: String) async throws -> CanvasSchema {
        
        let prompt = """
        RULES:
        Title of canvas = summary of main idea.
        Title should be short and descriptive.
        YOUR TASK:
        Generate a canvas name based on the idea: \(prompt)
        """
        
        let name = try await session.respond(
            to: prompt,
            generating: String.self,
            options: .init(
                sampling: .greedy,
                temperature: 1
            )
        ).content
        
        let canvas = CanvasSchema(
            id: UUID().uuidString,
            name: name,
            nodes: [],
            connections: []
        )
        
        return canvas
    }
    
    private func generateMainNode(
        session: LanguageModelSession,
        prompt: String,
        canvasTitle: String
    ) async throws -> NodeSchema {
        
        let prompt = """
            NODE RULES:
            - Exactly 1 node should be main idea.
            - Main Idea node name should be short and descriptive.
            YOUR TASK:
            Create a main idea node for canvas '\(canvasTitle)' based on the ideas user described: \(prompt)
            """
        
        return try await session.respond(
            to: prompt,
            generating: NodeSchema.self,
            options: .init(
                sampling: .greedy,
                temperature: 1
            )
        ).content
    }
    
    private func generateChildNodes(
        session: LanguageModelSession,
        prompt: String,
        canvasTitle: String,
        mainNode: NodeSchema
    ) async throws -> [NodeSchema] {

        let prompt = """
            NODE RULES:
            - Exactly 10 nodes.
            - Each node should describe unique idea extending main idea.
            YOUR TASK:
            Create nodes for canvas '\(canvasTitle)' based on the ideas user described: \(prompt). 
            The main idea node is: \(mainNode.name). 
            Detail of main node: \(mainNode.detail).
            """
        
        let nodes = try await session.respond(
            to: prompt,
            generating: [NodeSchema].self
        ).content
        
        // dirty fix just in case
        // sometimes ai halucinates and inserts name of node
        return nodes.map {
            NodeSchema(
                id: UUID().uuidString,
                name: $0.name,
                detail: $0.detail,
                color: $0.color,
                position: $0.position
            )
        }
    }
}


// MARK: - Helper methods to extend canvas

extension AIGenerationService {
    
    func extendNodes(
        nodes: [Node],
        in canvas: Canvas,
        userInput: String
    ) -> AsyncThrowingStream<([NodeSchema], [NodeConnectionSchema]), Error> {
        
        AsyncThrowingStream { continuation in
            
            // Cancel previous generation if still active
            self.cancelCurrentTask()
            
            self.currentTask = Task {
                do {
                    var newConnections = [NodeConnectionSchema]()
                    
                    continuation.yield(([], []))
                    runningStage = "Reading Canvas"
                    
                    let session = LanguageModelSession(
                        model: model,
                        instructions: """
                        You are an AI expert that operates a structured mind map.
                        RULES:
                        - Exactly 2-3 nodes as extension to current input.
                        - Each node should describe unique idea extending current input.
                        """
                    )
                    
                    try await Task.sleep(nanoseconds: 2000000000)
                    
                    for node in nodes {
                        try Task.checkCancellation()
                        
                        runningStage = "Extending '\(node.name)'"
                        
                        let schema = node.toSchema()

                        let prompt = """
                        Take a look at this node in canvas '\(canvas.name)':
                        ___
                        NAME:
                        \(node.name)
                        DETAIL:
                        \(node.detail)
                        ___
                        \(userInput.isEmpty
                            ? "Using the node provided above make new nodes that extends its topic or related to its topic."
                            : "Using the node provided above generate new nodes that extends its topic or related to its topic. When generating, also take in mind user provided input: \(userInput)")
                        """
                        
                        var extendedNodes = try await session.respond(
                            to: prompt,
                            generating: [NodeSchema].self
                        ).content
                        
                        try Task.checkCancellation()
                        
                        // dirty fix just in case
                        // sometimes ai halucinates and inserts name of node in id field
                        extendedNodes = extendedNodes.map {
                            NodeSchema(
                                id: UUID().uuidString,
                                name: $0.name,
                                detail: $0.detail,
                                color: $0.color,
                                position: $0.position
                            )
                        }
                        
                        layoutNodesInSemiCircleBelow(
                            nodes: &extendedNodes,
                            center: schema.position
                        )
                        
                        extendedNodes.forEach {
                            newConnections.append(
                                NodeConnectionSchema(
                                    id: UUID().uuidString,
                                    fromNodeId: node.id,
                                    toNodeId: $0.id
                                )
                            )
                        }
                        
                        continuation.yield((extendedNodes, newConnections))
                    }
                    
                    continuation.finish()
                    self.currentTask = nil
                    
                }  catch {
                    continuation.finish(throwing: error)
                    if !(error is CancellationError) {
                        self.error = error.localizedDescription
                    }
                    self.currentTask = nil
                }
            }
        }
    }
    
    func summarize(
        exclude: [Node] = [],
        scope: [Node],
        userInput: String,
        in canvas: Canvas
    ) async throws -> AsyncThrowingStream<(NodeSchema), Error> {
        
        AsyncThrowingStream { continuation in
            
            // Cancel previous generation if still active
            self.cancelCurrentTask()
            
            self.currentTask = Task {
                do {
                    runningStage = "Creating Summary"
                    
                    try Task.checkCancellation()
                    
                    var instructions = """
                        You are an AI expert that operates a structured mind map and generates a concise summary of nodes describing their shared theme, category, meaning, or relationship.
                        RULES:
                        - Exactly 1 node as summary to current input.
                        Rules for "name":
                        - Must represent the common theme or relationship between the objects
                        - Must be concise and human-readable
                        - Prefer a higher-level abstraction when possible
                        Rules for "description":
                        - Briefly explain the detected shared theme
                        - Describe what connects the objects
                        - Include important contextual details from the input descriptions
                        - Keep it concise but informative
                        - Do not repeat the input text verbatim
                        - Write it as a unified summary
                        - Include brief description of all summarized objects
                        Analysis behavior:
                        - First try to find a single theme shared by all objects
                        - If no clear common theme exists, choose the strongest or most probable connection
                        - If the objects are unrelated, infer a summary based on the dominant context or recurring patterns
                        """
                    
                    let excludeTopics = exclude.enumerated().map { (index, node) in
                        """
                        \(index + 1). NAME:
                        \(node.name)
                        DETAIL:
                        \(node.detail)
                        """
                    }.joined(separator: "\n")
                    let excludePrompt = """
                    ___
                      Do not include these related topics to avoid duplication: 
                    \(excludeTopics)
                    ___
                    """
                    
                    let session = LanguageModelSession(
                        model: model,
                        instructions: instructions
                    )
                    
                    let list = scope.map {
                        "- \($0.name): \($0.detail)"
                    }
                    .joined(separator: "\n")
                    
                    let question = """
                    Take a look at this list of nodes in canvas '\(canvas.name)':
                    \(list)
                    \(!exclude.isEmpty ? excludePrompt : "")
                    ___
                    \(userInput.isEmpty
                        ? "Analyze all objects and identify the most likely common theme, category, context, purpose, or shared characteristics between them. Generate a summary node"
                        : "Analyze all objects and identify the most likely common theme, category, context, purpose, or shared characteristics between them. Generate a summary node. When analyzing, also take in mind user provided input: \(userInput)")
                    """
                    
                    var summary = try await session.respond(
                        to: question,
                        generating: NodeSchema.self
                    ).content
                    
                    // dirty fix just in case
                    // sometimes ai halucinates and inserts name of node in id field
                    summary.id = UUID().uuidString
                    
                    try Task.checkCancellation()
                    
                    continuation.yield(summary)
                    
                    continuation.finish()
                    self.currentTask = nil
                    
                }  catch {
                    continuation.finish(throwing: error)
                    if !(error is CancellationError) {
                        self.error = error.localizedDescription
                    }
                    self.currentTask = nil
                }
            }
        }
    }
    
    func askQuestions(
        scope: [Node],
        userInput: String,
        in canvas: Canvas
    ) -> AsyncThrowingStream<String, Error> {
        
        AsyncThrowingStream { continuation in
            
            // Cancel previous generation if still active
            self.cancelCurrentTask()
            
            self.currentTask = Task {
                do {
                    runningStage = "Explainig"
                    
                    try Task.checkCancellation()
                    
                    let instructions = """
                    You are an AI expert that operates a structured mind map.
                    Your main task is to explain canvas and answer questions about canvas.
                    You don't ask questions, only answer them.
                    If there is no user question provided,
                    explain key points of provided canvas & nodes.
                    Do not include any details provided from nodes list,
                    they are provided for you to understand context
                    """
                    
                    let session = LanguageModelSession(
                        model: model,
                        instructions: instructions
                    )
                    
                    let list = scope.map {
                        "- \($0.name): \($0.detail)"
                    }
                    .joined(separator: "\n")
                    
                    let question = """
                    Take a look at this list of nodes in canvas '\(canvas.name)':
                    \(list)
                    ___
                    \(userInput.isEmpty
                        ? "Using the context provided above make key points of it"
                        : "Using the context provided above make key points that also answering user provided question: \(userInput)")
                    """
                    
                    let stream = session.streamResponse(to: question)
                    
                    for try await chunk in stream {
                        try Task.checkCancellation()
                        continuation.yield(chunk.content)
                    }
                    
                    continuation.finish()
                    self.currentTask = nil
                    
                } catch {
                    continuation.finish(throwing: error)
                    if !(error is CancellationError) {
                        self.error = error.localizedDescription
                    }
                    self.currentTask = nil
                }
            }
        }
    }
}
