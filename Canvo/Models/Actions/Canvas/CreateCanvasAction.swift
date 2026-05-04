//
//  CreateCanvasAction.swift
//  Canvo
//
//  Created by Олег Комаристый on 04.05.2026.
//

import Foundation


struct CreateCanvasAction: CanvasAction {
    let id = UUID()
    
    let canvasId: String
    let name: String
    
    func apply(on model: AppModel) {
        model.insertCanvasInternal(
            id: canvasId,
            name: name
        )
    }
    
    func undo(on model: AppModel) {
        model.removeCanvasInternal(id: canvasId)
    }
    
    func canMerge(with other: CanvasAction) -> Bool { false }
    func merged(with other: CanvasAction) -> CanvasAction { self }
}
