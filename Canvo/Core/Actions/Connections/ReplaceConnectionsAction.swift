//
//  ReplaceConnectionsAction.swift
//  Canvo
//
//  Created by Олег Комаристый on 04.05.2026.
//

import Foundation

struct ReplaceConnectionsAction: CanvasAction {
    let id = UUID()
    
    let canvasId: String
    let oldConnections: [ConnectionSnapshot]
    let newConnections: [ConnectionSnapshot]
    
    func apply(on model: AppModel) {
        model.mutationService.replaceConnections(
            canvasId: canvasId,
            snapshots: newConnections
        )
    }
    
    func undo(on model: AppModel) {
        model.mutationService.replaceConnections(
            canvasId: canvasId,
            snapshots: oldConnections
        )
    }
    
    func canMerge(with other: CanvasAction) -> Bool { false }
    func merged(with other: CanvasAction) -> CanvasAction { self }
}
