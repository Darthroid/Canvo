//
//  AIGenerationService.swift
//  Canvo
//
//  Created by Олег Комаристый on 08.01.2026.
//


import Foundation
import FoundationModels

@Observable
final class AIGenerationService: Sendable {

    @available(iOS 26.0, *)
    private var model: SystemLanguageModel {
        .default
    }
    
    @available(iOS 26.0, *)
    private var promptBuilder: PromptFactory {
        PromptFactory()
    }
    @available(iOS 26.0, *)
    private var layout: CanvasLayoutService {
        CanvasLayoutService()
    }

    private var currentTask: Task<Void, Never>? {
        didSet {
            isRunning = currentTask != nil
        }
    }

    public var runningStage: String?
    private(set) public var error: String?

    public var isAvailable: Bool {
        if #available(iOS 26.0, *) {
            model.isAvailable
        } else {
           false
        }
    }

    private(set) public var isRunning: Bool = false

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
    @available(iOS 26.0, *)
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
                        instructions: SessionInstructionPolicy.instructions(for: .graphGeneration)
                    )

                    self.runningStage = String(localized: "Creating canvas")

                    let titlePrompt = promptBuilder.build(
                        sessionInstructions: SessionInstructionPolicy.instructions(for: .graphGeneration),
                        task: .canvasTitle,
                        context: .init(userInput: prompt)
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

                    self.runningStage = String(localized: "Creating main idea")

                    let mainPrompt = promptBuilder.build(
                        sessionInstructions: SessionInstructionPolicy.instructions(for: .graphGeneration),
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

                    self.runningStage = String(localized: "Expanding graph")

                    let semanticGuard = SemanticGuard.build(canvas.nodes)

                    let generated = try await generateNodes(
                        style: style,
                        session: session,
                        prompt: prompt,
                        canvas: canvas,
                        mainNode: mainNode,
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
    @available(iOS 26.0, *)
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
                        instructions: SessionInstructionPolicy.instructions(for: .graphExpansion)
                    )

                    var allNewNodes: [NodeSchema] = []
                    var allNewConnections: [NodeConnectionSchema] = []

                    for node in nodes {

                        try Task.checkCancellation()

                        self.runningStage = String(localized: "Extending \(node.name)")

                        let guardText = SemanticGuard.build((canvas.nodes ?? []).map { $0.toSchema() })

                        let prompt = promptBuilder.build(
                            sessionInstructions: SessionInstructionPolicy.instructions(for: .graphExpansion),
                            task: .extendNode,
                            context: .init(
                                canvasName: canvas.name,
                                parentNode: node.toSchema(),
                                userInput: userInput,
                                semanticGuard: guardText
                            )
                        )

                        var extended = try await session.respond(
                            to: prompt,
                            generating: [NodeSchema].self
                        ).content.map(normalize)
                        
                        layout.layoutWithCollisionAvoidance(
                            nodes: &extended,
                            center: node.toSchema().position,
                            allNodes: (canvas.nodes ?? []).map { $0.toSchema() }
                        )

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
    @available(iOS 26.0, *)
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
                        instructions: SessionInstructionPolicy.instructions(for: .summarization)
                    )

                    self.runningStage = String(localized: "Summarizing")

                    let guardText = SemanticGuard.build((canvas.nodes ?? []).map { $0.toSchema() })

                    let scopeText = scope.map { "- \($0.name): \($0.detail)" }.joined(separator: "\n")

                    let prompt = promptBuilder.build(
                        sessionInstructions: SessionInstructionPolicy.instructions(for: .summarization),
                        task: .summarize,
                        context: .init(
                            canvasName: canvas.name,
                            userInput: userInput,
                            semanticGuard: guardText,
                            nodeContent: scopeText
                        )
                    )

                    var summary = try await session.respond(
                        to: prompt,
                        generating: NodeSchema.self
                    ).content

                    summary.id = UUID().uuidString

                    var allNodes = (canvas.nodes ?? []).map { $0.toSchema() }

                    let scopePositions = scope.map {
                        Position3DSchema(
                            x: $0.position.x,
                            y: $0.position.y,
                            z: $0.position.z
                        )
                    }

                    let centroid = layout.computeCentroid(scopePositions)

                    let direction = layout.findBestExpansionDirection(
                        from: centroid,
                        occupied: allNodes
                    )

                    summary.position = layout.findBestPositionInField(
                        preferredDirection: direction,
                        origin: centroid,
                        allNodes: allNodes,
                        radiusStart: 220
                    )
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
    @available(iOS 26.0, *)
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
                        instructions: SessionInstructionPolicy.instructions(for: .qa)
                    )

                    self.runningStage = String(localized: "Analyzing")

                    let list = scope.map { "- \($0.name): \($0.detail)" }.joined(separator: "\n")

                    let prompt = promptBuilder.build(
                        sessionInstructions: SessionInstructionPolicy.instructions(for: .qa),
                        task: .askQuestions,
                        context: .init(
                            canvasName: canvas.name,
                            userInput: userInput,
                            nodeContent: list
                        )
                    )

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

    // MARK: - NODE EDITING
    @available(iOS 26.0, *)
    func rewriteNodeContent(
        task: PromptFactory.Task,
        title: String,
        content: String
    ) async throws -> String {

        cancelCurrentTask()

        let job = Task<String, Error> {

            let session = LanguageModelSession(
                model: model,
                instructions: SessionInstructionPolicy.instructions(for: .rewriting)
            )

            let prompt = promptBuilder.build(
                sessionInstructions: SessionInstructionPolicy.instructions(for: .rewriting),
                task: task,
                context: .init(
                    nodeTitle: title,
                    nodeContent: content
                )
            )

            let result = try await session.respond(
                to: prompt,
                generating: String.self
            )

            return result.content.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        currentTask = Task {
            _ = try? await job.value
            self.currentTask = nil
        }

        return try await job.value
    }

    // MARK: - TAG GENERATION
    @available(iOS 26.0, *)
    func generateTags(
        title: String,
        content: String
    ) async throws -> String {

        cancelCurrentTask()

        let job = Task<String, Error> {

            let session = LanguageModelSession(
                model: model,
                instructions: SessionInstructionPolicy.instructions(for: .rewriting)
            )

            let prompt = promptBuilder.build(
                sessionInstructions: SessionInstructionPolicy.instructions(for: .rewriting),
                task: .generateTags,
                context: .init(
                    userInput: """
                    Title: \(title)

                    Content:
                    \(content)
                    """
                )
            )

            let result = try await session.respond(
                to: prompt,
                generating: String.self
            )

            return result.content.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        currentTask = Task {
            _ = try? await job.value
            self.currentTask = nil
        }

        return try await job.value
    }

    // MARK: - NODE GENERATION DISPATCH
    @available(iOS 26.0, *)
    private func generateNodes(
        style: CanvasGenerationStyle,
        session: LanguageModelSession,
        prompt: String,
        canvas: CanvasSchema,
        mainNode: NodeSchema,
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
                semanticGuard: semanticGuard
            )

        case .tree:
            return try await generateTree(
                session: session,
                prompt: prompt,
                canvas: canvas,
                mainNode: mainNode,
                semanticGuard: semanticGuard
            )
        }
    }

    // MARK: - RADIAL
    @available(iOS 26.0, *)
    private func generateRadial(
        session: LanguageModelSession,
        prompt: String,
        canvas: CanvasSchema,
        mainNode: NodeSchema,
        semanticGuard: String
    ) async throws -> (nodes: [NodeSchema], connections: [NodeConnectionSchema]) {

        self.runningStage = String(localized: "Creating related topics")

        let promptText = promptBuilder.build(
            sessionInstructions: SessionInstructionPolicy.instructions(for: .graphExpansion),
            task: .childNodes,
            context: .init(
                canvasName: canvas.name,
                mainNode: mainNode,
                userInput: prompt,
                semanticGuard: semanticGuard
            )
        )

        var nodes = try await session.respond(
            to: promptText,
            generating: [NodeSchema].self
        ).content

        nodes = nodes.map(normalize)

        var allNodes = [mainNode] + nodes
        layout.layoutNodesInCircle(
            nodes: &allNodes,
            centerNodeId: mainNode.id
        )

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
    @available(iOS 26.0, *)
    private func generateTree(
        session: LanguageModelSession,
        prompt: String,
        canvas: CanvasSchema,
        mainNode: NodeSchema,
        semanticGuard: String
    ) async throws -> (nodes: [NodeSchema], connections: [NodeConnectionSchema]) {

        self.runningStage = String(localized: "Creating related topics")

        let branchPrompt = promptBuilder.build(
            sessionInstructions: SessionInstructionPolicy.instructions(for: .graphGeneration),
            task: .branchNodes,
            context: .init(
                canvasName: canvas.name,
                mainNode: mainNode,
                userInput: prompt,
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

        for branch in branches {

            self.runningStage = String(localized: "Expanding \(branch.name)")

            let leafPrompt = promptBuilder.build(
                sessionInstructions: SessionInstructionPolicy.instructions(for: .graphExpansion),
                task: .leafNodes,
                context: .init(
                    canvasName: canvas.name,
                    parentNode: branch,
                    userInput: prompt,
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
    @available(iOS 26.0, *)
    private func normalize(_ node: NodeSchema) -> NodeSchema {
        var copy = node
        copy.id = UUID().uuidString
        return copy
    }
}
