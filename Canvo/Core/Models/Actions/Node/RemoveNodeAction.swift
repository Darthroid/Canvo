//
//  RemoveNodeAction.swift
//  Canvo
//
//  Created by Олег Комаристый on 04.05.2026.
//

import Foundation

struct RemoveNodeAction: CanvasAction {
    let id = UUID()
    
    let canvas: Canvas
    let node: NodeSnapshot
    let connections: [ConnectionSnapshot]
    
    func apply(on model: AppModel) {
        model.mutationService.removeNode(id: node.id)
    }
    
    func undo(on model: AppModel) {
        model.mutationService.insertNode(node, canvas: canvas)
        model.mutationService.insertConnections(connections, canvas: canvas)
    }
    
    func canMerge(with other: CanvasAction) -> Bool { false }
    func merged(with other: CanvasAction) -> CanvasAction { self }
}
