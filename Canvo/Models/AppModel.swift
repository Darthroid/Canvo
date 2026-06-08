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

@MainActor
@Observable
final class AppModel: Sendable {
    var immersiveMapToolbarOpen = false
    var immersiveMapOpen = false
    var outlineOpen = false
    var aiEditorOpen = false
    
    
    private let repository: CanvasRepository
    
    var tagsService: TagService
    var outlineService = OutlineService()
    var aiGenerationService = AIGenerationService()
    var actionService = ActionService()
    var importService = ImportService()
    var exportService = ExportService()
    var previewService = CanvasPreviewService()
    
    var canvases: [Canvas] = []
    private(set) var currentCanvas: Canvas?
    var expandedNodeIds: Set<String> = []
    var selectedNodeIds: Set<String> = []
    
    var pendingNodePosition: SIMD3<Float>? = nil
    
    var centerOnNodeId: String?
    
    /// Tags that the user has toggled in the filter UI
    var selectedTags: Set<Tag> = []
    
    var tags: [Tag] {
        currentCanvas?.tags ?? []
    }
    
    var nodes: [Node] {
        currentCanvas?.nodes ?? []
    }
    
    /// All nodes that match the current tag filter
    var visibleNodes: [Node] {
        guard !selectedTags.isEmpty else { return nodes }

        // A node is visible if **any** of its tags is in the selected set
        return nodes.filter { node in
            let tags = Set((node.tagsRaw ?? "").parseTags())
            return !tags.isDisjoint(with: selectedTags.map(\.name))
        }
    }
    
    var connections: [NodeConnection] {
        currentCanvas?.connections ?? []
    }
    
    /// All connections that should be drawn – only when both ends are visible
    var visibleConnections: [NodeConnection] {
        connections.filter { conn in
            guard let a = node(forId: conn.fromNodeId),
                  let b = node(forId: conn.toNodeId) else { return false }

            return visibleNodes.contains(a) && visibleNodes.contains(b)
        }
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
        
        tagsService = .init(repository: repository)
        
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
        actionService.clear()
        
        currentCanvas = canvas
        
        selectedNodeIds = []
        expandedNodeIds = []
        selectedTags = []
        
        let _nodes = nodes
        _nodes.forEach { node in
            node.isHidden = false
        }
        
        currentCanvas?.nodes = _nodes
    }
    
    func node(forId id: String) -> Node? {
        return nodes.first(where: { $0.id == id })
    }
    
    func hasConnection(nodeId: String) -> Bool {
        return connections.contains(where: { $0.fromNodeId == nodeId || $0.toNodeId == nodeId })
    }
    
    func nodesConnectedWith(node: Node) -> [Node] {
        let connections = connections.filter { $0.fromNodeId == node.id || $0.toNodeId == node.id }
        var connectedNodes: [Node] = []
        
        for connection in connections {
            let otherNodeId = connection.fromNodeId == node.id ? connection.toNodeId : connection.fromNodeId
            if let otherNode = self.node(forId: otherNodeId) {
                connectedNodes.append(otherNode)
            }
        }
        
        return connectedNodes
    }

    // MARK: - Tags Management


    
    
