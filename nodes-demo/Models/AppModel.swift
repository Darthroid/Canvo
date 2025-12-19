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
    var container: ModelContainer?
    var context: ModelContext? {
        container?.mainContext
    }
    
    var canvases: [Canvas] = []
    private(set) var currentCanvas: Canvas?
    var selectedNodeId: String?
    
    var nodes: [Node] {
        currentCanvas?.nodes ?? []
    }
    
    var connections: [NodeConnection] {
        currentCanvas?.connections ?? []
    }
    
    init() {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: false, allowsSave: true)
        self.container = try? ModelContainer(
            for: Canvas.self, Node.self, NodeConnection.self,
            configurations: configuration
        )
        
        fetchCanvases()
    }
    
    // MARK: - Canvas Management
    
    func fetchCanvases() {
        do {
            let descriptor = FetchDescriptor<Canvas>(
                sortBy: [SortDescriptor(\.createdAt)]
            )
            canvases = try context?.fetch(descriptor) ?? []
        } catch {
            print("Failed to fetch canvases: \(error)")
            canvases = []
        }
    }
    
    func createCanvas(name: String) {
        let canvas = Canvas(name: name)
        context?.insert(canvas)
        save()
        
        fetchCanvases()
        currentCanvas = canvas
    }
    
    func switchToCanvas(_ canvas: Canvas) {
        currentCanvas = canvas
    }
    
    func removeCanvas(_ canvas: Canvas) {
        context?.delete(canvas)
        save()
        fetchCanvases()
        
        if currentCanvas?.id == canvas.id {
            currentCanvas = nil
        }
    }
    
    func removeCanvas(at indexSet: IndexSet) {
        let canvasesToDelete = canvases.enumerated()
            .filter { indexSet.contains($0.offset) }
            .map { $0.element }
        
        canvasesToDelete.forEach { removeCanvas($0) }
    }
    
    func updateCanvasName(_ canvas: Canvas, newName: String) {
        canvas.name = newName
        canvas.updatedAt = Date()
        save()
    }
    
    // MARK: - Node Management (with canvas context)
    
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
    
    func addNode(name: String, detail: String, position: (x: Float, y: Float, z: Float)?, color: String? = nil) {
        guard let currentCanvas = currentCanvas else { return }
        
        let _position: (x: Float, y: Float, z: Float)
        
        if let providedPosition = position {
            _position = providedPosition
        } else if nodes.isEmpty {
            // If no nodes exist, place in the center relative to canvas
            _position = (0, 1.0, -1.5)
        } else {
            // Calculate center position of all existing nodes
            let totalX = nodes.reduce(0.0) { $0 + $1.x }
            let totalY = nodes.reduce(0.0) { $0 + $1.y }
            let totalZ = nodes.reduce(0.0) { $0 + $1.z }
            
            let centerX = totalX / Float(nodes.count)
            let centerY = totalY / Float(nodes.count)
            let centerZ = totalZ / Float(nodes.count)
            
            _position = (centerX, centerY, centerZ)
        }
        
        let node = Node(
            name: name,
            detail: detail,
            x: _position.x,
            y: _position.y,
            z: _position.z,
            color: color,
            canvas: currentCanvas
        )
        
        context?.insert(node)
        save()
    }
    
    func updateNode(id: String, with node: Node) {
        if let objectToUpdate = try? context?.fetch(
            FetchDescriptor<Node>(predicate: #Predicate { $0.id == id })
        ).first {
            objectToUpdate.x = node.x
            objectToUpdate.y = node.y
            objectToUpdate.z = node.z
            objectToUpdate.name = node.name
            objectToUpdate.detail = node.detail
            objectToUpdate.colorRaw = node.colorRaw
        }
        save()
    }
    
    func updateNode(id: String, name: String, detail: String, color: String? = nil) {
        if let objectToUpdate = try? context?.fetch(
            FetchDescriptor<Node>(predicate: #Predicate { $0.id == id })
        ).first {
            objectToUpdate.name = name
            objectToUpdate.detail = detail
            objectToUpdate.colorRaw = color
        }
        save()
    }
    
    func removeNode(at indexSet: IndexSet) {
        let nodesToDelete = nodes.enumerated()
            .filter { indexSet.contains($0.offset) }
            .map { $0.element }
        
        nodesToDelete.forEach { removeNode($0) }
    }
    
    func removeNode(_ node: Node) {
        let nodeId = node.id
        context?.delete(node)
        
        // Delete connections involving this node
        try? context?.delete(model: NodeConnection.self, where: #Predicate<NodeConnection> { item in
            (item.fromNodeId == nodeId || item.toNodeId == nodeId) && item.canvas?.id == currentCanvas?.id
        })
        save()
    }
    
    func updatePosition(for nodeId: String, newPosition: SIMD3<Float>) {
        if let objectToUpdate = try? context?.fetch(
            FetchDescriptor<Node>(predicate: #Predicate { $0.id == nodeId })
        ).first {
            objectToUpdate.x = newPosition.x
            objectToUpdate.y = newPosition.y
            objectToUpdate.z = newPosition.z
        }
        save()
    }
    
    // MARK: - Connection Management
    
    func addConnection(from fromNodeId: String, to toNodeId: String) {
        guard let currentCanvas = currentCanvas,
              fromNodeId != toNodeId,
              nodes.contains(where: { $0.id == fromNodeId }),
              nodes.contains(where: { $0.id == toNodeId }) else { return }
        
        guard !connections.contains(where: {
            ($0.fromNodeId == fromNodeId && $0.toNodeId == toNodeId) ||
            ($0.fromNodeId == toNodeId && $0.toNodeId == fromNodeId)
        }) else { return }
        
        let connection = NodeConnection(
            fromNodeId: fromNodeId,
            toNodeId: toNodeId,
            canvas: currentCanvas
        )
        context?.insert(connection)
        save()
    }
    
    func removeConnectionsBetween(_ node1: Node, and node2: Node) {
        let connections = connections.filter {
            ($0.fromNodeId == node1.id && $0.toNodeId == node2.id) ||
            ($0.fromNodeId == node2.id && $0.toNodeId == node1.id)
        }
        
        connections.forEach { removeConnection($0) }
    }
    
    func removeConnection(_ connection: NodeConnection) {
        context?.delete(connection)
        save()
    }
    
    func removeConnection(nodeId: String) {
        if let connection = connections.first(where: { $0.fromNodeId == nodeId || $0.toNodeId == nodeId }) {
            removeConnection(connection)
        }
    }
    
    // MARK: - Helper Methods
    
    fileprivate func save() {
        guard let context, context.hasChanges else { return }
        try? context.save()
        
        // Update current canvas timestamp
        currentCanvas?.updatedAt = Date()
        
        // Refresh canvases to update lists
        fetchCanvases()
    }
}
