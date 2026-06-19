//
//  AppModel.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 18.11.2025.
//

import SwiftUI
import Observation
import RealityKit
import SwiftData

@Observable
final class AppModel: Sendable {
    // MARK: - Global states
    
    var immersiveMapToolbarOpen = false
    var immersiveMapOpen = false
    var outlineOpen = false
    var aiEditorOpen = false
    
    // MARK: - Services
    
    var graphService = NodeGraphService()
    var outlineService = OutlineService()
    var aiGenerationService = AIGenerationService()
    var actionService = ActionService()
    var importService = ImportService()
    var exportService = ExportService()
    var previewService = CanvasPreviewService()
    
    var tagsService: TagService
    var mutationService: CanvasMutationService
    
    var reviewRequestService = ReviewPromptService()
    
    private let repository: CanvasRepository
    
    var session = CanvasSession()
    
    // MARK: -
    
    var canvases: [Canvas] = []

    var tags: [Tag] {
        session.currentCanvas?.tags ?? []
    }
    
    var nodes: [Node] {
        session.currentCanvas?.nodes ?? []
    }
    
    var nodesById: [String: Node] {
        Dictionary(
            uniqueKeysWithValues: nodes.map { ($0.id, $0) }
        )
    }
    
    /// All nodes that match the current tag filter
    var visibleNodes: [Node] {
        graphService.visibleNodes(
            nodes: nodes,
            selectedTags: session.selectedTags
        )
    }
    
    var connections: [NodeConnection] {
        session.currentCanvas?.connections ?? []
    }
    
    /// All connections that should be drawn – only when both ends are visible
    var visibleConnections: [NodeConnection] {
        graphService.visibleConnections(
            nodes: nodes,
            connections: connections,
            selectedTags: session.selectedTags
        )
    }
    
    init() {
        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        let container = try! ModelContainer(
            for: Canvas.self,
            Node.self,
            NodeConnection.self,
            configurations: configuration
        )
        
        repository = CanvasRepository(
            container: container
        )
        
        let _tagService = TagService(repository: repository)
        tagsService = _tagService
        
        mutationService = .init(
            repository: repository,
            tagsService: _tagService
        )
        
        actionService.set(model: self)
        importService.set(model: self)
        exportService.set(model: self)
        previewService.set(model: self)
        
        fetchCanvases()
//        fetchTags()
    }
    
    func tryImport(from url: URL) async throws -> Canvas? {
        return try await importService.processImport(from: url)
    }
    
    func fetchCanvases() {
        
        do {
            canvases = try repository.fetchCanvases()
            SpotlightService.index(canvases: canvases)
        } catch {
            print("Failed to fetch canvases: \(error)")
            canvases = []
        }
    }
    
    func save() {
        repository.save()
        fetchCanvases()
    }
    
    func switchToCanvas(_ canvas: Canvas?) {
        immersiveMapToolbarOpen = false
        immersiveMapOpen = false
        outlineOpen = false
        aiEditorOpen = false
        
        session.switchTo(canvas, actionService: actionService)
    }
    
    func canvas(forId id: String) -> Canvas? {
        repository.canvas(id: id)
    }
    
    func switchToCanvas(_ id: String) {
        guard let canvas = repository.canvas(id: id) else { return }
        switchToCanvas(canvas)
    }
}

// MARK: - Tags Management

extension AppModel {

    /// Called from the menu when a tag button is tapped
    func toggleTag(_ tag: Tag) {
        session.toggleTag(tag)
    }
    
    func showAllTags() {
        session.clearFilters()
    }
}

// MARK: - Node Graph

extension AppModel {
    
    func node(forId id: String) -> Node? {
        print("lookup")
        return nodesById[id]
    }
    
    func hasConnection(nodeId: String) -> Bool {
        graphService.hasConnection(
            nodeId: nodeId,
            connections: connections
        )
    }
    
    func nodesConnectedWith(node: Node) -> [Node] {
        graphService.connectedNodes(
            for: node,
            nodesById: nodesById,
            connections: connections
        )
    }
}

// MARK: - Outline

extension AppModel {
    func buildOutline() -> [NodeTree] {
        outlineService.buildOutline(
            nodes: nodes,
            connections: connections
        )
    }
}

// MARK: - Public API

extension AppModel {
    
    func undoAction() {
        session.clearSelection()
        actionService.undo()
    }
    
    func redoAction() {
        session.clearSelection()
        actionService.redo()
    }
}

// MARK: Canvas actions


