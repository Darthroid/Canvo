//
//  RemoveNodeAction.swift
//  Canvo
//
//  Created by Олег Комаристый on 04.05.2026.
//

import Foundation

struct RemoveNodeAction: CanvasAction {
    let id = UUID()
    
    let node: NodeSnapshot
    let connections: [ConnectionSnapshot]
    
    func apply(on model: AppModel) {
        model.removeNodeInternal(id: node.id)
    }
    
    func undo(on model: AppModel) {
        model.insertNodeInternal(node)
        model.insertConnectionsInternal(connections)
    }
    
    func canMerge(with other: CanvasAction) -> Bool { false }
    func merged(with other: CanvasAction) -> CanvasAction { self }
}