    /// Called from the menu when a tag button is tapped
    func toggleTag(_ tag: Tag) {
        selectedNodeIds.removeAll()
        
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    func showAllTags() {
        selectedNodeIds.removeAll()
        
        selectedTags.removeAll()
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
        selectedNodeIds.removeAll()
        actionService.undo()
    }
    
    func redoAction() {
        selectedNodeIds.removeAll()
        actionService.redo()
    }
    
    // MARK: Canvas actions
    
    func createCanvasAction(name: String) {
        let id = UUID().uuidString
        
        let action = CreateCanvasAction(
            canvasId: id,
            name: name
        )
        
        actionService.perform(action)
        
//        currentCanvas = canvasEntity(id: id)
    }
    
    func importCanvasAction(_ canvas: Canvas) {
        let action = CreateAICanvasAction(canvas: canvas)
        
        actionService.perform(action)
        
        tagsService.recomputeCanvasTags(canvasId: canvas.id)
        
        fetchCanvases()
    }
    
    func replaceCanvasAction(_ canvas: Canvas) {
        canvas.updatedAt = Date()
        let delete = DeleteCanvasAction(snapshot: makeCanvasSnapshot(canvas))
        let insert = CreateAICanvasAction(canvas: canvas)
        
        actionService.beginBatch()
        actionService.perform(delete)
        actionService.perform(insert)
        actionService.endBatch()
        
        tagsService.recomputeCanvasTags(canvasId: canvas.id)
        
        fetchCanvases()
        
    }
    
    func addCanvasFromAIAction(_ canvas: Canvas) {
        
        let createCanvas = CreateAICanvasAction(canvas: canvas)
        
        actionService.perform(createCanvas)

        tagsService.recomputeCanvasTags(canvasId: canvas.id)
        
        fetchCanvases()
    }
    
    func renameCanvasAction(id: String, newName: String) {
        guard let canvas = repository.canvas(id: id) else { return }
        
        let action = RenameCanvasAction(
            canvasId: id,
            oldName: canvas.name,
            newName: newName
        )
        
        actionService.perform(action)
        
        fetchCanvases()
    }
    
    func deleteCanvasAction(_ canvas: Canvas) {
        let snapshot = makeCanvasSnapshot(canvas)
        
        let action = DeleteCanvasAction(snapshot: snapshot)
        
        actionService.perform(action)
        
        fetchCanvases()
    }
    
    func deleteCanvasIdAction(_ id: String) {
        guard let canvas = repository.canvas(id: id) else { return }
        let snapshot = makeCanvasSnapshot(canvas)
        
        let action = DeleteCanvasAction(snapshot: snapshot)
        
        actionService.perform(action)
    }
    
    func toggleCanvasPinAction(_ canvas: Canvas) {
        let action = TogglePinCanvasAction(
            canvasId: canvas.id,
            oldValue: canvas.isPined,
            newValue: !canvas.isPined
        )
        
        actionService.perform(action)
    }
    
    func makeNodeSnapshotWithConnections(_ node: Node) -> (node: NodeSnapshot, connections: [ConnectionSnapshot]) {
        
        let nodeSnapshot = NodeSnapshot(
            id: node.id,
            name: node.name,
            detail: node.detail,
            detailRichText: node.detailRichText,
            x: node.x,
            y: node.y,
            z: node.z,
            color: node.colorRaw,
            tagsRaw: node.tagsRaw
        )
        
        let connections = connections
            .filter { $0.fromNodeId == node.id || $0.toNodeId == node.id }
            .map {
                ConnectionSnapshot(
                    id: $0.id,
                    fromNodeId: $0.fromNodeId,
                    toNodeId: $0.toNodeId
                )
            }
        
        return (nodeSnapshot, connections)
    }
    
    func addNodesFromAIAction(_ nodes: [Node], connections: [NodeConnection]) {
        let nodeSnapshots: [NodeSnapshot] = nodes.map {
            NodeSnapshot(
                id: $0.id,
                name: $0.name,
                detail: $0.detail,
                detailRichText: $0.detailRichText,
                x: $0.x,
                y: $0.y,
                z: $0.z,
                color: $0.colorRaw,
                tagsRaw: $0.tagsRaw
            )
        }
        
        let connectionsSnapshots: [ConnectionSnapshot] = connections.map {
            ConnectionSnapshot(
                id: $0.id,
                fromNodeId: $0.fromNodeId,
                toNodeId: $0.toNodeId
            )
        }
        
        actionService.beginBatch()
        let nodeActions = nodeSnapshots.map {
            AddNodeAction(node: $0)
        }
        nodeActions.forEach { actionService.perform($0) }
        
        let connectionsActions = connectionsSnapshots.map {
            AddConnectionAction(connection: $0)
        }
        connectionsActions.forEach { actionService.perform($0) }
        
        actionService.endBatch()
    }
}


extension AppModel {
    // MARK: - Canvas actions
    
