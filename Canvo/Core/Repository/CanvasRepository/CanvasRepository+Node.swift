//
//  CanvasRepository+Node.swift
//  Canvo
//
//  Created by Олег Комаристый on 06.06.2026.
//

import SwiftData
import Foundation

public extension CanvasRepository {

    func node(id: String) -> Node? {
        try? context.fetch(
            FetchDescriptor<Node>(
                predicate: #Predicate<Node> {
                    $0.id == id
                }
            )
        ).first
    }

    func insertNode(
        snapshot: NodeSnapshot,
        canvas: Canvas
    ) {
        let node = Node(
            id: snapshot.id,
            name: snapshot.name,
            detail: snapshot.detail,
            x: snapshot.x,
            y: snapshot.y,
            z: snapshot.z,
            color: snapshot.color,
            canvas: canvas,
            tagsRaw: snapshot.tagsRaw,
            images: snapshot.images
        )

        node.detailRichText = snapshot.detailRichText
        canvas.updatedAt = Date()

        context.insert(node)
    }

    func insertNodes(
        snapshots: [NodeSnapshot],
        canvas: Canvas
    ) {
        snapshots.forEach {
            insertNode(
                snapshot: $0,
                canvas: canvas
            )
        }
    }

    func updateNode(
        snapshot: NodeSnapshot
    ) {
        guard let node = node(id: snapshot.id) else { return }

        node.name = snapshot.name
        node.detail = snapshot.detail
        node.detailRichText = snapshot.detailRichText
        node.x = snapshot.x
        node.y = snapshot.y
        node.z = snapshot.z
        node.colorRaw = snapshot.color
        node.tagsRaw = snapshot.tagsRaw
        node.images = snapshot.images
        
        node.canvas?.updatedAt = Date()
    }

    func updateNodePosition(
        nodeId: String,
        position: SIMD3<Float>
    ) {
        guard let node = node(id: nodeId) else { return }

        node.x = position.x
        node.y = position.y
        node.z = position.z
        
        node.canvas?.updatedAt = Date()
    }

    func deleteNode(id: String) {

        guard let node = node(id: id) else {
            return
        }
        
        node.canvas?.updatedAt = Date()

        context.delete(node)

        try? context.delete(
            model: NodeConnection.self,
            where: #Predicate<NodeConnection> {
                $0.fromNodeId == id ||
                $0.toNodeId == id
            }
        )
    }

    func deleteNodes(ids: [String]) {
        ids.forEach {
            deleteNode(id: $0)
        }
    }
}
