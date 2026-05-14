//
//  UpdateNodeContentAction.swift
//  Canvo
//
//  Created by Олег Комаристый on 04.05.2026.
//

import Foundation


struct UpdateNodeContentAction: CanvasAction {
    let id = UUID()
    
    let nodeId: String
    let old: NodeSnapshot
    let new: NodeSnapshot
    
    func apply(on model: AppModel) {
        model.updateNodeInternal(from: new)
    }
    
    func undo(on model: AppModel) {
        model.updateNodeInternal(from: old)
    }
    
    func canMerge(with other: CanvasAction) -> Bool {
        guard let other = other as? UpdateNodeContentAction else { return false }
        return nodeId == other.nodeId
    }
    
    func merged(with other: CanvasAction) -> CanvasAction {
        guard let other = other as? UpdateNodeContentAction else { return self }
        
        return UpdateNodeContentAction(
            nodeId: nodeId,
            old: old,
            new: other.new
        )
    }
}