    func makeCanvasSnapshot(_ canvas: Canvas) -> CanvasSnapshot {
        let nodes = (canvas.nodes ?? []).map {
            NodeSnapshot(
                id: $0.id,
                name: $0.name,
                detail: $0.detail,
                detailRichText: $0.detailRichText,
                x: $0.x,
                y: $0.y,
                z: $0.z,
                color: $0.colorRaw,
                tagsRaw: $0.tagsRaw
            )
        }
        
        let connections = (canvas.connections ?? []).map {
            ConnectionSnapshot(
                id: $0.id,
                fromNodeId: $0.fromNodeId,
                toNodeId: $0.toNodeId
            )
        }
        
        let tags = (canvas.tags ?? []).map(\.name)
        
        return CanvasSnapshot(
            id: canvas.id,
            name: canvas.name,
            isPinned: canvas.isPined,
            nodes: nodes,
            connections: connections,
            tags: tags
        )
    }
    
    func insertCanvasInternal(id: String, name: String) {
        let canvas = Canvas(id: id, name: name)
        repository.insertCanvas(canvas)
        
        fetchCanvases()
    }
    
    func insertCanvasInternal(canvas: Canvas) {
        repository.insertCanvas(canvas)
        
        fetchCanvases()
    }
    
    func removeCanvasInternal(id: String) {
        repository.deleteCanvas(id: id)
        
        if currentCanvas?.id == id {
            currentCanvas = nil
        }
        
        fetchCanvases()
    }
    
    func restoreCanvasInternal(_ snapshot: CanvasSnapshot) {
        let canvas = Canvas(
            id: snapshot.id,
            name: snapshot.name
        )
        
        canvas.isPined = snapshot.isPinned
        
        repository.insertCanvas(canvas)
        
//        currentCanvas = canvas
        
        // tags
        for tagName in snapshot.tags {
            repository.createTag(name: tagName, canvas: canvas)
        }
        
        // nodes
        repository.insertNodes(snapshots: snapshot.nodes, canvas: canvas)
        
        // connections
        repository.insertConnections(snapshots: snapshot.connections, canvas: canvas)
        
        fetchCanvases()
    }
    
    func setPinInternal(canvasId: String, value: Bool) {
        repository.setPinned(canvasId: canvasId, value: value)
        
        fetchCanvases()
    }
    
    func renameCanvasInternal(id: String, name: String) {
        repository.renameCanvas(id: id, name: name)
        
        fetchCanvases()
    }
    
    // MARK: - Nodes actions
    
    func removeNode(_ node: Node) {
        withAnimation {
            selectedNodeIds.removeAll()
        }
        
        let snapshot = makeNodeSnapshotWithConnections(node)
        
        let action = RemoveNodeAction(
            node: snapshot.node,
            connections: snapshot.connections
        )
        
        actionService.perform(action)
    }
    
    func deleteSelectedNodes() {
        guard !selectedNodeIds.isEmpty else { return }
        
        let snapshots = selectedNodeIds
            .compactMap { node(forId: $0) }
            .map { makeNodeSnapshotWithConnections($0) }
        
        actionService.beginBatch()
        snapshots.forEach {
            let action = RemoveNodeAction(node: $0.node, connections: $0.connections)
            actionService.perform(action)
        }
        actionService.endBatch()
        
        withAnimation {
            selectedNodeIds.removeAll()
        }
    }
    
    func duplicateSelectedNodes() {
        guard !selectedNodeIds.isEmpty else { return }
        
        let snapshots = selectedNodeIds
            .compactMap { node(forId: $0) }
            .map {
                NodeSnapshot(
                    id: UUID().uuidString,
                    name: $0.name,
                    detail: $0.detail,
                    detailRichText: $0.detailRichText,
                    x: $0.x,
                    y: $0.y + 100,
                    z: $0.z, color: $0.colorRaw,
                    tagsRaw: $0.tagsRaw
                )
            }
        
        actionService.beginBatch()
        snapshots.forEach {
            let action = AddNodeAction(node: $0)
            actionService.perform(action)
        }
        actionService.endBatch()
        
        selectedNodeIds.removeAll()
        snapshots.forEach { selectedNodeIds.insert($0.id) }
    }
    
