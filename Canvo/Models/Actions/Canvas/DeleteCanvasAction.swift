//
//  DeleteCanvasAction.swift
//  Canvo
//
//  Created by Олег Комаристый on 04.05.2026.
//

import Foundation

struct DeleteCanvasAction: CanvasAction {
    let id = UUID()
    
    let snapshot: CanvasSnapshot
    
    func apply(on model: AppModel) {
        model.removeCanvasInternal(id: snapshot.id)
    }
    
    func undo(on model: AppModel) {
        model.restoreCanvasInternal(snapshot)
    }
    
    func canMerge(with other: CanvasAction) -> Bool { false }
    func merged(with other: CanvasAction) -> CanvasAction { self }
}
