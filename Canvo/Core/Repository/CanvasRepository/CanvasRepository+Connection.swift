//
//  CanvasRepository+Connection.swift
//  Canvo
//
//  Created by Олег Комаристый on 06.06.2026.
//


import SwiftData
import Foundation

public extension CanvasRepository {
    
    func connections(withNodeId id: String) -> [NodeConnection] {
        (try? context.fetch(
            FetchDescriptor<NodeConnection>(
                predicate: #Predicate<NodeConnection> {
                    $0.fromNodeId == id || $0.toNodeId == id
                }
            )
        )) ?? []
    }

    func connection(id: String) -> NodeConnection? {
        try? context.fetch(
            FetchDescriptor<NodeConnection>(
                predicate: #Predicate<NodeConnection> {
                    $0.id == id
                }
            )
        ).first
    }

    func insertConnection(
        snapshot: ConnectionSnapshot,
        canvas: Canvas
    ) {
        let connection = NodeConnection(
            id: snapshot.id,
            fromNodeId: snapshot.fromNodeId,
            toNodeId: snapshot.toNodeId,
            canvas: canvas
        )
        
        canvas.updatedAt = Date()

        context.insert(connection)
    }

    func insertConnections(
        snapshots: [ConnectionSnapshot],
        canvas: Canvas
    ) {
        snapshots.forEach {
            insertConnection(
                snapshot: $0,
                canvas: canvas
            )
        }
    }
    
    func deleteConnections(_ connections: [NodeConnection]) {
        connections.forEach {
            deleteConnection(id: $0.id)
        }
    }

    func deleteConnection(id: String) {
        guard let connection = connection(id: id) else {
            return
        }
        connection.canvas?.updatedAt = Date()
        
        context.delete(connection)
    }

    func replaceConnections(
        canvasId: String,
        snapshots: [ConnectionSnapshot]
    ) {
        guard let canvas = canvas(id: canvasId) else {
            return
        }

        try? context.delete(
            model: NodeConnection.self,
            where: #Predicate<NodeConnection> {
                ($0.canvas?.id ?? "") == canvasId
            }
        )

        insertConnections(
            snapshots: snapshots,
            canvas: canvas
        )
    }
}