extension AppModel {
    
    func createCanvas(name: String) {
        let id = UUID().uuidString
        
        let action = CreateCanvasAction(
            canvasId: id,
            name: name
        )
        
        actionService.perform(action)
        
        save()
        
        if let canvas = repository.canvas(id: id) {
            switchToCanvas(canvas)
            
            SpotlightService.index(canvas: canvas)
        }
    }
    
    func importCanvas(_ canvas: Canvas) {
        let action = CreateAICanvasAction(canvas: canvas)
        
        actionService.perform(action)
        
        tagsService.recomputeCanvasTags(canvasId: canvas.id)
        
        save()
        
        reviewRequestService.handle(event: .canvasCreated)
        
        SpotlightService.index(canvas: canvas)
    }
    
    func replaceCanvas(_ canvas: Canvas) {
        canvas.updatedAt = Date()
        let snapshot = SnapshotFactory.canvas(from: canvas)
        let delete = DeleteCanvasAction(snapshot: snapshot)
        let insert = CreateAICanvasAction(canvas: canvas)
        
        actionService.beginBatch()
        actionService.perform(delete)
        actionService.perform(insert)
        actionService.endBatch()
        
        tagsService.recomputeCanvasTags(canvasId: canvas.id)
        
        save()
        
        SpotlightService.removeFromIndexing(canvas: canvas)
        SpotlightService.index(canvas: canvas)
    }
    
    func addCanvasFromAI(_ canvas: Canvas) {
        
        let createCanvas = CreateAICanvasAction(canvas: canvas)
        
        actionService.perform(createCanvas)

        tagsService.recomputeCanvasTags(canvasId: canvas.id)
        
        save()
        
        reviewRequestService.handle(event: .aiGenerationAccepted)
        
        switchToCanvas(canvas)
        
        SpotlightService.index(canvas: canvas)
    }
    
    func renameCanvas(id: String, newName: String) {
        guard let canvas = repository.canvas(id: id) else { return }
        
        let action = RenameCanvasAction(
            canvasId: id,
            oldName: canvas.name,
            newName: newName
        )
        
        actionService.perform(action)
        
        save()
        
        SpotlightService.removeFromIndexing(canvas: canvas)
    }
    
    func deleteCanvas(_ id: String) {
        guard let canvas = repository.canvas(id: id) else { return }
        let snapshot = SnapshotFactory.canvas(from: canvas)
        
        let action = DeleteCanvasAction(snapshot: snapshot)
                
        actionService.perform(action)
        
        save()
        
        SpotlightService.removeFromIndexing(canvas: canvas)
    }
    
    func toggleCanvasPin(_ canvas: Canvas) {
        let action = TogglePinCanvasAction(
            canvasId: canvas.id,
            oldValue: canvas.isPined,
            newValue: !canvas.isPined
        )
        
        actionService.perform(action)
        
        save()
    }
    
    func toggleCanvasSecured(_ canvas: Canvas) {
        let action = ToggleSecureCanvasAction(
            canvasId: canvas.id,
            oldValue: canvas.isSecured,
            newValue: !canvas.isSecured
        )
        
        actionService.perform(action)
        
        save()
    }

}

// MARK: - Nodes actions

extension AppModel {
    func createNode(
        name: String,
        attributedDetail: AttributedString,
        position: SIMD3<Float>,
        color: Color?,
        tagsRaw: String,
        images: [Data]
    ) {
        guard let canvas = session.currentCanvas else { return }

        let snapshot = SnapshotFactory.node(
            id: UUID().uuidString,
            name: name,
            attributedDetail: attributedDetail,
            position: position,
            color: color,
            tagsRaw: tagsRaw,
            images: images
        )
        
        let action = AddNodeAction(canvas: canvas, node: snapshot)
        
        actionService.perform(action)
        
        if (canvas.nodes ?? []).isEmpty {
            reviewRequestService.handle(event: .canvasFirstNodeAdded)
        }
    }
    
    func addNodesFromAIAction(_ nodes: [Node], connections: [NodeConnection]) {
        guard let currentCanvas = session.currentCanvas else { return }
        let nodeSnapshots: [NodeSnapshot] = nodes.map {
            SnapshotFactory.node(from: $0)
        }
        
        let connectionsSnapshots: [ConnectionSnapshot] = connections.map {
            SnapshotFactory.connection(from: $0)
        }
        
        actionService.beginBatch()
        let nodeActions = nodeSnapshots.map {
            AddNodeAction(canvas: currentCanvas, node: $0)
        }
        nodeActions.forEach { actionService.perform($0) }
        
        let connectionsActions = connectionsSnapshots.map {
            AddConnectionAction(connection: $0, canvas: currentCanvas)
        }
        connectionsActions.forEach { actionService.perform($0) }
        
        actionService.endBatch()
    }
    
