//
//  CanvasMutationService.swift
//  Canvo
//
//  Created by Олег Комаристый on 09.06.2026.
//

import Foundation
import RealityKit

final class CanvasMutationService {
    private let repository: CanvasRepository
    private let tagsService: TagService

    init(
        repository: CanvasRepository,
        tagsService: TagService
    ) {
        self.repository = repository
        self.tagsService = tagsService
    }

    // MARK: - Canvas

    func insertCanvas(id: String, name: String) {
        let canvas = Canvas(
            id: id,
            name: name
        )

        repository.insertCanvas(canvas)
    }

    func insertCanvas(_ canvas: Canvas) {
        repository.insertCanvas(canvas)
    }

    func removeCanvas(id: String) {
        repository.deleteCanvas(id: id)
    }

    func restoreCanvas(_ snapshot: CanvasSnapshot) {
        let canvas = Canvas(
            id: snapshot.id,
            name: snapshot.name
        )

        canvas.isPined = snapshot.isPinned

        repository.insertCanvas(canvas)

        snapshot.tags.forEach {
            repository.createTag(
                name: $0,
                canvas: canvas
            )
        }

        repository.insertNodes(
            snapshots: snapshot.nodes,
            canvas: canvas
        )

        repository.insertConnections(
            snapshots: snapshot.connections,
            canvas: canvas
        )
    }

    func setPinned(
        canvasId: String,
        value: Bool
    ) {
        repository.setPinned(
            canvasId: canvasId,
            value: value
        )
    }
    
    func setSecured(
        canvasId: String,
        value: Bool
    ) {
        repository.setSecured(
            canvasId: canvasId,
            value: value
        )
    }

    func renameCanvas(
        id: String,
        name: String
    ) {
        repository.renameCanvas(
            id: id,
            name: name
        )
    }

    // MARK: - Nodes

    func insertNode(
        _ snapshot: NodeSnapshot,
        canvas: Canvas
    ) {
        repository.insertNode(
            snapshot: snapshot,
            canvas: canvas
        )

        tagsService.recomputeCanvasTags(
            canvasId: canvas.id
        )
    }

    func insertNodes(
        _ snapshots: [NodeSnapshot],
        canvas: Canvas
    ) {
        repository.insertNodes(
            snapshots: snapshots,
            canvas: canvas
        )

        tagsService.recomputeCanvasTags(
            canvasId: canvas.id
        )
    }

    func updateNode(
        _ snapshot: NodeSnapshot
    ) {
        guard let node = repository.node(id: snapshot.id),
              let canvas = node.canvas
        else {
            return
        }

        repository.updateNode(snapshot: snapshot)

        tagsService.recomputeCanvasTags(
            canvasId: canvas.id
        )
    }

    func removeNode(
        id: String
    ) {
        guard let node = repository.node(id: id),
              let canvas = node.canvas
        else {
            return
        }

        let connections = repository.connections(
            withNodeId: node.id
        )

        repository.deleteNode(id: node.id)
        repository.deleteConnections(connections)

        tagsService.recomputeCanvasTags(
            canvasId: canvas.id
        )
    }

    func removeNodes(
        ids: [String]
    ) {
        let nodes = ids.compactMap {
            repository.node(id: $0)
        }

        guard let canvas = nodes.first?.canvas else {
            return
        }

        let connections = nodes.flatMap {
            repository.connections(withNodeId: $0.id)
        }

        repository.deleteNodes(
            ids: nodes.map(\.id)
        )

        repository.deleteConnections(
            connections
        )

        tagsService.recomputeCanvasTags(
            canvasId: canvas.id
        )
    }

    func updatePosition(
        nodeId: String,
        position: SIMD3<Float>
    ) {
        repository.updateNodePosition(
            nodeId: nodeId,
            position: position
        )
        repository.save()
    }
    

    // MARK: - Connections

    func insertConnection(
        _ snapshot: ConnectionSnapshot,
        canvas: Canvas
    ) {
        repository.insertConnection(
            snapshot: snapshot,
            canvas: canvas
        )
    }

    func insertConnections(
        _ snapshots: [ConnectionSnapshot],
        canvas: Canvas
    ) {
        repository.insertConnections(
            snapshots: snapshots,
            canvas: canvas
        )
    }

    func removeConnection(
        id: String
    ) {
        repository.deleteConnection(id: id)
    }

    func replaceConnections(
        canvasId: String,
        snapshots: [ConnectionSnapshot]
    ) {
        repository.replaceConnections(
            canvasId: canvasId,
            snapshots: snapshots
        )
    }
}
