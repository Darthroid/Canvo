//
//  MoveNodeAction.swift
//  Canvo
//
//  Created by Олег Комаристый on 04.05.2026.
//

import Foundation

struct MoveNodeAction: CanvasAction {
    let id = UUID()
    
    let nodeId: String
    let oldPosition: SIMD3<Float>
    let newPosition: SIMD3<Float>
    
    func apply(on model: AppModel) {
        model.updatePositionInternal(nodeId: nodeId, position: newPosition)
    }
    
    func undo(on model: AppModel) {
        model.updatePositionInternal(nodeId: nodeId, position: oldPosition)
    }
    
    func canMerge(with other: CanvasAction) -> Bool {
        guard let o = other as? Self else { return false }
        return o.nodeId == nodeId
    }
    
    func merged(with other: CanvasAction) -> CanvasAction {
        let o = other as! Self
        return Self(nodeId: nodeId, oldPosition: oldPosition, newPosition: o.newPosition)
    }
}
