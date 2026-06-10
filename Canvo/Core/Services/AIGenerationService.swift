//
//  AIGenerationService.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 08.01.2026.
//

import FoundationModels
import Foundation

enum CanvasGenerationStyle: String, CaseIterable, Identifiable {
    case radial
    case tree

    var id: String { rawValue }

    var title: String {
        switch self {
        case .radial:
            return String(localized: "Radial")
        case .tree:
            return String(localized: "Tree")
        }
    }

    var subtitle: String {
        switch self {
        case .radial:
            return String(localized: "One idea in the center with connected topics around it")
        case .tree:
            return String(localized: "Hierarchical structure with branches and subtopics")
        }
    }
}

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@Observable
class AIGenerationService: Sendable {
    
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
    
    public init() {}
    
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
    
    func generateCanvasStream(
        prompt: String,
        style: CanvasGenerationStyle = .tree
    ) -> AsyncThrowingStream<CanvasSchema, Error> {
        AsyncThrowingStream { continuation in

            self.cancelCurrentTask()

            self.currentTask = Task {
                do {

                    try Task.checkCancellation()

                    runningStage = String(localized: "Creating canvas")

                    let session = LanguageModelSession(
                        model: model,
                        instructions: "You are an AI that designs a structured mind map."
                    )

                    var canvas = try await generaeteEmptyCanvas(
                        session: session,
                        prompt: prompt
                    )

                    continuation.yield(canvas)

                    // MAIN NODE

                    runningStage = String(localized: "Creating main idea")

                    var mainIdea = try await generateMainNode(
                        session: session,
                        prompt: prompt,
                        canvasTitle: canvas.name
                    )

                    mainIdea.id = UUID().uuidString
                    mainIdea.position = .init(
                        x: 0,
                        y: 0,
                        z: 0
                    )

                    canvas.nodes.append(mainIdea)

                    continuation.yield(canvas)

                    try Task.checkCancellation()
                    
                    runningStage = String(localized: "Extending main idea")

                    let generated = try await generateNodes(
                        style: style,
                        session: session,
                        prompt: prompt,
                        canvasTitle: canvas.name,
                        mainNode: mainIdea
                    )

                    canvas.nodes.append(contentsOf: generated.nodes)
                    canvas.connections.append(contentsOf: generated.connections)

                    continuation.yield(canvas)

                    runningStage = String(localized: "Finalizing")

                    continuation.yield(canvas)

                    continuation.finish()

                    self.currentTask = nil

                } catch {

                    if !(error is CancellationError) {
                        self.error = error.localizedDescription
                    }

                    continuation.finish(throwing: error)

                    self.currentTask = nil
                }
            }
        }
    }
    
