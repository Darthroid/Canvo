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
    private var container: ModelContainer?
    private var context: ModelContext? {
        container?.mainContext
    }
    
    var actionService = ActionService()
    
    var canvases: [Canvas] = []
    private(set) var currentCanvas: Canvas?
    var selectedNodeId: String?
    
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
        let configuration = ModelConfiguration(isStoredInMemoryOnly: false, allowsSave: true)
        self.container = try? ModelContainer(
            for: Canvas.self, Node.self, NodeConnection.self,
            configurations: configuration
        )
        
        actionService.set(model: self)
        fetchCanvases()
//        fetchTags()
    }
    
    func fetchCanvases() {
        do {
            let descriptor = FetchDescriptor<Canvas>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            canvases = try context?.fetch(descriptor) ?? []
        } catch {
            print("Failed to fetch canvases: \(error)")
            canvases = []
        }
    }
    
    func switchToCanvas(_ canvas: Canvas) {
        actionService.clear()
        
        currentCanvas = canvas
        
        selectedNodeId = nil
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

    func resolveTags(from rawText: String) -> [Tag] {

        let names = Set(rawText.parseTags())

        guard !names.isEmpty else { return [] }

        // 1. Забираем уже существующие
        let existing = currentCanvas?.tags ?? []

        var result = existing
        let existingNames = Set(existing.map(\.name))

        // 2. Создаём недостающие
        let missing = names.subtracting(existingNames)
        for name in missing {
            let tag = Tag(name: name, canvas: currentCanvas)
            context?.insert(tag)
            result.append(tag)
        }

        return result
    }
    
    func recomputeCanvasTags(canvasId: String) {
        guard let canvas = canvasEntity(id: canvasId) else { return }
        
        let nodes = canvas.nodes ?? []
        
        // 1. собрать все теги из нод
        let allTags: Set<String> = Set(
            nodes
                .flatMap { ($0.tagsRaw ?? "").parseTags() }
        )
        
        // 2. удалить старые
        for tag in canvas.tags ?? [] {
            context?.delete(tag)
        }
        
        // 3. создать новые
        for name in allTags {
            let tag = Tag(name: name, canvas: canvas)
            context?.insert(tag)
        }
        
        save()
    }
    
    
    /// Called from the menu when a tag button is tapped
    func toggleTag(_ tag: Tag) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    func showAllTags() {
        selectedTags.removeAll()
    }
    
    // MARK: - Helper Methods
    
    func save() {
        guard let context, context.hasChanges else { return }
        
        currentCanvas?.updatedAt = Date()
        
        try? context.save()
        
        // Update current canvas timestamp
        
        // Refresh canvases to update lists
        fetchCanvases()
        
//        fetchTags()
    }
}

// MARK: - Outline

extension AppModel {
    
    func buildChildrenMap(connections: [NodeConnection]) -> [String: [String]] {
        var map: [String: [String]] = [:]
        
        for c in connections {
            map[c.fromNodeId, default: []].append(c.toNodeId)
        }
        
        return map
    }
    
    func findRootNodes(
        nodes: [Node],
        connections: [NodeConnection]
    ) -> [Node] {
        let allToIds = Set(connections.map { $0.toNodeId })
        
        return nodes.filter { !allToIds.contains($0.id) }
    }
    
    func buildTree(
        node: Node,
        nodeDict: [String: Node],
        childrenMap: [String: [String]],
        visited: Set<String> = []
    ) -> NodeTree {
        
        // prevent cycles
        if visited.contains(node.id) {
            return NodeTree(id: node.id, node: node, children: [])
        }
        
        let newVisited = visited.union([node.id])
        
        let childrenIds = childrenMap[node.id] ?? []
        
        let children = childrenIds.compactMap { childId -> NodeTree? in
            guard let childNode = nodeDict[childId] else { return nil }
            return buildTree(
                node: childNode,
                nodeDict: nodeDict,
                childrenMap: childrenMap,
                visited: newVisited
            )
        }
        
        return NodeTree(
            id: node.id,
            node: node,
            children: children
        )
    }
    
    func buildOutline() -> [NodeTree] {
        guard let canvas = currentCanvas else { return [] }
        let nodes = canvas.nodes ?? []
        let connections = canvas.connections ?? []
        
        let nodeDict = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        
        let childrenMap = buildChildrenMap(connections: connections)
        var roots = findRootNodes(nodes: nodes, connections: connections)
        
        if roots.isEmpty, let first = nodes.first {
            roots = [first]
        }
        
        return roots.map {
            buildTree(
                node: $0,
                nodeDict: nodeDict,
                childrenMap: childrenMap
            )
        }
    }
}


