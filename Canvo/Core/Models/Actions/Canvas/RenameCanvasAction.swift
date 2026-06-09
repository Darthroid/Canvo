//
//  RenameCanvasAction.swift
//  Canvo
//
//  Created by Олег Комаристый on 04.05.2026.
//

import Foundation

struct RenameCanvasAction: CanvasAction {
    let id = UUID()
    
    let canvasId: String
    let oldName: String
    let newName: String
    
    func apply(on model: AppModel) {
        model.mutationService.renameCanvas(id: canvasId, name: newName)
    }
    
    func undo(on model: AppModel) {
        model.mutationService.renameCanvas(id: canvasId, name: oldName)
    }
    
    func canMerge(with other: CanvasAction) -> Bool {
        guard let o = other as? Self else { return false }
        return o.canvasId == canvasId
    }
    
    func merged(with other: CanvasAction) -> CanvasAction {
        let o = other as! Self
        return Self(canvasId: canvasId, oldName: oldName, newName: o.newName)
    }
}