    func editNode(
        nodeId: String,
        name: String,
        attributedDetail: AttributedString,
        color: Color?,
        tagsRaw: String,
        images: [Data]
    ) {
        guard let node = node(forId: nodeId) else { return }

        let snapshot = SnapshotFactory.nodeWithConnections(
            node: node,
            connections: connections.filter {
                $0.fromNodeId == nodeId || $0.toNodeId == nodeId
            }
        )
        
        let oldNode = snapshot.node

        let newNode = SnapshotFactory.node(
            id: nodeId,
            name: name,
            attributedDetail: attributedDetail,
            oldNode: oldNode,
            color: color,
            tagsRaw: tagsRaw,
            images: images
        )

        let action = UpdateNodeContentAction(
            nodeId: nodeId,
            old: oldNode,
            new: newNode
        )

        actionService.perform(action)
    }
    
    func removeNode(_ node: Node) {
        guard let canvas = session.currentCanvas else { return }
        
        withAnimation {
            session.clearSelection()
        }
        
        let snapshot = SnapshotFactory.nodeWithConnections(
            node: node,
            connections: connections.filter {
                $0.fromNodeId == node.id || $0.toNodeId == node.id
            }
        )
        
        let action = RemoveNodeAction(
            canvas: canvas,
            node: snapshot.node,
            connections: snapshot.connections
        )
        
        actionService.perform(action)
    }
    
    func removeSelectedNodes() {
        guard !session.selectedNodeIds.isEmpty,
              let canvas = session.currentCanvas
        else { return }
        
        let snapshots = session.selectedNodeIds
            .compactMap { node(forId: $0) }
            .map { node in
                SnapshotFactory.nodeWithConnections(
                    node: node,
                    connections: connections.filter {
                        $0.fromNodeId == node.id || $0.toNodeId == node.id
                    }
                )
            }
        
        actionService.beginBatch()
        snapshots.forEach {
            let action = RemoveNodeAction(
                canvas: canvas,
                node: $0.node,
                connections: $0.connections
            )
            actionService.perform(action)
        }
        actionService.endBatch()
        
        withAnimation {
            session.clearSelection()
        }
    }
    
    func duplicateSelectedNodes() {
        guard !session.selectedNodeIds.isEmpty,
              let canvas = session.currentCanvas
        else { return }
        
        let snapshots = session.selectedNodeIds
            .compactMap { node(forId: $0) }
            .map { SnapshotFactory.duplicatedNode(from: $0) }
        
        actionService.beginBatch()
        snapshots.forEach {
            let action = AddNodeAction(canvas: canvas, node: $0)
            actionService.perform(action)
        }
        actionService.endBatch()
        
        session.clearSelection()
        snapshots.forEach { session.selectedNodeIds.insert($0.id) }
    }

    func moveNodes(
        ids: [String],
        oldPositions: [SIMD3<Float>],
        newPositions: [SIMD3<Float>]
    ) {
        let action = MoveNodesBatchAction(
            nodeIds: ids,
            oldPositions: oldPositions,
            newPositions: newPositions
        )
        actionService.perform(action)
    }
}

// MARK: - Connection actions

extension AppModel {
    func addConnections(fromNodeId: String, toIds: Set<String>) {
        guard let canvas = session.currentCanvas else { return }
        
        actionService.beginBatch()
        toIds.forEach { toNodeId in
            guard !connections.contains(where: {
                ($0.fromNodeId == fromNodeId && $0.toNodeId == toNodeId) ||
                ($0.fromNodeId == toNodeId && $0.toNodeId == fromNodeId)
            }) else { return }
            
            let snapshot = SnapshotFactory.connection(fromId: fromNodeId, toId: toNodeId)
            
            let action = AddConnectionAction(connection: snapshot, canvas: canvas)
            actionService.perform(action)
        }
        actionService.endBatch()
    }
    
    func removeConnection(_ connection: NodeConnection) {
        guard let canvas = session.currentCanvas else { return }
        
        let snapshot = SnapshotFactory.connection(from: connection)
        let action = RemoveConnectionAction(connection: snapshot, canvas: canvas)
        actionService.perform(action)
    }
}