// MARK: - Public API

extension AppModel {
    
    // MARK: Canvas actions
    
    func createCanvasAction(name: String) {
        let id = UUID().uuidString
        
        let action = CreateCanvasAction(
            canvasId: id,
            name: name
        )
        
        actionService.perform(action)
        
        currentCanvas = canvasEntity(id: id)
    }
    
    func addCanvasFromAIAction(_ canvas: Canvas) {
        actionService.beginBatch()
        
        // 1. canvas
        let createCanvas = CreateCanvasAction(
            canvasId: canvas.id,
            name: canvas.name
        )
        actionService.perform(createCanvas)
        
        // 2. nodes
        for node in canvas.nodes ?? [] {
            let snapshot = NodeSnapshot(
                id: node.id,
                name: node.name,
                detail: node.detail,
                x: node.x,
                y: node.y,
                z: node.z,
                color: node.colorRaw,
                tagsRaw: node.tagsRaw
            )
            
            actionService.perform(AddNodeAction(node: snapshot))
        }
        
        // 3. connections
        for conn in canvas.connections ?? [] {
            let snapshot = ConnectionSnapshot(
                id: conn.id,
                fromNodeId: conn.fromNodeId,
                toNodeId: conn.toNodeId
            )
            
            actionService.perform(AddConnectionAction(connection: snapshot))
        }
        
        actionService.endBatch()
        
        currentCanvas = canvas
    }
    
    func renameCanvasAction(id: String, newName: String) {
        guard let canvas = canvasEntity(id: id) else { return }
        
        let action = RenameCanvasAction(
            canvasId: id,
            oldName: canvas.name,
            newName: newName
        )
        
        actionService.perform(action)
    }
    
    func deleteCanvasAction(_ canvas: Canvas) {
        let snapshot = makeCanvasSnapshot(canvas)
        
        let action = DeleteCanvasAction(snapshot: snapshot)
        
        actionService.perform(action)
    }
    
    func deleteCanvasIdAction(_ id: String) {
        guard let canvas = canvasEntity(id: id) else { return }
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
}

// MARK: - Internal Helpers

extension AppModel {
    func nodeEntity(id: String) -> Node? {
        try? context?.fetch(
            FetchDescriptor<Node>(
                predicate: #Predicate { $0.id == id }
            )
        ).first
    }

    func connectionEntity(id: String) -> NodeConnection? {
        try? context?.fetch(
            FetchDescriptor<NodeConnection>(
                predicate: #Predicate { $0.id == id }
            )
        ).first
    }

    func canvasEntity(id: String) -> Canvas? {
        try? context?.fetch(
            FetchDescriptor<Canvas>(
                predicate: #Predicate { $0.id == id }
            )
        ).first
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
        context?.insert(canvas)
        
        fetchCanvases()
    }
    
    func removeCanvasInternal(id: String) {
        guard let canvas = canvasEntity(id: id) else { return }
        
        context?.delete(canvas)
        
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
        
        context?.insert(canvas)
        
        currentCanvas = canvas
        
        // tags
        for tagName in snapshot.tags {
            let tag = Tag(name: tagName, canvas: canvas)
            context?.insert(tag)
        }
        
        // nodes
        for node in snapshot.nodes {
            let n = Node(
                id: node.id,
                name: node.name,
                detail: node.detail,
                x: node.x,
                y: node.y,
                z: node.z,
                color: node.color,
                canvas: canvas,
                tagsRaw: node.tagsRaw
            )
            context?.insert(n)
        }
        
        // connections
        for conn in snapshot.connections {
            let c = NodeConnection(
                id: conn.id,
                fromNodeId: conn.fromNodeId,
                toNodeId: conn.toNodeId,
                canvas: canvas
            )
            context?.insert(c)
        }
        
        fetchCanvases()
    }
    
    func setPinInternal(canvasId: String, value: Bool) {
        guard let canvas = canvasEntity(id: canvasId) else { return }
        
        canvas.isPined = value
        canvas.updatedAt = Date()
    }
    
    func renameCanvasInternal(id: String, name: String) {
        guard let canvas = canvasEntity(id: id) else { return }
        
        canvas.name = name
        canvas.updatedAt = Date()
    }
    
    // MARK: - Nodes actions
    
