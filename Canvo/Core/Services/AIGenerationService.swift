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

    private var currentTask: Task<Void, Never>? {
        didSet {
            isRunning = currentTask != nil
        }
    }

    public var runningStage: String?
    private(set) public var error: String?

    public var isAvailable: Bool {
        model.isAvailable
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
                        
                        layoutWithCollisionAvoidance(
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

                    let allNodes = (canvas.nodes ?? []).map { $0.toSchema() }

                    let scopePositions = scope.map {
                        Position3DSchema(
                            x: $0.position.x,
                            y: $0.position.y,
                            z: $0.position.z
                        )
                    }

                    let centroid = computeCentroid(scopePositions)

                    let direction = findBestExpansionDirection(
                        from: centroid,
                        occupied: allNodes
                    )

                    summary.position = findBestPositionInField(
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

    private func generateRadial(
        session: LanguageModelSession,
        prompt: String,
        canvas: CanvasSchema,
        mainNode: NodeSchema,
        semanticGuard: String
    ) async throws -> (nodes: [NodeSchema], connections: [NodeConnectionSchema]) {

        self.runningStage = String(localized: "Radial expansion")

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
        semanticGuard: String
    ) async throws -> (nodes: [NodeSchema], connections: [NodeConnectionSchema]) {

        self.runningStage = String(localized: "Branching")

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

    private func normalize(_ node: NodeSchema) -> NodeSchema {
        var copy = node
        copy.id = UUID().uuidString
        return copy
    }

    // MARK: - LAYOUT

    private let nodeHalfSize: Float = 200

    private func isOverlapping(
        _ a: NodeSchema,
        _ b: NodeSchema
    ) -> Bool {

        let dx = abs(a.position.x - b.position.x)
        let dy = abs(a.position.y - b.position.y)

        return dx < 420 && dy < 180
    }

    private func computeCentroid(_ positions: [Position3DSchema]) -> Position3DSchema {
        guard !positions.isEmpty else { return .init(x: 0, y: 0, z: 0) }

        let sum = positions.reduce((x: Float(0), y: Float(0), z: Float(0))) {
            ($0.x + $1.x, $0.y + $1.y, $0.z + $1.z)
        }

        return .init(
            x: sum.x / Float(positions.count),
            y: sum.y / Float(positions.count),
            z: sum.z / Float(positions.count)
        )
    }


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
    
    private func layoutWithCollisionAvoidance(
        nodes: inout [NodeSchema],
        center: Position3DSchema,
        allNodes: [NodeSchema],
        radius: Float = 220
    ) {
        guard !nodes.isEmpty else { return }

        let direction = findBestExpansionDirection(
            from: center,
            occupied: allNodes
        )

        let clusterCenter = findBestPositionInField(
            preferredDirection: direction,
            origin: center,
            allNodes: allNodes,
            radiusStart: radius
        )

        let baseAngle = atan2(
            direction.y,
            direction.x
        )

        let spread: Float = .pi / 3

        var occupied = allNodes

        for index in nodes.indices {

            let angleOffset: Float

            if nodes.count == 1 {
                angleOffset = 0
            } else {
                let t = Float(index) / Float(nodes.count - 1)
                angleOffset = -spread / 2 + spread * t
            }

            let candidate = Position3DSchema(
                x: clusterCenter.x + cos(baseAngle + angleOffset) * 90,
                y: clusterCenter.y + sin(baseAngle + angleOffset) * 140,
                z: center.z
            )

            nodes[index].position = candidate
            occupied.append(nodes[index])
        }
    }

    private func findBestExpansionDirection(
        from center: Position3DSchema,
        occupied: [NodeSchema]
    ) -> SIMD2<Float> {

        guard !occupied.isEmpty else {
            return SIMD2<Float>(0, 1)
        }

        let nearbyNodes = occupied.filter {

            let dx = $0.position.x - center.x
            let dy = $0.position.y - center.y

            let distanceSquared = dx * dx + dy * dy

            return distanceSquared < 900 * 900
        }

        guard !nearbyNodes.isEmpty else {
            return SIMD2<Float>(0, 1)
        }

        let sectors = 24

        var bestDirection = SIMD2<Float>(0, 1)
        var bestScore = -Float.infinity

        for sector in 0..<sectors {

            let angle =
                (Float(sector) / Float(sectors))
                * (.pi * 2)

            let direction = SIMD2<Float>(
                cos(angle),
                sin(angle)
            )

            var score: Float = 0

            for node in nearbyNodes {

                let dx = node.position.x - center.x
                let dy = node.position.y - center.y

                let distance = sqrt(dx * dx + dy * dy)

                guard distance > 1 else {
                    continue
                }

                let normalized = SIMD2<Float>(
                    dx / distance,
                    dy / distance
                )

                let alignment =
                    normalized.x * direction.x +
                    normalized.y * direction.y

                if alignment > 0 {

                    score -= alignment *
                    (1_000 / max(distance, 100))
                }
            }

            if score > bestScore {
                bestScore = score
                bestDirection = direction
            }
        }

        return bestDirection
    }

    private func findBestPositionInField(
        preferredDirection: SIMD2<Float>,
        origin: Position3DSchema,
        allNodes: [NodeSchema],
        radiusStart: Float = 220
    ) -> Position3DSchema {

        let baseAngle = atan2(
            preferredDirection.y,
            preferredDirection.x
        )

        for radius in stride(
            from: radiusStart,
            through: radiusStart + 1200,
            by: 25
        ) {

            for offset in stride(
                from: -Float.pi / 2,
                through: Float.pi / 2,
                by: Float.pi / 24
            ) {

                let angle = baseAngle + offset

                let candidate = Position3DSchema(
                    x: origin.x + cos(angle) * radius,
                    y: origin.y + sin(angle) * radius,
                    z: origin.z
                )

                let testNode = NodeSchema(
                    id: UUID().uuidString,
                    name: "",
                    detail: "",
                    position: candidate
                )

                let collision = allNodes.contains {
                    isOverlapping(testNode, $0)
                }

                if !collision {
                    return candidate
                }
            }
        }

        return .init(
            x: origin.x + preferredDirection.x * radiusStart,
            y: origin.y + preferredDirection.y * radiusStart,
            z: origin.z
        )
    }
}
