//
//  AIGenerationService.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 08.01.2026.
//


import Foundation
import FoundationModels

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@Observable
final class AIGenerationService: Sendable {

    private let model = SystemLanguageModel.default
    private let promptBuilder = PromptFactory()

    private var currentTask: Task<Void, Never>?

    public var runningStage: String?
    private(set) public var error: String?

    public var isAvailable: Bool {
        model.isAvailable
    }

    public var isRunning: Bool {
        currentTask != nil
    }

    public init() {}

    // MARK: - Cancel

    func cancelCurrentTask() {
        currentTask?.cancel()
        currentTask = nil
        runningStage = nil
        error = nil
    }

    func clearErrors() {
        error = nil
    }

    // MARK: - PUBLIC API

    func generateCanvasStream(
        prompt: String,
        style: CanvasGenerationStyle = .tree
    ) -> AsyncThrowingStream<CanvasSchema, Error> {

        AsyncThrowingStream { continuation in

            self.cancelCurrentTask()

            self.currentTask = Task {
                do {
                    try Task.checkCancellation()

                    let session = LanguageModelSession(
                        model: model,
                        instructions: "You generate structured knowledge graphs."
                    )

                    // MARK: - 1. Canvas title (LIGHT MODE)

                    self.runningStage = String(localized: "Creating canvas")

                    let titlePrompt = promptBuilder.build(
                        task: .canvasTitle,
                        context: .init(
                            userInput: prompt
                        )
                    )

                    let canvasName = try await session.respond(
                        to: titlePrompt,
                        generating: String.self,
                        options: .init(sampling: .greedy, temperature: 1)
                    ).content

                    var canvas = CanvasSchema(
                        id: UUID().uuidString,
                        name: canvasName,
                        nodes: [],
                        connections: []
                    )

                    continuation.yield(canvas)

                    // MARK: - 2. Main node (LIGHT MODE)

                    self.runningStage = String(localized: "Creating main idea")

                    let mainPrompt = promptBuilder.build(
                        task: .mainNode,
                        context: .init(
                            canvasName: canvas.name,
                            userInput: prompt
                        )
                    )

                    var mainNode = try await session.respond(
                        to: mainPrompt,
                        generating: NodeSchema.self
                    ).content

                    mainNode.id = UUID().uuidString
                    mainNode.position = .init(x: 0, y: 0, z: 0)

                    canvas.nodes.append(mainNode)

                    continuation.yield(canvas)

                    try Task.checkCancellation()

                    // MARK: - 3. Expand graph (ONLY HERE v2 intelligence is allowed)

                    self.runningStage = String(localized: "Expanding graph")

                    let graphState = GraphStateBuilder.build(
                        nodes: canvas.nodes,
                        connections: canvas.connections
                    )

                    let graphMemory = GraphMemory.build(graphState)
                    let semanticGuard = SemanticGuard.build(canvas.nodes)

                    let generated = try await generateNodes(
                        style: style,
                        session: session,
                        prompt: prompt,
                        canvas: canvas,
                        mainNode: mainNode,
                        graphMemory: graphMemory,
                        semanticGuard: semanticGuard
                    )

                    canvas.nodes.append(contentsOf: generated.nodes)
                    canvas.connections.append(contentsOf: generated.connections)

                    continuation.yield(canvas)

                    self.runningStage = String(localized: "Finalizing")
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
    
    // MARK: - EXTEND GRAPH

    func extendGraph(
        nodes: [Node],
        in canvas: Canvas,
        userInput: String
    ) -> AsyncThrowingStream<([NodeSchema], [NodeConnectionSchema]), Error> {

        AsyncThrowingStream { continuation in

            self.cancelCurrentTask()

            self.currentTask = Task {
                do {

                    let session = LanguageModelSession(
                        model: model,
                        instructions: """
                        You are an incremental graph expansion engine.
                        Expand ONLY the given node. Do not drift to global context.
                        Return coherent local structures.
                        """
                    )

                    var allNewNodes: [NodeSchema] = []
                    var allNewConnections: [NodeConnectionSchema] = []

                    for node in nodes {

                        try Task.checkCancellation()

                        self.runningStage = String(localized: "Extending \(node.name)")

                        let state = GraphStateBuilder.build(
                            nodes: (canvas.nodes ?? []).map { $0.toSchema() },
                            connections: (canvas.connections ?? []).map { $0.toSchema() }
                        )

                        let memory = GraphMemory.build(state)
                        let guardText = SemanticGuard.build((canvas.nodes ?? []).map { $0.toSchema() })

                        let prompt = promptBuilder.build(
                            task: .extendNode,
                            context: .init(
                                canvasName: canvas.name,
                                parentNode: node.toSchema(),
                                userInput: userInput,
                                graphMemory: memory,
                                semanticGuard: guardText
                            )
                        )

                        var extended = try await session.respond(
                            to: prompt,
                            generating: [NodeSchema].self
                        ).content.map(normalize)

                        // layout per parent node
                        layoutNodesInSemiCircle(
                            nodes: &extended,
                            center: node.toSchema().position
                        )

                        // build connections for THIS node
                        let connections = extended.map {
                            NodeConnectionSchema(
                                id: UUID().uuidString,
                                fromNodeId: node.id,
                                toNodeId: $0.id
                            )
                        }

                        allNewNodes.append(contentsOf: extended)
                        allNewConnections.append(contentsOf: connections)

                        continuation.yield((allNewNodes, allNewConnections))
                    }

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
    
    // MARK: - SUMMARIZE GRAPH

    func summarizeGraph(
        scope: [Node],
        exclude: [Node] = [],
        in canvas: Canvas,
        userInput: String
    ) -> AsyncThrowingStream<NodeSchema, Error> {

        AsyncThrowingStream { continuation in

            self.cancelCurrentTask()

            self.currentTask = Task {
                do {

                    let session = LanguageModelSession(
                        model: model,
                        instructions: """
                        You compress multiple nodes into a single abstraction node.
                        Focus on shared meaning, not enumeration.
                        """
                    )

                    self.runningStage = String(localized: "Summarizing")

                    let state = GraphStateBuilder.build(
                        nodes: (canvas.nodes ?? []).map { $0.toSchema() },
                        connections: (canvas.connections ?? []).map { $0.toSchema() }
                    )

                    let memory = GraphMemory.build(state)
                    let guardText = SemanticGuard.build((canvas.nodes ?? []).map { $0.toSchema() })

                    let scopeText = scope.map {
                        "- \($0.name): \($0.detail)"
                    }.joined(separator: "\n")

                    let excludeText = exclude.map {
                        "- \($0.name): \($0.detail)"
                    }.joined(separator: "\n")

                    let prompt = """
                    TASK:
                    Create a single summary node.

                    SCOPE:
                    \(scopeText)

                    EXCLUDE:
                    \(excludeText)

                    USER INPUT:
                    \(userInput)

                    GRAPH MEMORY:
                    \(memory)

                    SEMANTIC GUARD:
                    \(guardText)
                    """

                    var summary = try await session.respond(
                        to: prompt,
                        generating: NodeSchema.self
                    ).content

                    summary.id = UUID().uuidString

                    continuation.yield(summary)
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
    
    // MARK: - ASK GRAPH

    func askGraph(
        scope: [Node],
        userInput: String,
        in canvas: Canvas
    ) -> AsyncThrowingStream<String, Error> {

        AsyncThrowingStream { continuation in

            self.cancelCurrentTask()

            self.currentTask = Task {
                do {

                    let session = LanguageModelSession(
                        model: model,
                        instructions: """
                        You explain graph structure.
                        Focus on insights, not listing nodes.
                        """
                    )

                    self.runningStage = String(localized: "Analyzing")

                    let state = GraphStateBuilder.build(
                        nodes: (canvas.nodes ?? []).map { $0.toSchema() },
                        connections: (canvas.connections ?? []).map { $0.toSchema() }
                    )

                    let memory = GraphMemory.build(state)

                    let list = scope.map {
                        "- \($0.name): \($0.detail)"
                    }.joined(separator: "\n")

                    let prompt = """
                    GRAPH:
                    \(memory)

                    NODES:
                    \(list)

                    QUESTION:
                    \(userInput)
                    """

                    let stream = session.streamResponse(to: prompt)

                    for try await chunk in stream {
                        try Task.checkCancellation()
                        continuation.yield(chunk.content)
                    }

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

    // MARK: - NODE GENERATION DISPATCH

    private func generateNodes(
        style: CanvasGenerationStyle,
        session: LanguageModelSession,
        prompt: String,
        canvas: CanvasSchema,
        mainNode: NodeSchema,
        graphMemory: String,
        semanticGuard: String
    ) async throws -> (
        nodes: [NodeSchema],
        connections: [NodeConnectionSchema]
    ) {

        switch style {

        case .radial:
            return try await generateRadial(
                session: session,
                prompt: prompt,
                canvas: canvas,
                mainNode: mainNode,
                graphMemory: graphMemory,
                semanticGuard: semanticGuard
            )

        case .tree:
            return try await generateTree(
                session: session,
                prompt: prompt,
                canvas: canvas,
                mainNode: mainNode,
                graphMemory: graphMemory,
                semanticGuard: semanticGuard
            )
        }
    }

    // MARK: - RADIAL

    private func generateRadial(
        session: LanguageModelSession,
        prompt: String,
        canvas: CanvasSchema,
        mainNode: NodeSchema,
        graphMemory: String,
        semanticGuard: String
    ) async throws -> (nodes: [NodeSchema], connections: [NodeConnectionSchema]) {

        self.runningStage = String(localized: "Radial expansion")

        let promptText = promptBuilder.build(
            task: .childNodes,
            context: .init(
                canvasName: canvas.name,
                mainNode: mainNode,
                userInput: prompt,
                graphMemory: graphMemory,
                semanticGuard: semanticGuard
            )
        )

        var nodes = try await session.respond(
            to: promptText,
            generating: [NodeSchema].self
        ).content

        nodes = nodes.map(normalize)

        var allNodes = [mainNode] + nodes
        layoutNodesInCircle(nodes: &allNodes, centerNodeId: mainNode.id)

        let positioned = Array(allNodes.dropFirst())

        let connections = positioned.map {
            NodeConnectionSchema(
                id: UUID().uuidString,
                fromNodeId: mainNode.id,
                toNodeId: $0.id
            )
        }

        return (positioned, connections)
    }

    // MARK: - TREE

    private func generateTree(
        session: LanguageModelSession,
        prompt: String,
        canvas: CanvasSchema,
        mainNode: NodeSchema,
        graphMemory: String,
        semanticGuard: String
    ) async throws -> (nodes: [NodeSchema], connections: [NodeConnectionSchema]) {

        self.runningStage = String(localized: "Branching")

        // 1. Branches

        let branchPrompt = promptBuilder.build(
            task: .branchNodes,
            context: .init(
                canvasName: canvas.name,
                mainNode: mainNode,
                userInput: prompt,
                graphMemory: graphMemory,
                semanticGuard: semanticGuard
            )
        )

        var branches = try await session.respond(
            to: branchPrompt,
            generating: [NodeSchema].self
        ).content.map(normalize)

        let positions: [Position3DSchema] = [
            .init(x: -200, y: 150, z: 0),
            .init(x: -200, y: -150, z: 0),
            .init(x: 200, y: 150, z: 0),
            .init(x: 200, y: -150, z: 0)
        ]

        var nodes: [NodeSchema] = []
        var connections: [NodeConnectionSchema] = []

        for i in branches.indices {
            branches[i].id = UUID().uuidString
            branches[i].position = positions[i]

            nodes.append(branches[i])

            connections.append(
                NodeConnectionSchema(
                    id: UUID().uuidString,
                    fromNodeId: mainNode.id,
                    toNodeId: branches[i].id
                )
            )
        }

        // 2. Leaves per branch

        for branch in branches {

            self.runningStage = String(localized: "Expanding \(branch.name)")

            let leafPrompt = promptBuilder.build(
                task: .leafNodes,
                context: .init(
                    canvasName: canvas.name,
                    parentNode: branch,
                    userInput: prompt,
                    graphMemory: graphMemory,
                    semanticGuard: semanticGuard
                )
            )

            var leaves = try await session.respond(
                to: leafPrompt,
                generating: [NodeSchema].self
            ).content.map(normalize)

            let isLeft = branch.position.x < 0
            let childX: Float = isLeft ? branch.position.x - 250 : branch.position.x + 250

            if leaves.indices.contains(0) {
                leaves[0].id = UUID().uuidString
                leaves[0].position = .init(x: childX, y: branch.position.y + 60, z: 0)

                nodes.append(leaves[0])

                connections.append(
                    NodeConnectionSchema(
                        id: UUID().uuidString,
                        fromNodeId: branch.id,
                        toNodeId: leaves[0].id
                    )
                )
            }

            if leaves.indices.contains(1) {
                leaves[1].id = UUID().uuidString
                leaves[1].position = .init(x: childX, y: branch.position.y - 60, z: 0)

                nodes.append(leaves[1])

                connections.append(
                    NodeConnectionSchema(
                        id: UUID().uuidString,
                        fromNodeId: branch.id,
                        toNodeId: leaves[1].id
                    )
                )
            }
        }

        return (nodes, connections)
    }

    // MARK: - NORMALIZATION

    private func normalize(_ node: NodeSchema) -> NodeSchema {
        var copy = node
        copy.id = UUID().uuidString
        return copy
    }

    // MARK: - LAYOUT

    private func layoutNodesInCircle(
        nodes: inout [NodeSchema],
        centerNodeId: String,
        radius: Float = 300
    ) {
        guard let centerIndex = nodes.firstIndex(where: { $0.id == centerNodeId }) else { return }

        nodes[centerIndex].position = .init(x: 0, y: 0, z: 0)

        let others = nodes.indices.filter { $0 != centerIndex }
        let count = others.count
        guard count > 0 else { return }

        for (i, index) in others.enumerated() {
            let angle = (2 * Float.pi * Float(i)) / Float(count)

            nodes[index].position = .init(
                x: radius * cos(angle),
                y: radius * sin(angle),
                z: 0
            )
        }
    }
    
    private func layoutNodesInSemiCircle(
        nodes: inout [NodeSchema],
        center: Position3DSchema,
        radius: Float = 300
    ) {
        let count = nodes.count
        guard count > 0 else { return }

        let minAngle: Float = .pi / 6
        let maxAngle: Float = 5 * .pi / 6
        let step = count > 1 ? (maxAngle - minAngle) / Float(count - 1) : 0

        for i in nodes.indices {

            let angle = count == 1
                ? .pi / 2
                : minAngle + step * Float(i)

            nodes[i].position = .init(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle),
                z: center.z
            )
        }
    }
}