    func insertNodeInternal(_ snapshot: NodeSnapshot) {
        guard let currentCanvas else { return }

        repository.insertNode(snapshot: snapshot, canvas: currentCanvas)
        
        tagsService.recomputeCanvasTags(canvasId: currentCanvas.id)
        save()
    }
    
    func insertNodesInternal(_ snapshots: [NodeSnapshot]) {
        guard let currentCanvas else { return }

        repository.insertNodes(snapshots: snapshots, canvas: currentCanvas)
        
        tagsService.recomputeCanvasTags(canvasId: currentCanvas.id)
        save()
    }
    
    func updateNodeInternal(from snapshot: NodeSnapshot) {
        guard let node = repository.node(id: snapshot.id),
              let canvas = node.canvas
        else { return }
        
        repository.updateNode(snapshot: snapshot)
        tagsService.recomputeCanvasTags(canvasId: canvas.id)
        
        save()
    }
    
    func removeNodeInternal(id: String) {
        guard let node = repository.node(id: id),
              let canvas = node.canvas else { return }
        
        let connections = repository.connections(withNodeId: node.id)
        repository.deleteNode(id: node.id)
        repository.deleteConnections(connections)

        tagsService.recomputeCanvasTags(canvasId: canvas.id)
        save()
    }
    
    func removeNodesInternal(ids: [String]) {
        let nodes = ids.compactMap { repository.node(id: $0) }
        guard let canvas = nodes.first?.canvas else { return }
        
        let connections = nodes
            .flatMap { repository.connections(withNodeId: $0.id) }
        
        repository.deleteNodes(ids: nodes.map(\.id))
        repository.deleteConnections(connections)
        
        tagsService.recomputeCanvasTags(canvasId: canvas.id)
        save()
    }
    
    func updateNodeContentInternal(_ snapshot: NodeSnapshot) {
        guard let node = repository.node(id: snapshot.id),
              let canvas = node.canvas else { return }
        
        repository.updateNode(snapshot: snapshot)
        
        tagsService.recomputeCanvasTags(canvasId: canvas.id)
        save()
    }
    
    func updatePositionInternal(nodeId: String, position: SIMD3<Float>) {
        repository.updateNodePosition(nodeId: nodeId, position: position)
        
        save()
    }
    
    // MARK: - Connection actions
    
    func insertConnectionInternal(_ snapshot: ConnectionSnapshot) {
        guard let currentCanvas else { return }
        
        repository.insertConnection(snapshot: snapshot, canvas: currentCanvas)
    }
    
    func insertConnectionsInternal(_ snapshots: [ConnectionSnapshot]) {
        guard let currentCanvas else { return }
        
        repository.insertConnections(snapshots: snapshots, canvas: currentCanvas)
    }
    
    func removeConnectionInternal(id: String) {
        repository.deleteConnection(id: id)
    }
    
    func replaceConnectionsInternal(_ newConnections: [ConnectionSnapshot]) {
        guard let currentCanvas else { return }
        
        repository.replaceConnections(canvasId: currentCanvas.id, snapshots: newConnections)
        
    }
}

// MARK: - Tags actions

extension AppModel {

    func createTagInternal(name: String) {
        tagsService.createTag(
            name: name,
            canvas: currentCanvas
        )
    }

    func deleteTagInternal(name: String) {
        tagsService.deleteTag(
            name: name,
            canvas: currentCanvas
        )
    }
    
    func updateNodeTagsInternal(nodeId: String, raw: String) {
        tagsService.updateNodeTags(
            nodeId: nodeId,
            raw: raw
        )
    }
}
