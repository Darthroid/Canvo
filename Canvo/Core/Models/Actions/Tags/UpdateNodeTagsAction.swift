//
//  UpdateNodeTagsAction.swift
//  Canvo
//
//  Created by Олег Комаристый on 04.05.2026.
//

import Foundation

struct UpdateNodeTagsAction: CanvasAction {
    let id = UUID()
    
    let nodeId: String
    let oldTags: String
    let newTags: String
    
    func apply(on model: AppModel) {
        model.tagsService.updateNodeTags(nodeId: nodeId, raw: newTags)
    }
    
    func undo(on model: AppModel) {
        model.tagsService.updateNodeTags(nodeId: nodeId, raw: oldTags)
    }
    
    func canMerge(with other: CanvasAction) -> Bool {
        guard let o = other as? Self else { return false }
        return o.nodeId == nodeId
    }
    
    func merged(with other: CanvasAction) -> CanvasAction {
        let o = other as! Self
        return Self(nodeId: nodeId, oldTags: oldTags, newTags: o.newTags)
    }
}