    func insertNodeInternal(_ snapshot: NodeSnapshot) {
        guard let currentCanvas else { return }
        
        let node = Node(
            id: snapshot.id,
            name: snapshot.name,
            detail: snapshot.detail,
            x: snapshot.x,
            y: snapshot.y,
            z: snapshot.z,
            color: snapshot.color,
            canvas: currentCanvas,
            tagsRaw: snapshot.tagsRaw
        )
        
        context?.insert(node)
        
        recomputeCanvasTags(canvasId: currentCanvas.id)
        save()
    }
    
    func updateNodeInternal(from snapshot: NodeSnapshot) {
        guard let node = nodeEntity(id: snapshot.id) else { return }
        
        node.name = snapshot.name
        node.detail = snapshot.detail
        node.x = snapshot.x
        node.y = snapshot.y
        node.z = snapshot.z
        node.colorRaw = snapshot.color
        node.tagsRaw = snapshot.tagsRaw
        
        save()
    }
    
    func removeNodeInternal(id: String) {
        guard let node = nodeEntity(id: id),
              let canvas = node.canvas else { return }
        
        context?.delete(node)
        
        try? context?.delete(
            model: NodeConnection.self,
            where: #Predicate<NodeConnection> {
                $0.fromNodeId == id || $0.toNodeId == id
            }
        )
        
        recomputeCanvasTags(canvasId: canvas.id)
        save()
    }
    
    func updateNodeContentInternal(_ snapshot: NodeSnapshot) {
        guard let node = nodeEntity(id: snapshot.id),
              let canvas = node.canvas else { return }
        
        node.name = snapshot.name
        node.detail = snapshot.detail
        node.colorRaw = snapshot.color
        node.tagsRaw = snapshot.tagsRaw
        
        recomputeCanvasTags(canvasId: canvas.id)
        save()
    }
    
    func updatePositionInternal(nodeId: String, position: SIMD3<Float>) {
        guard let node = nodeEntity(id: nodeId) else { return }
        
        node.x = position.x
        node.y = position.y
        node.z = position.z
        
        save()
    }
    
    // MARK: - Connection actions
    
    func insertConnectionInternal(_ snapshot: ConnectionSnapshot) {
        guard let currentCanvas else { return }
        
        let connection = NodeConnection(
            id: snapshot.id,
            fromNodeId: snapshot.fromNodeId,
            toNodeId: snapshot.toNodeId,
            canvas: currentCanvas
        )
        
        context?.insert(connection)
    }
    
    func insertConnectionsInternal(_ snapshots: [ConnectionSnapshot]) {
        guard let currentCanvas else { return }
        
        for s in snapshots {
            let c = NodeConnection(
                id: s.id,
                fromNodeId: s.fromNodeId,
                toNodeId: s.toNodeId,
                canvas: currentCanvas
            )
            context?.insert(c)
        }
    }
    
    func removeConnectionInternal(id: String) {
        guard let connection = connectionEntity(id: id) else { return }
        
        context?.delete(connection)
    }
    
    func replaceConnectionsInternal(_ newConnections: [ConnectionSnapshot]) {
        guard let currentCanvas else { return }
        
        // удалить все
        try? context?.delete(model: NodeConnection.self, where: #Predicate<NodeConnection> { item in
            (item.canvas?.id ?? "") == currentCanvas.id
        })
        
        // вставить новые
        insertConnectionsInternal(newConnections)
    }
    
    // MARK: - Tags actions
    
    // FIXME: TAGS currently not working
    func updateNodeTagsInternal(nodeId: String, raw: String) {
        guard let node = nodeEntity(id: nodeId) else { return }
        
        let tags = resolveTags(from: raw)
        node.tagsRaw = tags.map(\.name).joined(separator: ",")
    }
    
    func createTagInternal(name: String) {
        guard let currentCanvas else { return }
        
        let exists = currentCanvas.tags?.contains(where: { $0.name == name }) ?? false
        guard !exists else { return }
        
        let tag = Tag(name: name, canvas: currentCanvas)
        context?.insert(tag)
    }
    
    func deleteTagInternal(name: String) {
        guard let currentCanvas else { return }
        
        guard let tag = currentCanvas.tags?.first(where: { $0.name == name }) else { return }
        
        context?.delete(tag)
        
        // очистить у нод
        for node in currentCanvas.nodes ?? [] {
            let tags = (node.tagsRaw ?? "")
                .components(separatedBy: ",")
                .filter { $0 != name }
            
            node.tagsRaw = tags.joined(separator: ",")
        }
    }
}
