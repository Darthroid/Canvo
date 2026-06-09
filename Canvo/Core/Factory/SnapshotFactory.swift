//
//  SnapshotFactory.swift
//  Canvo
//
//  Created by Олег Комаристый on 09.06.2026.
//

import Foundation
import SwiftUI

enum SnapshotFactory {

    // MARK: - Node

    static func node(from node: Node) -> NodeSnapshot {
        NodeSnapshot(
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
    }

    static func nodes(from nodes: [Node]) -> [NodeSnapshot] {
        nodes.map(node(from:))
    }

    // MARK: - Connection

    static func connection(from connection: NodeConnection) -> ConnectionSnapshot {
        ConnectionSnapshot(
            id: connection.id,
            fromNodeId: connection.fromNodeId,
            toNodeId: connection.toNodeId
        )
    }

    static func connections(from connections: [NodeConnection]) -> [ConnectionSnapshot] {
        connections.map(connection(from:))
    }

    // MARK: - Canvas

    static func canvas(from canvas: Canvas) -> CanvasSnapshot {
        CanvasSnapshot(
            id: canvas.id,
            name: canvas.name,
            isPinned: canvas.isPined,
            nodes: nodes(from: canvas.nodes ?? []),
            connections: self.connections(from: canvas.connections ?? []),
            tags: (canvas.tags ?? []).map(\.name)
        )
    }

    // MARK: - Helpers
    
    static func connection(fromId: String, toId: String) -> ConnectionSnapshot {
        ConnectionSnapshot(id: UUID().uuidString, fromNodeId: fromId, toNodeId: toId)
    }
    
    static func node(
        id: String,
        name: String,
        detail: String,
        position: SIMD3<Float>,
        color: String?,
        tagsRaw: String
    ) -> NodeSnapshot {
        NodeSnapshot(
            id: id,
            name: name,
            richText: AttributedString(detail),
            x: position.x,
            y: position.y,
            z: position.z,
            color: color,
            tagsRaw: tagsRaw
        )
    }
    
    static func node(
        id: String,
        name: String,
        attributedDetail: AttributedString,
        position: SIMD3<Float>,
        color: Color,
        tagsRaw: String
    ) -> NodeSnapshot {
        NodeSnapshot(
            id: id,
            name: name,
            richText: attributedDetail,
            x: position.x,
            y: position.y,
            z: position.z,
            color: color.toHex(includeAlpha: true),
            tagsRaw: tagsRaw
        )
    }
    
    static func node(
        id: String,
        name: String,
        attributedDetail: AttributedString,
        oldNode: NodeSnapshot,
        color: Color,
        tagsRaw: String
    ) -> NodeSnapshot {
        NodeSnapshot(
            id: id,
            name: name,
            richText: attributedDetail,
            x: oldNode.x,
            y: oldNode.y,
            z: oldNode.z,
            color: color.toHex(includeAlpha: true),
            tagsRaw: tagsRaw
        )
    }

    static func nodeWithConnections(
        node: Node,
        connections: [NodeConnection]
    ) -> (
        node: NodeSnapshot,
        connections: [ConnectionSnapshot]
    ) {
        let nodeSnapshot = self.node(from: node)

        let connectionSnapshots = connections
            .filter {
                $0.fromNodeId == node.id ||
                $0.toNodeId == node.id
            }
            .map(connection(from:))

        return (
            node: nodeSnapshot,
            connections: connectionSnapshots
        )
    }

    static func duplicatedNode(
        from node: Node,
        offsetY: Float = 100
    ) -> NodeSnapshot {
        NodeSnapshot(
            id: UUID().uuidString,
            name: node.name,
            detail: node.detail,
            detailRichText: node.detailRichText,
            x: node.x,
            y: node.y + offsetY,
            z: node.z,
            color: node.colorRaw,
            tagsRaw: node.tagsRaw
        )
    }
}