    private func generateNodes(
        style: CanvasGenerationStyle,
        session: LanguageModelSession,
        prompt: String,
        canvasTitle: String,
        mainNode: NodeSchema
    ) async throws -> (
        nodes: [NodeSchema],
        connections: [NodeConnectionSchema]
    ) {

        switch style {

        case .radial:

            var nodes = try await generateChildNodes(
                session: session,
                prompt: prompt,
                canvasTitle: canvasTitle,
                mainNode: mainNode
            )

            nodes = nodes.map {
                NodeSchema(
                    id: UUID().uuidString,
                    name: $0.name,
                    detail: $0.detail,
                    color: $0.color,
                    position: $0.position
                )
            }

            var allNodes = [mainNode]
            allNodes.append(contentsOf: nodes)

            layoutNodesInCircle(
                nodes: &allNodes,
                centerNodeId: mainNode.id
            )

            let positionedNodes = Array(allNodes.dropFirst())

            let connections = positionedNodes.map {
                NodeConnectionSchema(
                    id: UUID().uuidString,
                    fromNodeId: mainNode.id,
                    toNodeId: $0.id
                )
            }

            return (
                nodes: positionedNodes,
                connections: connections
            )

        case .tree:

            var generatedNodes: [NodeSchema] = []
            var connections: [NodeConnectionSchema] = []

            var branches = try await generateBranchNodes(
                session: session,
                prompt: prompt,
                canvasTitle: canvasTitle,
                mainNode: mainNode
            )

            let branchPositions: [Position3DSchema] = [
                .init(x: -200, y:  150, z: 0), // top left
                .init(x: -200, y: -150, z: 0), // bottom left
                .init(x:  200, y:  150, z: 0), // top right
                .init(x:  200, y: -150, z: 0)  // bottom right
            ]

            for index in branches.indices {

                branches[index].id = UUID().uuidString
                branches[index].position = branchPositions[index]

                generatedNodes.append(branches[index])

                connections.append(
                    NodeConnectionSchema(
                        id: UUID().uuidString,
                        fromNodeId: mainNode.id,
                        toNodeId: branches[index].id
                    )
                )
            }

            for branch in branches {

                var leafNodes = try await generateLeafNodes(
                    session: session,
                    branchNode: branch
                )

                let isLeftSide = branch.position.x < 0

                let childX: Float = isLeftSide
                    ? branch.position.x - 250
                    : branch.position.x + 250

                if leafNodes.indices.contains(0) {

                    leafNodes[0].id = UUID().uuidString

                    leafNodes[0].position = .init(
                        x: childX,
                        y: branch.position.y + 60,
                        z: 0
                    )

                    generatedNodes.append(leafNodes[0])

                    connections.append(
                        NodeConnectionSchema(
                            id: UUID().uuidString,
                            fromNodeId: branch.id,
                            toNodeId: leafNodes[0].id
                        )
                    )
                }

                if leafNodes.indices.contains(1) {

                    leafNodes[1].id = UUID().uuidString

                    leafNodes[1].position = .init(
                        x: childX,
                        y: branch.position.y - 60,
                        z: 0
                    )

                    generatedNodes.append(leafNodes[1])

                    connections.append(
                        NodeConnectionSchema(
                            id: UUID().uuidString,
                            fromNodeId: branch.id,
                            toNodeId: leafNodes[1].id
                        )
                    )
                }
            }

            return (
                nodes: generatedNodes,
                connections: connections
            )
        }
    }
    
    private func generateBranchNodes(
        session: LanguageModelSession,
        prompt: String,
        canvasTitle: String,
        mainNode: NodeSchema
    ) async throws -> [NodeSchema] {

        let prompt = """
        RULES:
        - Generate exactly 4 nodes.
        - Every node must be a major branch of the main idea.
        - Branches should cover different aspects.
        - Keep names concise.

        MAIN IDEA:
        \(mainNode.name)

        DETAIL:
        \(mainNode.detail)
        """

        let nodes = try await session.respond(
            to: prompt,
            generating: [NodeSchema].self
        ).content

        return nodes.prefix(4).map {
            NodeSchema(
                id: UUID().uuidString,
                name: $0.name,
                detail: $0.detail,
                color: $0.color,
                position: .init(x: 0, y: 0, z: 0)
            )
        }
    }
    
    private func generateLeafNodes(
        session: LanguageModelSession,
        branchNode: NodeSchema
    ) async throws -> [NodeSchema] {

        let prompt = """
        RULES:
        - Generate exactly 2 nodes.
        - Nodes must expand the parent topic.
        - Keep names concise.

        PARENT:
        \(branchNode.name)

        DETAIL:
        \(branchNode.detail)
        """

        let nodes = try await session.respond(
            to: prompt,
            generating: [NodeSchema].self
        ).content

        return nodes.prefix(2).map {
            NodeSchema(
                id: UUID().uuidString,
                name: $0.name,
                detail: $0.detail,
                color: $0.color,
                position: .init(x: 0, y: 0, z: 0)
            )
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
                    runningStage = String(localized: "Reading Canvas")
                    
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
                        
                        runningStage = String(localized: "Extending '\(node.name)'")
                        
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
                    runningStage = String(localized: "Creating Summary")
                    
                    try Task.checkCancellation()
                    
                    let instructions = """
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
                    runningStage = String(localized: "Explainig")
                    
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
